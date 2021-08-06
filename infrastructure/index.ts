import * as gke from "./gke";
import * as eks from "./eks";

const CLUSTER_NAME = "wasmcloud";

export const gkeCluster = new gke.GkeCluster(CLUSTER_NAME, {});
export const eksCluster = new eks.EksCluster(CLUSTER_NAME, {});
