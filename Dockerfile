FROM registry.tusimple.ai/base:16.04

ARG GO_VERSION=1.15.1

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
RUN rm ~/.aws/credential && sapt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
# Core packages
RUN apt install -y \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  dkms \
  emacs \
  git \
  htop \
  jq \
  libfreetype6-dev \
  libhdf5-dev \
  libjpeg-dev \
  libopenblas-base \
  libibverbs1 \
  libpng-dev \
  pciutils \
  pkg-config \
  protobuf-compiler \
  python3-pip python-pip \
  python3-tk python-tk \
  rsync \
  screen \
  software-properties-common \
  tmux \
  tree \
  unzip \
  vim \
  wget \
  zip \
  zlib1g-dev \
  graphviz \
  pandoc \
  texlive-xetex \
  inotify-tools \
  lsof \
  python3-venv \
      && \
    rm -rf /var/lib/apt/lists/*

# Install node and yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    apt update && \
    apt install -y yarn

# Install Go
RUN wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O go_install.tar.gz && \
    tar -C /usr/local -xzf ./go_install.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    echo "export PATH=\$PATH:/usr/local/go/bin" | tee -a /root/.bashrc && \
    rm -f go_install.tar.gz

# Install VSCode
RUN curl -fsSL https://code-server.dev/install.sh | sh
COPY ./vscode_config.yaml /root/.config/code-server/config.yaml
COPY ./settings.json /root/.local/share/code-server/User/settings.json

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable" && \
    apt update && \
    apt install -y docker-ce docker-ce-cli containerd.io

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -f awscliv2.zip && \
    rm -rf ./aws

# Configs for VSCode server
ENV SHELL="/bin/bash"
EXPOSE 443
ENTRYPOINT ["code-server"]
