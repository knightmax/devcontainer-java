# syntax=docker/dockerfile:1
FROM eclipse-temurin:25-jdk-noble

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG MAVEN_VERSION=3.9.9
ARG MVND_VERSION=1.0.2

# Packages de base + SSH server (pour JetBrains Gateway)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget unzip zip ca-certificates gnupg2 \
    openssh-server sudo procps lsof jq \
    && rm -rf /var/lib/apt/lists/*

# Installer OpenShift CLI (oc)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then OC_ARCH="linux"; \
       elif [ "$ARCH" = "arm64" ]; then OC_ARCH="linux-arm64"; \
       else echo "Unsupported arch: $ARCH" && exit 1; fi \
    && curl -fsSL "https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/stable/openshift-client-${OC_ARCH}.tar.gz" \
    | tar xz -C /usr/local/bin oc kubectl \
    && chmod +x /usr/local/bin/oc /usr/local/bin/kubectl

# Créer l'utilisateur non-root
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Installer Maven
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

# Installer mvnd (Maven Daemon)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then MVND_ARCH="linux-amd64"; \
       elif [ "$ARCH" = "arm64" ]; then MVND_ARCH="linux-aarch64"; \
       else echo "Unsupported arch: $ARCH" && exit 1; fi \
    && curl -fsSL "https://github.com/apache/maven-mvnd/releases/download/${MVND_VERSION}/maven-mvnd-${MVND_VERSION}-${MVND_ARCH}.tar.gz" \
    | tar xz -C /opt \
    && ln -s /opt/maven-mvnd-${MVND_VERSION}-${MVND_ARCH} /opt/mvnd
ENV MVND_HOME=/opt/mvnd
ENV PATH="${MVND_HOME}/bin:${PATH}"

# Configurer SSH pour JetBrains Gateway
RUN mkdir -p /run/sshd \
    && sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Script d'import des certificats entreprise
COPY scripts/setup-certs.sh /usr/local/bin/setup-certs.sh
RUN chmod +x /usr/local/bin/setup-certs.sh

# Répertoires Maven/mvnd pour le cache
RUN mkdir -p /home/${USERNAME}/.m2/repository /home/${USERNAME}/.mvnd \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.m2 /home/${USERNAME}/.mvnd

# Répertoire pour les certificats montés depuis l'hôte
RUN mkdir -p /usr/local/share/ca-certificates/enterprise

USER ${USERNAME}
WORKDIR /workspace
