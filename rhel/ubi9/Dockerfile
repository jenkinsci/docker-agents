ARG UBI9_TAG=9.8-1784165989
FROM registry.access.redhat.com/ubi9/ubi:"${UBI9_TAG}" AS jre-build

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# This Build ARG is populated by Docker
# Ref. https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETPLATFORM

COPY adoptium-get-jdk-link.sh /usr/bin/local/adoptium-get-jdk-link.sh
COPY adoptium-install-jdk.sh /usr/bin/local/adoptium-install-jdk.sh

# TODO: remove jq along with the adoptium shell script in favor of direct JDK archive URL maintained by updatecli/renovabot
COPY ./gpg-keys/jq-keyring.kbx /tmp/gpg-keys/jq-keyring.kbx
ARG JQ_VERSION=1.8.2

ARG JAVA_VERSION=17.0.19_10

# hadolint ignore=DL3041
RUN dnf install --disableplugin=subscription-manager --setopt=install_weak_deps=0 --setopt=tsflags=nodocs --allowerasing -y \
    ca-certificates \
    curl \
    && dnf clean --disableplugin=subscription-manager all \
    && keyring_file="/tmp/gpg-keys/jq-keyring.kbx" \
    && jq_temp_download_dir="$(mktemp -d)" \
    && arch=$(uname -m | sed -e 's/x86_64/amd64/g' -e 's/aarch64/arm64/g') \
    # Relative paths (assuming we're working from inside the temp dir)
    && jq_binary_file="jq-linux-${arch}" \
    && jq_sig_file="${jq_binary_file}.asc" \
    && pushd "${jq_temp_download_dir}" \
    && curl --fail --silent --show-error --location --output "${jq_binary_file}" \
      "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/${jq_binary_file}" \
    # The detached signature is published in the jq repository's sig/ tree (not as a release asset)
    && curl --fail --silent --show-error --location --output "${jq_sig_file}" \
      "https://raw.githubusercontent.com/jqlang/jq/master/sig/v${JQ_VERSION}/${jq_sig_file}" \
    && gpgv --keyring="${keyring_file}" "${jq_sig_file}" "${jq_binary_file}" \
    && cp "${jq_binary_file}" /usr/local/bin/jq \
    && chmod a+x /usr/local/bin/jq \
    && /usr/bin/local/adoptium-install-jdk.sh

ENV PATH="/opt/jdk-${JAVA_VERSION}/bin:${PATH}"

# Generate smaller java runtime without unneeded files
# for now we include the full module path to maintain compatibility
# while still saving space (approx 200mb from the full distribution)
# TODO: extract this to a common script instead of ignoring SC2086
# hadolint ignore=SC2086
RUN java_major_version="$(jlink --version 2>&1 | cut -c1-2)"; \
  if [[ "${TARGETPLATFORM}" == "linux/arm/v7" || "${java_major_version}" == 25 ]]; then \
    # It is acceptable to have a larger image in arm/v7 (arm 32 bits) environment
    # because jlink fails with the error "jmods: Value too large for defined data type" error.
    # For JDK25, we need to have a proper test and validation process first cf https://github.com/jenkinsci/docker-agents/issues/1124)
    # Noting there isn't any JMODs shipped anymore since https://adoptium.net/en-GB/news/2025/08/eclipse-temurin-jdk24-JEP493-enabled
    cp -r "/opt/jdk-${JAVA_VERSION}" /javaruntime; \
  else \
    case "$(jlink --version 2>&1 | cut -c1-2)" in \
      "17") options="--compress=2 --add-modules ALL-MODULE-PATH" ;; \
      "21") options="--compress=zip-6 --add-modules ALL-MODULE-PATH" ;; \
      *) echo "ERROR: unmanaged jlink version pattern" && exit 1 ;; \
    esac; \
    jlink \
      --strip-java-debug-attributes \
      ${options} \
      --no-man-pages \
      --no-header-files \
      --output /javaruntime; \
  fi

FROM registry.access.redhat.com/ubi9/ubi:"${UBI9_TAG}" AS agent

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN groupadd -g "${gid}" "${group}" \
  && useradd -l -c "Jenkins user" -d /home/"${user}" -u "${uid}" -g "${gid}" -m "${user}" || echo "user ${user} already exists."

ARG AGENT_WORKDIR=/home/"${user}"/agent
ENV TZ=Etc/UTC

# hadolint ignore=DL3041
RUN dnf install --disableplugin=subscription-manager --setopt=install_weak_deps=0 --setopt=tsflags=nodocs -y \
      ca-certificates \
      fontconfig \
      git \
      less \
      patch \
      tzdata \
    && dnf clean --disableplugin=subscription-manager all

ARG VERSION=3261.v9c670a_4748a_9
ADD --chown="${user}":"${group}" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" /usr/share/jenkins/agent.jar
RUN chmod 0644 /usr/share/jenkins/agent.jar \
    && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ARG GIT_LFS_VERSION=3.7.1
RUN arch=$(uname -m | sed -e 's/x86_64/amd64/g' -e 's/aarch64/arm64/g') \
  && curl -L -s -o git-lfs.tgz "https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-${arch}-v${GIT_LFS_VERSION}.tar.gz" \
  && tar xzf git-lfs.tgz \
  && bash git-lfs-*/install.sh \
  && git lfs install --skip-repo --system \
  && rm -rf git-lfs*

ENV LANG=C.UTF-8

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=jre-build /javaruntime "$JAVA_HOME"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

USER "${user}"
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir -p /home/"${user}"/.jenkins && mkdir -p "${AGENT_WORKDIR}"

VOLUME /home/"${user}"/.jenkins
VOLUME "${AGENT_WORKDIR}"
WORKDIR /home/"${user}"
ENV USER=${user}
LABEL \
  org.opencontainers.image.vendor="Jenkins project" \
  org.opencontainers.image.title="Official Jenkins Agent Base container image for UBI 9" \
  org.opencontainers.image.description="This is a base image, which provides the Jenkins agent executable (agent.jar)" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.url="https://www.jenkins.io/" \
  org.opencontainers.image.source="https://github.com/jenkinsci/docker-agents" \
  org.opencontainers.image.licenses="MIT"

## Inbound Agent image target
FROM agent AS inbound-agent

ARG user=jenkins

USER root
COPY ../../jenkins-agent /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent &&\
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave
USER ${user}

LABEL \
  org.opencontainers.image.vendor="Jenkins project" \
  org.opencontainers.image.title="Official Jenkins Inbound Agent Base container image for UBI 9" \
  org.opencontainers.image.description="This is an image for Jenkins agents using TCP or WebSockets to establish inbound connection to the Jenkins controller" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.url="https://www.jenkins.io/" \
  org.opencontainers.image.source="https://github.com/jenkinsci/docker-agents" \
  org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
