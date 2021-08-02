#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"/..

gcloud container clusters get-credentials wasmcloud --zone europe-west2

# It's sad that this will not get a pinned version of istio, but it's the easiest way to get going
command -v istioctl || curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl operator init

until kubectl wait --for=condition=ready pod -l name=istio-operator -n istio-operator --timeout=480s; do
    echo "Waiting for istio operator"
    sleep 10
done

kubectl apply -f https://raw.githubusercontent.com/nats-io/nats-operator/master/deploy/00-prereqs.yaml
kubectl wait --for=condition=available --timeout=60s --all deployments

# Setup NATS Cluster
kubectl apply -k kubernetes/nats-cluster
kubectl wait --for=condition=available --timeout=60s --all deployments

# Deploy application specific resources
kubectl apply -k kubernetes/todo-backend

# Waiting for actors and capabilities to be running, removing this sleep can cause panic
sleep 15

# Port forward to the nats cluster
# TODO: work out how to make `concurrently` set a successful exit code.
pnpx -y concurrently --kill-others "kubectl port-forward nats-cluster-1 4222:4222" "todo-backend/links.sh" || exit 0
