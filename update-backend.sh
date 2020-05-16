#!/bin/bash

alias docker-compose="'"'docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.25.5'"'"

sudo sh -c "docker-compose pull backend"
sudo sh -c "docker-compose up -d backend"
