FROM ubuntu:18.04

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
  npm \
  nodejs \
  yarn \
      && \
    rm -rf /var/lib/apt/lists/*

# Install VSCode
RUN curl -fsSL https://code-server.dev/install.sh | sh
COPY ./vscode_config.yaml /root/.config/code-server/config.yaml

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
EXPOSE 80
CMD ["code-server"]

