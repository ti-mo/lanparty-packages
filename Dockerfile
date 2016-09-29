# Dockerfile
FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /root

RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
COPY config/apt-preferences /etc/apt/preferences

# Make sure to run apt-get update before trying to install a dependency in
# the container. This is required when /var/lib/apt/lists is empty.
RUN apt-get update \
 && apt-get -t jessie-backports install -y \
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
    golang-go \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "gem: --no-ri --no-rdoc" > /etc/gemrc

COPY config/Gemfile /root/Gemfile
RUN bundle install
RUN gem specific_install https://github.com/ti-mo/fpm-cookery.git
