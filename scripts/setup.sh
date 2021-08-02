#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f https://raw.githubusercontent.com/nats-io/nats-operator/master/deploy/00-prereqs.yaml
kubectl wait --for=condition=available --timeout=60s --all deployments

# Setup NATS Cluster
kubectl apply -k ../kubernetes/nats-cluster
kubectl wait --for=condition=available --timeout=60s --all deployments

# Deploy application specific resources
kubectl apply -k ../kubernetes

# Waiting for actors and capabilities to be running, removing this sleep can cause panic
sleep 15

# Port forward to the nats cluster
pnpx -y concurrently --kill-others "kubectl port-forward nats-cluster-1 4222:4222" "../links.sh"
