#!/bin/bash
set -euxo pipefail

# start nats — nast-server -js
# start wasmcloud host — docker run --rm -p8081:8081 -e WASMCLOUD_PROV_RPC_HOST=host.docker.internal -e OCI_REGISTRY_USER=wasmcloudk8sdemo -e OCI_REGISTRY_PASSWORD=<pwd> -e WASMCLOUD_RPC_HOST=host.docker.internal -e WASMCLOUD_CTL_HOST=host.docker.internal eu.gcr.io/wasmcloud-k8s-demo/wasmcloud_host:0.50.0
# start redis locally — `redis-server`

wash ctl start provider wasmcloudk8sdemo.azurecr.io/wasmcloud-k8s-demo/kvredis:0.14.0-beta --timeout 10

wash ctl start actor wasmcloudk8sdemo.azurecr.io/wasmcloud-k8s-demo/todo:0.1.2 --timeout 10

wash ctl start provider wasmcloud.azurecr.io/httpserver:0.13.1 --timeout 10

wash ctl link put \
	MAGRQW4WRCLAWZ3I3EVKLPSHGLT3V3NDJUXMUDWFMN5WZ7MK3S5LQ36R \
	VARKLFUT2KURNFQ36TPNLYSYDKSAI73FC6NYIQJVHCQ4ANJOS56BHMZ2 \
	wasmcloud:keyvalue \
	URL=redis://host.docker.internal:6379 \
	--timeout 10

wash ctl link put \
	MAGRQW4WRCLAWZ3I3EVKLPSHGLT3V3NDJUXMUDWFMN5WZ7MK3S5LQ36R \
	VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4AYJ5RKAX2UNSCAPHA5M \
	wasmcloud:httpserver \
	PORT=8081 \
	--timeout 10
