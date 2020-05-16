#!/bin/bash

alias docker-compose=docker run -it --rm \
	-v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:$PWD" -w="$PWD" \
	docker/compose:1.25.5

sudo docker-compose pull frontend
sudo docker-compose up -d frontend
