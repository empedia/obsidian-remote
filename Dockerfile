FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

LABEL maintainer="github@sytone.com" \
      org.opencontainers.image.authors="github@sytone.com" \
      org.opencontainers.image.source="https://github.com/sytone/obsidian-remote" \
      org.opencontainers.image.title="Container hosted Obsidian MD" \
      org.opencontainers.image.description="Hosted Obsidian instance allowing access via web browser"

# Update and install extra packages.
RUN echo "**** install packages ****" && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl libgtk-3-0 libnotify4 libatspi2.0-0 libsecret-1-0 libsecret-1-dev libnss3 desktop-file-utils fonts-noto-color-emoji git make gcc  ksshaskpass && \
    apt-get autoclean && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Set version label
ARG OBSIDIAN_VERSION=1.3.5

# Download and install Obsidian
RUN echo "**** download obsidian ****" && \
    curl --location --output obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION}_amd64.deb" && \
    dpkg -i obsidian.deb

RUN echo "**** get and make git-credential-libsecret ****" && \
    git clone -n --depth=1 --filter=tree:0 https://github.com/git/git.git && \
    cd git && \
    git sparse-checkout set --no-cone /contrib/credential/libsecret && \
    git checkout && \
    cd ./contrib/credential/libsecret && \
    make
    

RUN echo "**** configure git to use libsecret and ksshaskpass ****" && \
    git config --global credential.helper /git/contrib/credential/libsecret/git-credential-libsecret && \
    git config --global core.askPass "ksshaskpass"


#RUN echo "**** install git credential manager ****" && \
#    curl --location --output gcm.deb "https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.2.1/gcm-linux_amd64.2.2.1.deb" && \
#    dpkg -i gcm.deb && \
#    git-credential-manager configure

# Environment variables
ENV CUSTOM_PORT="8080" \
    CUSTOM_HTTPS_PORT="8443" \
    CUSTOM_USER="" \
    PASSWORD="" \
    SUBFOLDER="" \
    TITLE="Obsidian v${OBSIDIAN_VERSION}" \
    FM_HOME="/vaults" \
    GCM_CREDENTIAL_STORE="cache"

# Add local files
COPY root/ /
EXPOSE 8080 8443
VOLUME ["/config","/vaults"]

# Define a healthcheck
HEALTHCHECK CMD curl --fail http://localhost:8080/ || exit 1
