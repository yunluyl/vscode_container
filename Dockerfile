FROM ubuntu:18.04

ARG GO_VERSION=1.15.1

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
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
    rm -f go_install.tar.gz

# Install VSCode
RUN curl -fsSL https://code-server.dev/install.sh | sh
COPY ./vscode_config.yaml /root/.config/code-server/config.yaml

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable" && \
    apt update && \
    apt install -y docker-ce docker-ce-cli containerd.io

# Install Firebase CLI
RUN curl -sL https://firebase.tools | bash

# Install gcsfuse and gcloud, implicitly installs python2.7
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    export GCSFUSE_REPO="gcsfuse-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee -a /etc/apt/sources.list.d/gcsfuse.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt update -y && \
    apt install google-cloud-sdk gcsfuse -y && \
    rm -rf /var/lib/apt/lists/*

# Configs for VSCode server
ENV SHELL="/bin/bash"
EXPOSE 8080
CMD ["code-server"]
