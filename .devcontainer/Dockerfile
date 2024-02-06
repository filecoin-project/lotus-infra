FROM python:3-bookworm

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1 \
    && apt-get -y install git iproute2 procps lsb-release \
    && apt-get -y install ansible \
    && apt-get -y install git procps lsb-release jq vim

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=
VOLUME [ "/var/lib/docker" ]
COPY library-scripts/*.sh /tmp/library-scripts/
ENV DOCKER_BUILDKIT=1
RUN /bin/bash /tmp/library-scripts/docker-in-docker-debian.sh

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash vscode && usermod -aG docker vscode
RUN curl -LOs https://golang.org/dl/go1.20.7.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz

USER vscode
WORKDIR /home/vscode

ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["sleep", "infinity"]
