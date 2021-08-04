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

if [ "${1:-x}" == "eks" ]; then
    aws eks --region eu-west-2 update-kubeconfig --name wasmcloud
    # apply nginx controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/aws/deploy.yaml
elif [ "${1:-x}" == "gke" ]; then
    gcloud container clusters get-credentials wasmcloud --zone europe-west2
    # apply nginx controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/cloud/deploy.yaml
else
    echo "Usage: setup.sh gke | eks"
    exit 1
fi

command -v helm || brew install helm
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update

# Get this from David (TODO: switch to some other way of providing this)
kubectl apply -f super-secret-secret.yml
# helm is not idempotent, so let's create a manifest and apply it instead
helm template nats nats/nats -f nats.yaml --namespace=nats >kubernetes/20-nats/helm-template.yml
kubectl apply -k kubernetes/20-nats
wait_for_pods -n nats -l app.kubernetes.io/name=nats
wait_for_deployments

# Deploy application specific resources
kubectl apply -k kubernetes/50-todo-backend
wait_for_deployments

# Waiting for actors and capabilities to be running, removing this sleep can cause panic
sleep 15

# Port forward to the nats cluster
# TODO: work out how to make `concurrently` set a successful exit code.
pnpx -y concurrently --kill-others "kubectl port-forward -n nats service/nats 4222:4222" "todo-backend/links.sh" || true
