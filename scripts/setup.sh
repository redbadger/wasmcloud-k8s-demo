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

CLUSTER="${1:-x}"

if [ "$CLUSTER" == "aws" ]; then
    aws eks --region eu-west-2 update-kubeconfig --name wasmcloud
    kubectx aws=. || true
    # apply nginx controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/aws/deploy.yaml
elif [ "$CLUSTER" == "gcp" ]; then
    gcloud container clusters get-credentials wasmcloud --zone europe-west2
    kubectx gcp=. || true
    # apply nginx controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/cloud/deploy.yaml
else
    echo "Usage: setup.sh gcp | aws"
    exit 1
fi

# Get this from David (TODO: switch to some other way of providing this)
if [ ! -f kubernetes/20-nats/nats-secrets.yml ]; then
    echo "please get kubernetes/20-nats/nats-secrets.yml from David"
    exit 1
fi

# installing cert manager operator
if ! kubectl get namespace cert-manager; then
    kubectl create namespace cert-manager
    kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
fi

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.4.3/cert-manager.yaml
wait_for_deployments

# update helm and helm charts.
command -v helm || brew install helm
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update

# helm is not idempotent, so let's create a manifest and apply it instead
helm template nats nats/nats -f nats.yaml --namespace=nats >kubernetes/20-nats/helm-template.yml
# HACK: inject `account` public key id into the leafnodes remote config using sed
# (until  https://github.com/nats-io/k8s/pull/286 has been released,
# and we can put it into nats.yaml directly).
sed -i '' \
    's!^\( *\)\(url: tls://connect.ngs.global:7422\)$!\1account: AB7AGANA6KWTTBUD3AUIEZ47M3GWP2L5AMEVV6OE4IDIN3VFOD3P6TZ5\n\1\2!' \
    kubernetes/20-nats/helm-template.yml

kubectl apply -k kubernetes/20-nats
wait_for_pods -n nats -l app.kubernetes.io/name=nats
wait_for_deployments

if [ ${STOP:-100} -lt 50 ]; then
    exit 0
fi

# Deploy application specific resources
kubectl apply -k "kubernetes/50-todo-backend/$CLUSTER"
wait_for_deployments

# Waiting for actors and capabilities to be running, removing this sleep can cause panic
sleep 15

# Port forward to the nats cluster
pod=$(kubectl get pods -n todo --selector="tier=web" -o name)
pnpx -y concurrently --kill-others --success=first "kubectl port-forward -n todo $pod 4222:4222" "todo-backend/links.sh"

while true; do
    if [ "$CLUSTER" == "aws" ]; then
        hostname=$(kubectl -n todo get ingress ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    else
        hostname=$(kubectl -n todo get ingress ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi

    curl --fail "$hostname/api" | jq && break

    echo "waiting for ingress to work"
    sleep 10
done
