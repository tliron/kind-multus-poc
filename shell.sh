#!/bin/bash
set -e

HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")

"$HERE/use.sh" $1
kubectl exec -it deploy/demo$2 -n nephio -- sh

