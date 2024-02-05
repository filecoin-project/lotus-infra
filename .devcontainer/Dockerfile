FROM python:3.9-slim

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1 \
    && apt-get -y install git iproute2 procps lsb-release \
    && apt-get -y install ansible

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Verify git, process tools, lsb-release (useful for CLI installs)
RUN apt-get -y install git procps lsb-release

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -ms /bin/bash vscode

USER vscode
WORKDIR /home/vscode

CMD [ "bash" ]
