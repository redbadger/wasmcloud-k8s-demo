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

- Ask for the .env from someone on the red-badger slack. Specifically, you will want to export PULUMI_CONFIG_PASSPHRASE into your environment (this is used to decrypt the pulumi state, which is shared in an aws s3 bucket).

#### Log into aws if you aren't already

https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/obtain-credentials.html

```bash
aws configure
```

```bash
gcloud auth login
gcloud config set project wasmcloud-k8s-demo
gcloud auth application-default login
```

Check that you don't have a `GOOGLE_CREDENTIALS` environment variable exported from a previous project 🙈.

#### Run pulumi

`pulumi up` contains a confirmation step, so you don't need to worry about accidentally stomping over other people's work.

```bash
(cd infrastructure/ && npm install && pulumi up --stack dev)
```

#### Set up kubernetes

#### Authenticate with the cluster
Log in:

```bash
gcloud container clusters get-credentials wasmcloud --zone europe-west2
```
#### Setup NATS operator
Install nats operator following [their docs](https://github.com/nats-io/nats-operator).

```
kubectl apply -f https://raw.githubusercontent.com/nats-io/nats-operator/master/deploy/00-prereqs.yaml
kubectl apply -f https://raw.githubusercontent.com/nats-io/nats-operator/master/deploy/10-deployment.yaml
```

There is a whole bunch more that could be done, but a simple nats cluster will do for now. We will add an NGS bridge later.

#### Broadcasting wasmcloud links
* Port forward to the cluster, using
```
kubectl port-forward nats-cluster-1 4222:4222
```
* Run [`./links.sh`](./todo-backend/links.sh)

#### Apply all the k8s manifests
```
kubectl apply -f todo-backend/kubernentes/<manifest>.yml
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
