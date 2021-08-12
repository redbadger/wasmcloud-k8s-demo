#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"/..

CLUSTER="${1:-x}"

if [ "$CLUSTER" == "aws" ]; then
    aws eks --region eu-west-2 update-kubeconfig --name wasmcloud
    kubectx aws=. || true
elif [ "$CLUSTER" == "gcp" ]; then
    gcloud container clusters get-credentials wasmcloud --zone europe-west2
    kubectx gcp=. || true
else
    echo "Usage: setup.sh gcp | aws"
    exit 1
fi

ls -d1 kubernetes/* | sort --reverse | while read dir; do
    kubectl delete -k $dir || echo "$dir failed to delete. Maybe you deleted it already?"
done
