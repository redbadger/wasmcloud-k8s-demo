import * as gke from "./gke";
import * as eks from "./eks";

const CLUSTER_NAME = "wasmcloud";

const gkeCluster = new gke.GkeCluster(CLUSTER_NAME, {});
const eksCluster = new eks.EksCluster(CLUSTER_NAME, {});
