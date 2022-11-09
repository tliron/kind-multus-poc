#!/bin/bash
set -e

HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")

function apply_demo () {
	local NUM=$1
	kubectl delete --filename="$HERE/demo$NUM.yaml" || true
	kubectl apply --filename="$HERE/demo$NUM.yaml"
}

function node_ip () {
	kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
}

"$HERE/use.sh" 1
NODE1=$(node_ip)
"$HERE/use.sh" 2
NODE2=$(node_ip)

"$HERE/exec.sh" 1 ip route add 10.1.2.0/24 via $NODE2 || true
"$HERE/exec.sh" 2 ip route add 10.1.1.0/24 via $NODE1 || true

"$HERE/use.sh" 1
apply_demo 1
"$HERE/use.sh" 2
apply_demo 2

