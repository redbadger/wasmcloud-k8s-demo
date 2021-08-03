#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"/..

# TODO: split this out into a Makefile?

function wait_for_deployments() {
    kubectl wait --for=condition=available --timeout=60s --all-namespaces --all deployments
}

function wait_for_pods() {
    until kubectl wait --for=condition=ready --timeout=480s pod "$@"; do
        echo "Waiting for $*"
        sleep 10
    done
}

if [ "$1" == "eks" ]; then
    aws eks --region eu-west-2 update-kubeconfig --name wasmcloud
elif [ "$1" == "gke" ]; then
    gcloud container clusters get-credentials wasmcloud --zone europe-west2
else 
    echo "Usage: setup.sh gke | eks"
    exit 1
fi

kubectl apply -k kubernetes/01-nats-prereqs
kubectl apply -k kubernetes/10-nats-operator
until kubectl apply -k kubernetes/20-nats-cluster; do
    # Workaround for: `unable to recognize "kubernetes/20-nats-cluster": no matches for kind "NatsCluster" in version "nats.io/v1alpha2"``
    # TODO: find a way to wait for the nats operator to install the NatsCluster crd
    sleep 10
done
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
