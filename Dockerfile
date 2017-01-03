# Dockerfile
FROM debian:jessie

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /root

COPY config/apt-sources /etc/apt/sources.list
COPY config/apt-preferences /etc/apt/preferences

# Warning: running apt-get build-dep on some packages requires a debian-stable
# image. Even installing packages from backports could be too cutting-edge (php5)

# Make sure to run apt-get update before trying to install a dependency in
# the container. This is required when /var/lib/apt/lists is empty.
RUN apt-get update \
 && apt-get install -y \
    build-essential \
    bison \
    curl \
    devscripts \
    equivs \
    git-buildpackage \
    git \
    lsb-release \
    make \
    openssh-client \
    pristine-tar \
    rake \
    rsync \
    ruby \
    bundler \
    ruby-dev \
    rubygems \
    wget \
 && apt-get install -y -t jessie-backports \
    golang \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "gem: --no-ri --no-rdoc" > /etc/gemrc

COPY config/Gemfile /root/Gemfile
RUN bundle install
RUN gem specific_install https://github.com/ti-mo/fpm-cookery.git
