#!/usr/bin/env zx

const start = async (type, ref, host) => {
  return $`wash ctl start ${type} ${ref} --host-id ${host} --timeout 10`;
};

const applyLinks = async () => {
  const ACTOR_KEY = "MAGRQW4WRCLAWZ3I3EVKLPSHGLT3V3NDJUXMUDWFMN5WZ7MK3S5LQ36R";
  const PROVIDER_HTTP =
    "VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4AYJ5RKAX2UNSCAPHA5M";
  const PROVIDER_KEY_VALUE =
    "VARKLFUT2KURNFQ36TPNLYSYDKSAI73FC6NYIQJVHCQ4ANJOS56BHMZ2";

  await $`wash ctl link put ${ACTOR_KEY} ${PROVIDER_HTTP} wasmcloud:httpserver PORT=8082 --timeout 10`;
  await $`wash ctl link put ${ACTOR_KEY} ${PROVIDER_KEY_VALUE} wasmcloud:keyvalue URL=redis://redis-service.todo:6379/ --timeout 10`;
};

const waitForNats = async () => {
  while ((await $`nats pub devnull somenoise`.exitCode) != 0) {
    console.log(
      "Could not connect to nats cluster. Please run the following in another terminal:"
    );
    console.log(
      "kubectl port-forward -n nats-cluster nats-cluster-1 4222:4222"
    );

    await sleep(10_000);
  }
};

void (async function () {
  try {
    await waitForNats();
    
    let { hosts } = JSON.parse(await $`wash ctl get hosts -o json`);

    for (let host of hosts) {
      const {
        inventory: { actors, providers, labels },
      } = JSON.parse(await $`wash ctl get inventory ${host.id} -o json`);

      if (actors.length === 0 && labels.intention === "actor") {
        await start(
          "actor",
          "wasmcloudk8sdemo.azurecr.io/wasmcloud-k8s-demo/todo:0.1.2",
          host.id
        );
      }

      if (providers.length === 0 && labels.intention === "http") {
        await start(
          "provider",
          "wasmcloud.azurecr.io/httpserver:0.13.1",
          host.id
        );
      }

      if (providers.length === 0 && labels.intention === "redis") {
        await start(
          "provider",
          "wasmcloudk8sdemo.azurecr.io/wasmcloud-k8s-demo/kvredis:0.14.0-beta",
          host.id
        );
      }
    }

    await applyLinks();
  } catch (error) {
    console.log(error);
  }
})();
