# syntax=docker/dockerfile:1
FROM eclipse-temurin:25-jdk-noble

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG MAVEN_VERSION=3.9.9
ARG MVND_VERSION=1.0.2

# Packages de base + SSH server (pour JetBrains Gateway)
# Force HTTPS mirrors to avoid HTTP auth/proxy issues in some enterprise networks.
RUN sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g; s|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update && apt-get install -y --no-install-recommends \
    git curl wget unzip zip ca-certificates gnupg2 \
    openssh-server sudo procps lsof jq \
    && rm -rf /var/lib/apt/lists/*

# Ensure X11 socket dir can be managed by non-root users (VS Code helper on Podman).
RUN mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp /tmp/.X11-unix

# Installer OpenShift CLI (oc)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then OC_ARCH="linux"; \
       elif [ "$ARCH" = "arm64" ]; then OC_ARCH="linux-arm64"; \
       else echo "Unsupported arch: $ARCH" && exit 1; fi \
    && curl -fsSL "https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/stable/openshift-client-${OC_ARCH}.tar.gz" \
    | tar xz -C /usr/local/bin oc kubectl \
    && chmod +x /usr/local/bin/oc /usr/local/bin/kubectl

# Créer l'utilisateur non-root
RUN EXISTING_UID_USER="$(getent passwd ${USER_UID} | cut -d: -f1 || true)" \
    && if id -u ${USERNAME} >/dev/null 2>&1; then \
        true; \
    elif [ -n "${EXISTING_UID_USER}" ]; then \
        usermod -l ${USERNAME} "${EXISTING_UID_USER}" \
        && usermod -d /home/${USERNAME} -m ${USERNAME} \
        && if getent group ${USER_GID} >/dev/null 2>&1; then \
            EXISTING_GID_GROUP="$(getent group ${USER_GID} | cut -d: -f1)" \
            && if [ "${EXISTING_GID_GROUP}" != "${USERNAME}" ]; then groupmod -n ${USERNAME} "${EXISTING_GID_GROUP}"; fi; \
           else \
            groupadd --gid ${USER_GID} ${USERNAME}; \
           fi \
        && usermod -g ${USER_GID} ${USERNAME}; \
    else \
        if ! getent group ${USER_GID} >/dev/null 2>&1; then groupadd --gid ${USER_GID} ${USERNAME}; fi \
        && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash; \
    fi \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
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
