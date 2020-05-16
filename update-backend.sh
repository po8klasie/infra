#!/bin/bash

COMPOSE_CMD=(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:$PWD" "-w=\"$PWD\"" docker/compose:1.25.5)

"${COMPOSE_CMD[@]}" pull backend
"${COMPOSE_CMD[@]}" up -d backend
