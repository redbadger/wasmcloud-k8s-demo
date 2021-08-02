#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"/..

# TODO: split this out into a Makefile?

function wait_for_deployments() {
    kubectl wait --for=condition=available --timeout=60s --all-namespaces --all deployments
}

function wait_for_pods() {
    until kubectl wait --for=condition=ready --timeout=480s pod "$@"; do
        echo "Waiting for $@"
        sleep 10
    done
}

gcloud container clusters get-credentials wasmcloud --zone europe-west2

# It's sad that this will not get a pinned version of istio, but it's the easiest way to get going
command -v istioctl || curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl operator init

wait_for_pods -n istio-operator -l name=istio-operator

kubectl apply -k kubernetes/00-istio/
wait_for_deployments

kubectl apply -k kubernetes/01-nats-prereqs
kubectl apply -k kubernetes/10-nats-operator
kubectl apply -k kubernetes/20-nats-cluster
wait_for_pods -n nats-cluster -l app=nats
wait_for_deployments

# Deploy application specific resources
kubectl apply -k kubernetes/50-todo-backend
wait_for_deployments

# Waiting for actors and capabilities to be running, removing this sleep can cause panic
sleep 15

# Port forward to the nats cluster
# TODO: work out how to make `concurrently` set a successful exit code.
pnpx -y concurrently --kill-others "kubectl port-forward -n nats-cluster nats-cluster-1 4222:4222" "todo-backend/links.sh" || true
