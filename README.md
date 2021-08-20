# wasmcloud k8s demo

This repo contains our investigation into the developer experience of using wasmcloud in a multi-cloud kubernetes environment. We are hoping to explore:

- wasmcloud lattice across multiple cloud providers (GCP+AWS), via NGS
- GitOps
- Ingress
- kv store with redis (only in GCP)
- moving actors between clouds
- chaos testing
- ...

We have chosen to go with krustlet + wasmcloud 0.18, because it is more aligned with the GitOps philosophy of idempotently applying desired configurations. We are expecting wasmcloud 0.20 to be released towards the end of our project, but krustlet compatibility is expected to lag behind.

## Setup

### Infrastructure

We are using pulumi for our infrastructure-as-code setup. If you get lost, it might be because we forgot to write down a step. If you manage to unblock yourself by reading https://www.pulumi.com/docs/get-started/ , please send us a pull request.

To set things up:

- Ask for the .env from someone on the red-badger slack. Specifically, you will want to export PULUMI_CONFIG_PASSPHRASE into your environment (this is used to decrypt the pulumi state, which is shared in a google storage bucket).
- Ask for User credentials for NGS and the internal nats cluster. These live at `kubernetes/20-nats/nats-secrets.yml` and
  `kubernetes/50-todo-backend/base/nats-sidecar-secret.yml`.
  - If you want to reproduce this demo on your own, you can create a new ngs account to put in nats-secrets.yml, and make a new Operator + Account + User on your computer. You will need to regenerate `kubernetes/20-nats/operator-jwt.yml` and `kubernetes/20-nats/nats-accounts.yml`

#### Log into aws if you aren't already

Follow the steps from https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/obtain-credentials.html to get your credentials as a csv, and then run:

```bash
aws configure
```

and paste in the appropriate values.

```bash
gcloud auth login
gcloud config set project wasmcloud-k8s-demo
gcloud auth application-default login
```

Check that you don't have a `GOOGLE_CREDENTIALS` environment variable exported from a previous project 🙈.

#### Run pulumi

`pulumi login --cloud-url gs://pulumi-state-bucket`

`pulumi up` contains a confirmation step, so you don't need to worry about accidentally stomping over other people's work.

```bash
(cd infrastructure/ && npm install && pulumi up --stack dev)
```

The user who does this step becomes god on the eks cluster automatically. As a work-around,

```
kubectl edit configmap aws-auth -n kube-system
```

```
mapUsers: |
    - userarn: arn:aws:iam::394465323128:user/david.laban
    username: david.laban
    groups:
        - system:masters
```

#### Set up kubernetes

All setup operations live in ./scripts/setup.sh. This takes an argument `eks` or `gke`, and sets up the appropriate cluster + link definitions.

## Testing

```
kubectl port-forward -n todo-backend service/todo-http-capability-service 8082:8082
```

```
curl localhost:8082/api
```

This should return the empty array `[]`, or whatever todo items people have added.

## Debugging nats

In order to connect directly to the nats cluster from your local machine, you will need to trust the cluster's CA certificate.

You will also need to forward ports in such a way that the nats cluster is available on the domain name `nats.nats`. You can either edit /etc/hosts manually, or use kubefwd to achieve this.

```bash
kubectl get secrets -n todo bogus-cert -o json | jq '.data["ca.crt"]' -r | base64 -D > ca.crt
sudo kubefwd svc -n nats nats
nats --tlsca=ca.crt --server=nats.nats --creds ~/.nkeys/creds/synadia/leaftest/wasmcloud-project.creds pub asdf adsf
```

Alternatively, if you are happy connecting to a sidecar, you can do what setup.sh does

```bash
pod=$(kubectl get pods -n todo --selector="tier=web" -o name)
kubectl port-forward -n todo $pod 4222:4222
nats pub asdf adsf
```

## Developing

### Pushing an actor image

Found some inconsistency when pushing and pulling images to and from GCR when using wash cli, we resorted to using `wasm-to-oci`. The inconsistency lied with the media types supported for the images. Had to change the supported media types within `wasm-to-oci` as shown below.

wash doesn't understand how to talk to gcr.io, and we're not in the mood for debugging it right now. As a work-around, we applied this patch to https://github.com/engineerd/wasm-to-oci :

```
diff --git a/pkg/oci/mediatypes.go b/pkg/oci/mediatypes.go
index 5c99816..ffaa489 100644
--- a/pkg/oci/mediatypes.go
+++ b/pkg/oci/mediatypes.go
@@ -2,5 +2,5 @@ package oci

 const (
        ConfigMediaType       = "application/vnd.wasm.config.v1+json"
-       ContentLayerMediaType = "application/vnd.wasm.content.layer.v1+wasm"
+       ContentLayerMediaType = "application/vnd.module.wasm.content.layer.v1+wasm"
 )
```

and push a new image like this `wasm-to-oci push todo-backend/target/wasm32-unknown-unknown/debug/todo_backend_s.wasm eu.gcr.io/wasmcloud-k8s-demo/todo-backend:0.2`

We made our registry public, to simplify our lives.
