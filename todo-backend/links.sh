#!/bin/bash

set -euo pipefail

# wash ctl returns success even if it can't connect to anything, so we guard against it up here.
until nats pub devnull somenoise; do
    echo
    echo "Could not connect to nats cluster. Please run the following in another terminal:"
    echo "kubectl port-forward -n nats-cluster nats-cluster-1 4222:4222"
    echo
    sleep 10
done

ACTOR_KEY=MBBMA4XIXSYIMSBJDVGNS43WBZ76ZX2DMFBOXY773SEQBPFP2OR4ODHT
PROVIDER_HTTP=VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4AYJ5RKAX2UNSCAPHA5M
PROVIDER_KEY_VALUE=VARKLFUT2KURNFQ36TPNLYSYDKSAI73FC6NYIQJVHCQ4ANJOS56BHMZ2

wash ctl link put $ACTOR_KEY $PROVIDER_HTTP wasmcloud:httpserver PORT=8082
wash ctl link put $ACTOR_KEY $PROVIDER_KEY_VALUE wasmcloud:keyvalue URL=redis://redis-service.todo:6379/
