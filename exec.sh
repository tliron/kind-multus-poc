#!/bin/bash
set -e

podman exec -it edge$1-control-plane "${@:2}"
