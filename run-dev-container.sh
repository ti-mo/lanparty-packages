#!/bin/bash

if [ -z $1 ]; then
  echo "lanparty-packages - Run Docker development environment"
  echo ""
  echo "  :: This script runs a container with the current directory mounted in /build."
  echo "  :: Also, port 80 is exposed on the host."
  echo "  :: lanparty-packages:base is used as the image, make sure to run 'docker-compose build' first."
  echo ""
  echo "Usage: $0 <dev-container-name>"
  echo ""
  exit 1
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
  echo "Container $1 not found, creating.."

  docker run -ti --name "$1" -v `pwd`:/build -p 80:80 lanparty-packages:base

  echo "Stopped container $1. Re-run script to resume."

fi
