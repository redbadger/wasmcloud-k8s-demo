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
(cd infrastructure/ && npm install && pulumi up --stack wasmcloud-state-dev)
```
