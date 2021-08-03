import * as eks from "@pulumi/eks";
import * as pulumi from "@pulumi/pulumi";

export class EksCluster extends pulumi.ComponentResource {
  public clusterName: pulumi.Output<string>;
  public kubeconfig: pulumi.Output<any>;

  constructor(name: string, opts: pulumi.ComponentResourceOptions = {}) {
    super("wasmcloud:EksCluster", name, {}, opts);

    const cluster = new eks.Cluster(name, {
      name,
    });
    this.clusterName = cluster.eksCluster.name;

    this.kubeconfig = cluster.kubeconfig;
  }
}
