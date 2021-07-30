#!/bin/bash
set -euo pipefail

# Setup NATS Cluster
kubectl apply -k ../kubernetes/nats-cluster; sleep 30

# Deploy application specific resources
kubectl apply -k ../kubernetes; sleep 15

# Port forward to the nats cluster
kubectl port-forward nats-cluster-1 4222:4222&

# Attach the necessary links
../links.sh

# Clean up and kill the port forwarding
kill "$(lsof -t -i:4222)"