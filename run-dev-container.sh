#!/bin/bash

if [ -z $1 ]; then
  echo "lanparty-packages - Run Docker development environment"
  echo ""
  echo "  :: This script runs a container with the current directory mounted in /build."
  echo "  :: Also, port 80 is exposed on the host."
  echo "  :: Make sure to run 'docker-compose build' first; the second argument is the"
  echo "  :: tag of the lanparty-packages image to run (eg. kernel or base)"
  echo ""
  echo "Usage: $0 dev-container-name [image-tag]"
  echo ""
  exit 1
fi

tag=$2

if [ -z $tag ]; then
  tag='base'
fi

dstatus=$(docker ps -a --format "{{.Names}} {{.Status}}")

if echo "$dstatus" | grep -q "^$1[[:space:]]"; then
  if echo "$dstatus" | grep "^$1[[:space:]]" | grep -q "Up"; then
    echo "Container $1 exists and is already running, exiting."
  else
    echo "Container $1 exists, starting.."

    docker start -i "$1"

    echo "Stopped container $1. Re-run script to resume."

  fi

else
  echo "Container $1 not found, creating from image tag $tag.."

  docker run -ti --name "$1" -v `pwd`:/build -p 80:80 lanparty-packages:$tag

  echo "Stopped container $1. Re-run script to resume."

fi
