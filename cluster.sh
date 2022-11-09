#!/bin/bash
set -e

HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")

function delete_cluster () {
	local NUM=$1
	kind delete cluster --name=edge$NUM
}

function create_cluster () {
	local NUM=$1
	kind create cluster --config="$HERE/edge$NUM.yaml"

	# Deploy Multus
	"$HERE/use.sh" $NUM
	kubectl apply --filename="https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/v3.9.2/deployments/multus-daemonset-thick-plugin.yml"

	# Convenience/debugging utils
	"$HERE/exec.sh" $NUM apt update
	"$HERE/exec.sh" $NUM apt install iputils-ping
}

delete_cluster 1
delete_cluster 2

create_cluster 1
create_cluster 2

