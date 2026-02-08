# Jenkins Agent and Inbound Agent Docker images

[![Join the chat at https://gitter.im/jenkinsci/docker](https://badges.gitter.im/jenkinsci/docker.svg)](https://gitter.im/jenkinsci/docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![GitHub stars](https://img.shields.io/github/stars/jenkinsci/docker-agent?label=GitHub%20stars)](https://github.com/jenkinsci/docker-agents)
[![GitHub release](https://img.shields.io/github/release/jenkinsci/docker-agent.svg?label=changelog)](https://github.com/jenkinsci/docker-agents/releases/latest)

This repository contains the definition of Jenkins agent and inbound agent Docker images.

## agent
[![Docker Pulls](https://img.shields.io/docker/pulls/jenkins/agent.svg)](https://hub.docker.com/r/jenkins/agent/)

This is a base image for Docker, which includes JDK and the Jenkins agent executable (agent.jar).

See [the `agent` README](./README_agent.md)

## inbound-agent
[![Docker Pulls](https://img.shields.io/docker/pulls/jenkins/inbound-agent.svg)](https://hub.docker.com/r/jenkins/inbound-agent/)

This is an image based on `agent` for [Jenkins](https://jenkins.io) agents using TCP or WebSockets to establish inbound connection to the Jenkins controller.

See [the `inbound-agent` README](./README_inbound-agent.md)

## Building

### Building and testing on Linux

#### Target images

If you want to see the target images (matching your current OS and architecture) that will be built, you can issue the following command:

```bash
$ make list
+ make --silent listarch-arm64
+ make --silent showarch-arm64
+ jq -r '.target | keys[]'
+ make --silent show
+ jq --arg arch linux/arm64 '.target |= with_entries(select(.value.platforms | index($arch)))'
+ make --silent show-all
+ docker buildx bake --file docker-bake.hcl --progress=quiet --print all
+ jq
agent_alpine_jdk21
agent_alpine_jdk25
agent_debian_jdk17
agent_debian_jdk21
agent_debian_jdk25
agent_rhel_ubi9_jdk17
agent_rhel_ubi9_jdk21
agent_rhel_ubi9_jdk25
inbound-agent_alpine_jdk21
inbound-agent_alpine_jdk25
inbound-agent_debian_jdk17
inbound-agent_debian_jdk21
inbound-agent_debian_jdk25
inbound-agent_rhel_ubi9_jdk17
inbound-agent_rhel_ubi9_jdk21
inbound-agent_rhel_ubi9_jdk25
```

To list them all:

```bash
$ make list-all
+ make --silent show-all
+ jq -r '.target | keys[]'
+ docker buildx bake --file docker-bake.hcl --progress=quiet --print all
+ jq
agent_alpine_jdk17
agent_alpine_jdk21
agent_alpine_jdk25
agent_debian_jdk17
agent_debian_jdk21
agent_debian_jdk25
agent_nanoserver-ltsc2019_jdk17
agent_nanoserver-ltsc2019_jdk21
agent_nanoserver-ltsc2019_jdk25
agent_nanoserver-ltsc2022_jdk17
agent_nanoserver-ltsc2022_jdk21
agent_nanoserver-ltsc2022_jdk25
agent_rhel_ubi9_jdk17
agent_rhel_ubi9_jdk21
agent_rhel_ubi9_jdk25
agent_windowsservercore-ltsc2019_jdk17
agent_windowsservercore-ltsc2019_jdk21
agent_windowsservercore-ltsc2019_jdk25
agent_windowsservercore-ltsc2022_jdk17
agent_windowsservercore-ltsc2022_jdk21
agent_windowsservercore-ltsc2022_jdk25
inbound-agent_alpine_jdk17
inbound-agent_alpine_jdk21
inbound-agent_alpine_jdk25
inbound-agent_debian_jdk17
inbound-agent_debian_jdk21
inbound-agent_debian_jdk25
inbound-agent_nanoserver-ltsc2019_jdk17
inbound-agent_nanoserver-ltsc2019_jdk21
inbound-agent_nanoserver-ltsc2019_jdk25
inbound-agent_nanoserver-ltsc2022_jdk17
inbound-agent_nanoserver-ltsc2022_jdk21
inbound-agent_nanoserver-ltsc2022_jdk25
inbound-agent_rhel_ubi9_jdk17
inbound-agent_rhel_ubi9_jdk21
inbound-agent_rhel_ubi9_jdk25
inbound-agent_windowsservercore-ltsc2019_jdk17
inbound-agent_windowsservercore-ltsc2019_jdk21
inbound-agent_windowsservercore-ltsc2019_jdk25
inbound-agent_windowsservercore-ltsc2022_jdk17
inbound-agent_windowsservercore-ltsc2022_jdk21
inbound-agent_windowsservercore-ltsc2022_jdk25
```

You can see and use other targets by setting `OS` and/or `ARCH`:

```
$ OS=windows ARCH=amd64 make list
+ make --silent listarch-amd64
+ make --silent showarch-amd64
+ jq -r '.target | keys[]'
+ make --silent show
+ jq --arg arch windows/amd64 '.target |= with_entries(select(.value.platforms | index($arch)))'
+ make --silent show-all
+ docker buildx bake --file docker-bake.hcl --progress=quiet --print all
+ jq
agent_nanoserver-ltsc2019_jdk17
agent_nanoserver-ltsc2019_jdk21
agent_nanoserver-ltsc2019_jdk25
agent_nanoserver-ltsc2022_jdk17
agent_nanoserver-ltsc2022_jdk21
agent_nanoserver-ltsc2022_jdk25
agent_windowsservercore-ltsc2019_jdk17
agent_windowsservercore-ltsc2019_jdk21
agent_windowsservercore-ltsc2019_jdk25
agent_windowsservercore-ltsc2022_jdk17
agent_windowsservercore-ltsc2022_jdk21
agent_windowsservercore-ltsc2022_jdk25
inbound-agent_nanoserver-ltsc2019_jdk17
inbound-agent_nanoserver-ltsc2019_jdk21
inbound-agent_nanoserver-ltsc2019_jdk25
inbound-agent_nanoserver-ltsc2022_jdk17
inbound-agent_nanoserver-ltsc2022_jdk21
inbound-agent_nanoserver-ltsc2022_jdk25
inbound-agent_windowsservercore-ltsc2019_jdk17
inbound-agent_windowsservercore-ltsc2019_jdk21
inbound-agent_windowsservercore-ltsc2019_jdk25
inbound-agent_windowsservercore-ltsc2022_jdk17
inbound-agent_windowsservercore-ltsc2022_jdk21
inbound-agent_windowsservercore-ltsc2022_jdk25
```

#### Building a specific image

If you want to build a specific image, you can issue the following command:

```bash
make build-<AGENT_TYPE>_<LINUX_FLAVOR>_<JDK_VERSION>
```

That would give for an image of an inbound agent with JDK 17 on Debian:

```bash
make build-inbound-agent_debian_jdk17
```

#### Building images supported by your current architecture

Then, you can build the images supported by your current architecture by running:

```bash
make build
```

#### Testing all images

If you want to test these images, you can run:

```bash
make test
```
#### Testing a specific image

If you want to test a specific image, you can run:

```bash
make test-<AGENT_TYPE>_<LINUX_FLAVOR>_<JDK_VERSION>
```

That would give for an image of an inbound agent with JDK 17 on Debian:

```bash
make test-inbound-agent_debian_jdk17
```

#### Building all images

You can build all images for your OS (even those unsupported by your current architecture) by running:

```bash
make multiarchbuild
```

#### Other `make` targets

##### Target `show`

This target (and `show-<bake group>`) gives us a detailed view of the images that could be built (with tags, platforms, and Dockerfiles), independently of your current OS or architecture.

Note that to see all tags created on publication, you'll have to set `ON_TAG` to `true`.

```json
$ make show
+ make --silent show-all
+ docker buildx bake --file docker-bake.hcl --progress=quiet --print all
+ jq
{
  "group": {
    "alpine": {
      "targets": [
        "agent_alpine_jdk17",
        "agent_alpine_jdk21",
        "inbound-agent_alpine_jdk17",
        "inbound-agent_alpine_jdk21"
      ]
    },
    "debian": {
      "targets": [
        "agent_debian_jdk17",
        "agent_debian_jdk21",
        "inbound-agent_debian_jdk17",
        "inbound-agent_debian_jdk21"
      ]
    },
    "default": {
      "targets": [
        "linux"
      ]
    },
    "linux": {
      "targets": [
        "alpine",
        "debian",
        "rhel_ubi9"
      ]
    },
    "rhel_ubi9": {
      "targets": [
        "agent_rhel_ubi9_jdk17",
        "agent_rhel_ubi9_jdk21",
        "inbound-agent_rhel_ubi9_jdk17",
        "inbound-agent_rhel_ubi9_jdk21"
      ]
    }
  },
  "target": {
    "agent_alpine_jdk17": {
      "context": ".",
      "dockerfile": "alpine/Dockerfile",
      "args": {
        "ALPINE_TAG": "3.23.3",
        "JAVA_VERSION": "17.0.18_8",
        "VERSION": "3355.v388858a_47b_33"
      },
      "tags": [
        "docker.io/jenkins/agent:alpine",
        "docker.io/jenkins/agent:latest-alpine",
        "docker.io/jenkins/agent:alpine-jdk17",
        "docker.io/jenkins/agent:latest-alpine-jdk17",
        "docker.io/jenkins/agent:alpine3.23",
        "docker.io/jenkins/agent:latest-alpine3.23",
        "docker.io/jenkins/agent:alpine3.23-jdk17",
        "docker.io/jenkins/agent:latest-alpine3.23-jdk17"
      ],
      "target": "agent",
      "platforms": [
        "linux/amd64"
      ],
      "output": [
        {
          "type": "docker"
        }
      ]
    },
    [...]
  }
}
```

##### Target `tags`

To view all tags, set `ON_TAG` (and eventually `BUILD_NUMBER`):
```bash
$ ON_TAG=true BUILD_NUMBER=3 make tags
```
<details><summary>Output</summary>

```
docker.io/hlemeur/agent:3355.v388858a_47b_33-3 (agent_debian_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine (agent_alpine_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine-jdk17 (agent_alpine_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine-jdk21 (agent_alpine_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine-jdk25 (agent_alpine_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine3.23 (agent_alpine_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine3.23-jdk17 (agent_alpine_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine3.23-jdk21 (agent_alpine_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-alpine3.23-jdk25 (agent_alpine_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk17 (agent_debian_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk17-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk17-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk17-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk17-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk21 (agent_debian_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk21-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk21-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk21-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk21-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk25 (agent_debian_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk25-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk25-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk25-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-jdk25-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-rhel-ubi9 (agent_rhel_ubi9_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-rhel-ubi9-jdk17 (agent_rhel_ubi9_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-rhel-ubi9-jdk21 (agent_rhel_ubi9_jdk21)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-rhel-ubi9-jdk25 (agent_rhel_ubi9_jdk25)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/agent:3355.v388858a_47b_33-3-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/agent:alpine (agent_alpine_jdk17)
docker.io/hlemeur/agent:alpine-jdk17 (agent_alpine_jdk17)
docker.io/hlemeur/agent:alpine-jdk21 (agent_alpine_jdk21)
docker.io/hlemeur/agent:alpine-jdk25 (agent_alpine_jdk25)
docker.io/hlemeur/agent:alpine3.23 (agent_alpine_jdk17)
docker.io/hlemeur/agent:alpine3.23-jdk17 (agent_alpine_jdk17)
docker.io/hlemeur/agent:alpine3.23-jdk21 (agent_alpine_jdk21)
docker.io/hlemeur/agent:alpine3.23-jdk25 (agent_alpine_jdk25)
docker.io/hlemeur/agent:jdk17 (agent_debian_jdk17)
docker.io/hlemeur/agent:jdk17-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/agent:jdk17-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/agent:jdk17-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/agent:jdk17-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/agent:jdk21 (agent_debian_jdk21)
docker.io/hlemeur/agent:jdk21-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk21)
docker.io/hlemeur/agent:jdk21-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk21)
docker.io/hlemeur/agent:jdk21-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk21)
docker.io/hlemeur/agent:jdk21-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk21)
docker.io/hlemeur/agent:jdk25 (agent_debian_jdk25)
docker.io/hlemeur/agent:jdk25-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk25)
docker.io/hlemeur/agent:jdk25-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk25)
docker.io/hlemeur/agent:jdk25-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk25)
docker.io/hlemeur/agent:jdk25-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk25)
docker.io/hlemeur/agent:latest (agent_debian_jdk17)
docker.io/hlemeur/agent:latest-alpine (agent_alpine_jdk17)
docker.io/hlemeur/agent:latest-alpine-jdk17 (agent_alpine_jdk17)
docker.io/hlemeur/agent:latest-alpine-jdk21 (agent_alpine_jdk21)
docker.io/hlemeur/agent:latest-alpine-jdk25 (agent_alpine_jdk25)
docker.io/hlemeur/agent:latest-alpine3.23 (agent_alpine_jdk17)
docker.io/hlemeur/agent:latest-alpine3.23-jdk17 (agent_alpine_jdk17)
docker.io/hlemeur/agent:latest-alpine3.23-jdk21 (agent_alpine_jdk21)
docker.io/hlemeur/agent:latest-alpine3.23-jdk25 (agent_alpine_jdk25)
docker.io/hlemeur/agent:latest-jdk17 (agent_debian_jdk17)
docker.io/hlemeur/agent:latest-jdk21 (agent_debian_jdk21)
docker.io/hlemeur/agent:latest-jdk25 (agent_debian_jdk25)
docker.io/hlemeur/agent:latest-rhel-ubi9 (agent_rhel_ubi9_jdk17)
docker.io/hlemeur/agent:latest-rhel-ubi9-jdk17 (agent_rhel_ubi9_jdk17)
docker.io/hlemeur/agent:latest-rhel-ubi9-jdk21 (agent_rhel_ubi9_jdk21)
docker.io/hlemeur/agent:latest-rhel-ubi9-jdk25 (agent_rhel_ubi9_jdk25)
docker.io/hlemeur/agent:latest-trixie (agent_debian_jdk17)
docker.io/hlemeur/agent:latest-trixie-jdk17 (agent_debian_jdk17)
docker.io/hlemeur/agent:latest-trixie-jdk21 (agent_debian_jdk21)
docker.io/hlemeur/agent:latest-trixie-jdk25 (agent_debian_jdk25)
docker.io/hlemeur/agent:nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/agent:nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/agent:rhel-ubi9 (agent_rhel_ubi9_jdk17)
docker.io/hlemeur/agent:rhel-ubi9-jdk17 (agent_rhel_ubi9_jdk17)
docker.io/hlemeur/agent:rhel-ubi9-jdk21 (agent_rhel_ubi9_jdk21)
docker.io/hlemeur/agent:rhel-ubi9-jdk25 (agent_rhel_ubi9_jdk25)
docker.io/hlemeur/agent:trixie (agent_debian_jdk17)
docker.io/hlemeur/agent:trixie-jdk17 (agent_debian_jdk17)
docker.io/hlemeur/agent:trixie-jdk21 (agent_debian_jdk21)
docker.io/hlemeur/agent:trixie-jdk25 (agent_debian_jdk25)
docker.io/hlemeur/agent:windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/agent:windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3 (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine-jdk17 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine-jdk21 (inbound-agent_alpine_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine-jdk25 (inbound-agent_alpine_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine3.23 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine3.23-jdk17 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine3.23-jdk21 (inbound-agent_alpine_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-alpine3.23-jdk25 (inbound-agent_alpine_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk17 (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk17-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk17-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk17-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk17-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk21 (inbound-agent_debian_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk21-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk21-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk21-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk21-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk25 (inbound-agent_debian_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk25-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk25-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk25-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-jdk25-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-rhel-ubi9 (inbound-agent_rhel_ubi9_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-rhel-ubi9-jdk17 (inbound-agent_rhel_ubi9_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-rhel-ubi9-jdk21 (inbound-agent_rhel_ubi9_jdk21)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-rhel-ubi9-jdk25 (inbound-agent_rhel_ubi9_jdk25)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:3355.v388858a_47b_33-3-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:alpine (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:alpine-jdk17 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:alpine-jdk21 (inbound-agent_alpine_jdk21)
docker.io/hlemeur/inbound-agent:alpine-jdk25 (inbound-agent_alpine_jdk25)
docker.io/hlemeur/inbound-agent:alpine3.23 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:alpine3.23-jdk17 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:alpine3.23-jdk21 (inbound-agent_alpine_jdk21)
docker.io/hlemeur/inbound-agent:alpine3.23-jdk25 (inbound-agent_alpine_jdk25)
docker.io/hlemeur/inbound-agent:jdk17 (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:jdk21 (inbound-agent_debian_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk21)
docker.io/hlemeur/inbound-agent:jdk25 (inbound-agent_debian_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk25)
docker.io/hlemeur/inbound-agent:latest (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:latest-alpine (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:latest-alpine-jdk17 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:latest-alpine-jdk21 (inbound-agent_alpine_jdk21)
docker.io/hlemeur/inbound-agent:latest-alpine-jdk25 (inbound-agent_alpine_jdk25)
docker.io/hlemeur/inbound-agent:latest-alpine3.23 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:latest-alpine3.23-jdk17 (inbound-agent_alpine_jdk17)
docker.io/hlemeur/inbound-agent:latest-alpine3.23-jdk21 (inbound-agent_alpine_jdk21)
docker.io/hlemeur/inbound-agent:latest-alpine3.23-jdk25 (inbound-agent_alpine_jdk25)
docker.io/hlemeur/inbound-agent:latest-jdk17 (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:latest-jdk21 (inbound-agent_debian_jdk21)
docker.io/hlemeur/inbound-agent:latest-jdk25 (inbound-agent_debian_jdk25)
docker.io/hlemeur/inbound-agent:latest-rhel-ubi9 (inbound-agent_rhel_ubi9_jdk17)
docker.io/hlemeur/inbound-agent:latest-rhel-ubi9-jdk17 (inbound-agent_rhel_ubi9_jdk17)
docker.io/hlemeur/inbound-agent:latest-rhel-ubi9-jdk21 (inbound-agent_rhel_ubi9_jdk21)
docker.io/hlemeur/inbound-agent:latest-rhel-ubi9-jdk25 (inbound-agent_rhel_ubi9_jdk25)
docker.io/hlemeur/inbound-agent:latest-trixie (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:latest-trixie-jdk17 (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:latest-trixie-jdk21 (inbound-agent_debian_jdk21)
docker.io/hlemeur/inbound-agent:latest-trixie-jdk25 (inbound-agent_debian_jdk25)
docker.io/hlemeur/inbound-agent:nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:rhel-ubi9 (inbound-agent_rhel_ubi9_jdk17)
docker.io/hlemeur/inbound-agent:rhel-ubi9-jdk17 (inbound-agent_rhel_ubi9_jdk17)
docker.io/hlemeur/inbound-agent:rhel-ubi9-jdk21 (inbound-agent_rhel_ubi9_jdk21)
docker.io/hlemeur/inbound-agent:rhel-ubi9-jdk25 (inbound-agent_rhel_ubi9_jdk25)
docker.io/hlemeur/inbound-agent:trixie (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:trixie-jdk17 (inbound-agent_debian_jdk17)
docker.io/hlemeur/inbound-agent:trixie-jdk21 (inbound-agent_debian_jdk21)
docker.io/hlemeur/inbound-agent:trixie-jdk25 (inbound-agent_debian_jdk25)
docker.io/hlemeur/inbound-agent:windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk17)
```

</details>

You can also call `make tags-windows` to show Windows image tags:
```
docker.io/hlemeur/agent:jdk17-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/agent:jdk17-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/agent:jdk17-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/agent:jdk17-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/agent:jdk21-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk21)
docker.io/hlemeur/agent:jdk21-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk21)
docker.io/hlemeur/agent:jdk21-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk21)
docker.io/hlemeur/agent:jdk21-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk21)
docker.io/hlemeur/agent:jdk25-nanoserver-ltsc2019 (agent_nanoserver-ltsc2019_jdk25)
docker.io/hlemeur/agent:jdk25-nanoserver-ltsc2022 (agent_nanoserver-ltsc2022_jdk25)
docker.io/hlemeur/agent:jdk25-windowsservercore-ltsc2019 (agent_windowsservercore-ltsc2019_jdk25)
docker.io/hlemeur/agent:jdk25-windowsservercore-ltsc2022 (agent_windowsservercore-ltsc2022_jdk25)
docker.io/hlemeur/inbound-agent:jdk17-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk17)
docker.io/hlemeur/inbound-agent:jdk17-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk17)
docker.io/hlemeur/inbound-agent:jdk21-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk21)
docker.io/hlemeur/inbound-agent:jdk21-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk21)
docker.io/hlemeur/inbound-agent:jdk25-nanoserver-ltsc2019 (inbound-agent_nanoserver-ltsc2019_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-nanoserver-ltsc2022 (inbound-agent_nanoserver-ltsc2022_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-windowsservercore-ltsc2019 (inbound-agent_windowsservercore-ltsc2019_jdk25)
docker.io/hlemeur/inbound-agent:jdk25-windowsservercore-ltsc2022 (inbound-agent_windowsservercore-ltsc2022_jdk25)
```

##### Target `bats`

This target is a dependency target. It will update the [`bats` submodule](https://github.com/bats-core/bats-core) and run the tests.

```bash
make bats
make: 'bats' is up to date.
```

You can set `BATS_FLAGS` to pass arguments to `bats`, ex:
```bash
$ mkdir -p tests/.bats/run-logs
$ BATS_FLAGS="--trace --filter-status failed" make test
```

##### Target `publish`

This target allows the publication of all images targeted by 'linux' to a registry.

##### Target `docker-init`

This target is dedicated to Jenkins infrastructure for initializing docker and isn't required in other contexts.

### Building and testing on Windows

#### Building all images

Run `.\make.ps1` to launch the build of the images corresponding to the "windows" target of docker-bake.hcl.

Internally, the first time you'll run this script and if there is no build-windows_<AGENT_TYPE>_<WINDOWS_FLAVOR>_<WINDOWS_VERSION>.yaml file in your repository, it will use a combination of `docker buildx bake` and `yq` to generate a  build-windows_<AGENT_TYPE>_<WINDOWS_FLAVOR>_<WINDOWS_VERSION>.yaml docker compose file containing all Windows image definitions from docker-bake.hcl. Then it will run `docker compose` on this file to build these images.

You can modify this docker compose file as you want, then rerun `.\make.ps1`.
It won't regenerate the docker compose file from docker-bake.hcl unless you add the `-OverwriteDockerComposeFile` make.ps1 parameter:  `.\make.ps1 -OverwriteDockerComposeFile`.

Note: you can generate this docker compose file from docker-bake.hcl yourself with the following command (require `docker buildx` and `yq`):

```bash
# - Use docker buildx bake to output image definitions from the "windows" bake group
# - Convert with yq to the format expected by docker compose
# - Store the result in the docker compose file

$ docker buildx bake --progress=quiet --file=docker-bake.hcl windows --print \
    | yq --prettyPrint '.target[] | del(.output) | {(. | key): {"image": .tags[0], "build": .}}' | yq '{"services": .}' \
    > build-windows_mybuild.yaml
```

Note that you don't need make.ps1 to build (or to publish) your images from this docker compose file, you can use `docker compose --file=build-windows_mybuild.yaml build`.

#### Testing all images

Run `.\make.ps1 test` if you also want to run the tests harness suit.

Run `.\make.ps1 test -TestsDebug 'debug'` to also get commands & stderr of tests, displayed on top of them.
You can set it to `'verbose'` to also get stdout of every test command.

Note that instead of passing `-TestsDebug` parameter to make.ps1, you can set the  $env:TESTS_DEBUG environment variable to the desired value.

Also note that contrary to the Linux part, you have to build the images before testing them.

#### Golden files

A golden file (sometimes called a snapshot) is a file that contains the expected output of a program or function.
Tests compare the current output of the code against this "golden" reference to detect regressions or unintended changes.
They are treated as contract artifacts, not test fixtures.

Golden files may be updated only when:
- Output behavior is intentionally changed
- A bug fix corrects previously incorrect output
- A new test case is added

Golden updates must be reviewed like code.

If your work implies golden file changes, those changes must be committed:
- In the same commit as the behavior change
- With a commit message explaining why output changed

Golden updates must never be automatic.

##### How to update a golden file
- Reproduce output manually
- Inspect output
- Update the golden file explicitly
- Run tests

To update a golden file, you can use the dedicated ./tests/update-golden-file.sh helper script.

Example:
```
./tests/update-golden-file.sh expected_tags_linux make tags-linux
```

Then ensure corresponding tests are passing with:
```
bats ./tests/tags.bats
```

#### Dry run

Add the `-DryRun` parameter to print out any build, publish or tests commands instead of executing them: `.\make.ps1 test -DryRun`

#### Building and testing a specific image

You can build (and test) only one image type by setting `-ImageType` to a combination of Windows flavors ("nanoserver" & "windowsservercore") and Windows versions ("ltsc2019", "ltsc2022").

Ex: `.\make.ps1 -ImageType 'nanoserver-ltsc2019'`

You can also build (and test) only one agent type by setting `-AgentType` to either "agent" or "inbound-agent".

Ex: `.\make.ps1 -AgentType 'agent'`

Both parameters can be combined.
