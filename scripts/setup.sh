#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"/..

# TODO: split this out into a Makefile?

function wait_for_kubernetes() {
    kubectl wait --for=condition=available --timeout=60s --all deployments
}

gcloud container clusters get-credentials wasmcloud --zone europe-west2

# # It's sad that this will not get a pinned version of istio, but it's the easiest way to get going
# command -v istioctl || curl -sL https://istio.io/downloadIstioctl | sh -
# export PATH=$PATH:$HOME/.istioctl/bin
# istioctl operator init

# until kubectl wait --for=condition=ready pod -l name=istio-operator -n istio-operator --timeout=480s; do
#     echo "Waiting for istio operator"
#     sleep 10
# done

# kubectl apply -k kubernetes/00-istio/
# wait_for_kubernetes

kubectl apply -k kubernetes/01-nats-prereqs
kubectl apply -k kubernetes/10-nats-operator
kubectl apply -k kubernetes/20-nats-cluster
kubectl wait --for=condition=ready -n nats-cluster pod/nats-cluster-1

# Deploy application specific resources
kubectl apply -k kubernetes/50-todo-backend

# Waiting for actors and capabilities to be running, removing this sleep can cause panic
sleep 15

# Port forward to the nats cluster
# TODO: work out how to make `concurrently` set a successful exit code.
pnpx -y concurrently --kill-others "kubectl port-forward -n nats-cluster nats-cluster-1 4222:4222" "todo-backend/links.sh" || true
