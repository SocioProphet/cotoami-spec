#!/bin/bash

if [ -n "$DOCKER_HOST" ]; then
  DOCKER_HOST_IP=$(echo $DOCKER_HOST | sed 's/^.*\/\/\(.*\):[0-9][0-9]*$/\1/g')
else
  DOCKER_HOST_IP="127.0.0.1"
fi


# Cotoami
export COMPOSE_PROJECT_NAME=cotoami
export COTOAMI_VERSION="v0.23.0"
export COTOAMI_HOST=$DOCKER_HOST_IP

wget -q https://raw.githubusercontent.com/cotoami/cotoami/$COTOAMI_VERSION/launch/docker-compose.yml -O docker-compose.yml

docker-compose up -d


# Selenium Server
echo
echo "# Running selenium server..."
export CID_SELENIUM=$(docker run -d \
  -p 4444:4444 \
  --name selenium-server \
  --shm-size=2g \
  selenium/standalone-chrome:latest)
echo "  waiting for selenium server to be launched..."
while ! nc -z $DOCKER_HOST_IP 4444; do
  sleep 1s
done


# Run specs
stack --docker test


# Make sure to tear down the backend containers
function tear_down_containers() {
  echo
  echo "# Tearing down containers..."
  docker stop $CID_SELENIUM && docker rm $CID_SELENIUM
  docker-compose down -v
}
trap tear_down_containers 0 1 2 3 15
