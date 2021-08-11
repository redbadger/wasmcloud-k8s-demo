import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

export class GkeCluster extends pulumi.ComponentResource {
  public clusterName: pulumi.Output<string>;
  public provider: k8s.Provider;
  // public staticIp: pulumi.Output<string>;

  constructor(name: string, opts: pulumi.ComponentResourceOptions = {}) {
    super("wasmcloud:GkeCluster", name, {}, opts);

    // TODO: this needs to have a region, but also needs to be publicly routable
    // The gcloud invocation for this is `gcloud compute addresses create wasmcloud-ip-2 --region europe-west2`
    // (both of them exist in https://console.cloud.google.com/networking/addresses/list?project=wasmcloud-k8s-demo)
    // but what is the way to specify this in pulumi?
    // const ipAddress = new gcp.compute.GlobalAddress("wasmcloud-ip", {
    //   name: "wasmcloud-ip",
    // });

    // this.staticIp = ipAddress.address;

    const engineVersion = gcp.container
      .getEngineVersions()
      .then((v) => v.latestMasterVersion);

    const cluster = new gcp.container.Cluster(name, {
      name: name,
      initialNodeCount: 1,
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

    this.clusterName = cluster.name;

    // Manufacture a GKE-style kubeconfig. Note that this is slightly "different"
    // because of the way GKE requires gcloud to be in the picture for cluster
    // authentication (rather than using the client cert/key directly).
    const kubeconfig = pulumi
      .all([cluster.name, cluster.endpoint, cluster.masterAuth])
      .apply(([name, endpoint, masterAuth]) => {
        const context = `${gcp.config.project}_${gcp.config.zone}_${name}`;
        return `apiVersion: v1
clusters:
- cluster:
  certificate-authority-data: ${masterAuth.clusterCaCertificate}
  server: https://${endpoint}
name: ${context}
contexts:
- context:
  cluster: ${context}
  user: ${context}
name: ${context}
current-context: ${context}
kind: Config
preferences: {}
users:
- name: ${context}
user:
  auth-provider:
    config:
      cmd-args: config config-helper --format=json
      cmd-path: gcloud
      expiry-key: '{.credential.token_expiry}'
      token-key: '{.credential.access_token}'
    name: gcp
`;
      });

    this.provider = new k8s.Provider(name, {
      kubeconfig,
    });
  }
}
