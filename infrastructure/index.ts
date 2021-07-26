import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

const CLUSTER_NAME = "wasmcloud";

const engineVersion = gcp.container
  .getEngineVersions()
  .then((v) => v.latestMasterVersion);

const cluster = new gcp.container.Cluster(CLUSTER_NAME, {
  initialNodeCount: 2,
  minMasterVersion: engineVersion,
  nodeVersion: engineVersion,
  nodeConfig: {
    machineType: "n1-standard-1",
    oauthScopes: [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ],
  },
});

export const clusterName = cluster.name;
