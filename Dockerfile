# Dockerfile
FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

RUN apt-get update && apt-get -t jessie-backports install -y \
    build-essential \
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
    ruby-dev \
    rubygems \
    wget \
    golang-go \
    && apt-get clean

RUN echo "gem: --no-ri --no-rdoc" > /etc/gemrc
RUN gem install fpm -v 1.6.2
RUN gem install fpm-cookery -v 0.32.0
RUN gem install buildtasks -v 0.0.2
RUN gem install bundler -v 1.12.5
