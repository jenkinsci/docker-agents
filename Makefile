ROOT_DIR="$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))/"

## For Docker <=20.04
export DOCKER_BUILDKIT=1
## For Docker <=20.04
export DOCKER_CLI_EXPERIMENTAL=enabled
## Required to have docker build output always printed on stdout
export BUILDKIT_PROGRESS=plain

current_os := $(shell uname -s)
current_arch := $(shell uname -m)

export OS ?= $(shell \
	case "$(current_os)" in \
		(Linux) echo linux ;; \
		(Darwin) echo linux ;; \
		(MINGW*|MSYS*|CYGWIN*) echo windows ;; \
		(*) echo unknown ;; \
	esac)

export ARCH ?= $(shell \
	case $(current_arch) in \
		(x86_64) echo "amd64" ;; \
		(aarch64|arm64) echo "arm64" ;; \
		(armv7*) echo "arm/v7";; \
		(s390*|riscv*|ppc64le) echo $(current_arch);; \
		(*) echo "UNKNOWN-CPU";; \
	esac)

##### Macros
## Check the presence of a CLI in the current PATH
check_cli = type "$(1)" >/dev/null 2>&1 || { echo "Error: command '$(1)' required but not found. Exiting." ; exit 1 ; }
## Check if a given image exists in the current manifest docker-bake.hcl
check_image = make --silent list | grep -w '$(1)' >/dev/null 2>&1 || { echo "Error: the image '$(1)' does not exist in manifest for the current platform '$(OS)/$(ARCH)'. Please check the output of 'make list'. Exiting." ; exit 1 ; }
## Base "docker buildx base" command to be reused everywhere
bake_base_cli := docker buildx bake --file docker-bake.hcl
## Command to be used on build (only)
bake_cli := $(bake_base_cli) --load
## Default bake target
bake_default_target := all

.PHONY: build
.PHONY: test test-alpine test-debian

check-reqs:
## Build requirements
	@$(call check_cli,bash)
	@$(call check_cli,git)
	@$(call check_cli,docker)
	@docker info | grep 'buildx:' >/dev/null 2>&1 || { echo "Error: Docker BuildX plugin required but not found. Exiting." ; exit 1 ; }
## Test requirements
	@$(call check_cli,curl)
	@$(call check_cli,jq)

## This function is specific to Jenkins infrastructure and isn't required in other contexts
docker-init: check-reqs
ifeq ($(CI),true)
ifeq ($(wildcard /etc/buildkitd.toml),)
	echo 'WARNING: /etc/buildkitd.toml not found, using default configuration.'
	docker buildx create --use --bootstrap --driver docker-container
else
	docker buildx create --use --bootstrap --driver docker-container --config /etc/buildkitd.toml
endif
else
	docker buildx create --use --bootstrap --driver docker-container
endif
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker info

# Lint check on all Dockerfiles
hadolint:
	find . -type f -name 'Dockerfile*' -not -path "./bats/*" -print0 | xargs -0 $(ROOT_DIR)/tools/hadolint

# Shellcheck on all bash scripts
shellcheck:
	@$(ROOT_DIR)/tools/shellcheck -e SC1091 jenkins-agent *.sh tests/test_helpers.bash tests/*.bats tools/hadolint tools/shellcheck

# Build all targets with the current OS and architecture
build: check-reqs target showarch-$(ARCH)
	@set -x; $(bake_cli) --metadata-file=target/build-result-metadata_$(bake_default_target).json --set '*.platform=$(OS)/$(ARCH)' $(shell make --silent list)

# Build a specific target with the current OS and architecture
build-%: check-reqs target show-%
	@$(call check_image,$*)
	@echo "== building $*"
	@set -x; $(bake_cli) --metadata-file=target/build-result-metadata_$*.json --set '*.platform=$(OS)/$(ARCH)' '$*'

# Build default bake group corresponding to the current OS but independently of the architecture
multiarchbuild: check-reqs show-$(OS)
	@set -x; $(bake_base_cli) $(OS)

# Build a specific bake group or target independently of the architecture or the OS
multiarchbuild-%: check-reqs show-%
	@set -x; $(bake_base_cli) $*

# Show all default targets
show:
	@set -x; make --silent show-$(bake_default_target)

# Show a specific target
show-%:
	@set -x; $(bake_base_cli) --progress=quiet --print $* | jq

# Show all targets depending on the architecture
showarch-%:
	@set -x; make --silent show | jq --arg arch "$(OS)/$*" '.target |= with_entries(select(.value.platforms | index($$arch)))'

# List tags of all default targets
tags:
	@set -x; make --silent tags-$(bake_default_target)

# List tags of a specific target
tags-%:
	@set -x; make --silent show-$* | jq -r '.target | to_entries[] | .key as $$name | .value.tags[] | "\(.) (\($$name))"' | LC_ALL=C sort -u

# Return the list of targets depending on the current OS and architecture
list: check-reqs
	@set -x; make --silent listarch-$(ARCH)

# Return the list of targets of a specific "target" (can be a docker bake group)
list-%: check-reqs
	@set -x; make --silent show-$* | jq -r '.target | keys[]'

# Return the list of targets depending on the current OS and architecture
listarch-%: check-reqs
	@set -x; make --silent showarch-$* | jq -r '.target | keys[]'

# Ensure bats exists in the current folder
bats:
	git clone --branch v1.13.0 https://github.com/bats-core/bats-core ./bats

# Ensure all bats submodules are up to date
prepare-test: bats check-reqs target
	git submodule update --init --recursive

# Ensure tests and build metadata "target" folder exist
target:
	mkdir -p target

# Publish all targets corresponding to the current OS
publish:
	@set -x; make --silent publish-$(OS)

# Publish a specific "target" (can be a docker bake group)
publish-%: target show-%
	@set -x; $(bake_base_cli) --metadata-file=target/build-result-metadata_$*_publish.json --push $*

## Define bats options based on environment
# common flags for all tests
bats_flags := ""
# if DISABLE_PARALLEL_TESTS true, then disable parallel execution
ifneq (true,$(DISABLE_PARALLEL_TESTS))
# If the GNU 'parallel' command line is absent, then disable parallel execution
parallel_cli := $(shell command -v parallel 2>/dev/null)
ifneq (,$(parallel_cli))
# If parallel execution is enabled, then set 2 tests per core available for the Docker Engine
test-%: PARALLEL_JOBS ?= $(shell echo $$(( $(shell docker run --rm alpine grep -c processor /proc/cpuinfo) * 2)))
test-%: bats_flags += --jobs $(PARALLEL_JOBS)
endif
endif
# Optional bats flags (see https://bats-core.readthedocs.io/en/stable/usage.html)
ifneq (,$(BATS_FLAGS))
test-%: bats_flags += $(BATS_FLAGS)
endif
test-%: prepare-test
# Check that the image exists in the manifest
	@$(call check_image,$*)
# Ensure that the image is built
	@set -x; make --silent build-$*
# Show bats version
	@set -x; bats/bin/bats --version
# Each type of image ("agent" or "inbound-agent") has its own tests suite
ifeq ($(CI), true)
# Execute the test harness and write result to a TAP file
	IMAGE=$* bats/bin/bats $(CURDIR)/tests/tests_$(shell echo $* |  cut -d "_" -f 1).bats $(bats_flags) --formatter junit | tee target/junit-results-$*.xml
else
# Execute the test harness
	IMAGE=$* bats/bin/bats $(CURDIR)/tests/tests_$(shell echo $* |  cut -d "_" -f 1).bats $(bats_flags) --timing
endif

# Test targets depending on the current architecture
test:
	@set -x; make --silent list | while read image; do make --silent "test-$${image}"; done
