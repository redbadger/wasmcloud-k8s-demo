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

ACTOR_KEY=MD3MZVXGR36UBZOH2R5ES4KY57ZVMDSLTFGKDTIY2DM6EODVD5HTIVOI
PROVIDER_HTTP=VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4AYJ5RKAX2UNSCAPHA5M
PROVIDER_LOGGING=VCCANMDC7KONJK435W6T7JFEEL7S3ZG6GUZMZ3FHTBZ32OZHJQR5MJWZ
PROVIDER_KEY_VALUE=VAZVC4RX54J2NVCMCW7BPCAHGGG5XZXDBXFUMDUXGESTMQEJLC3YVZWB

wash ctl link $ACTOR_KEY $PROVIDER_HTTP wasmcloud:httpserver PORT=8082
wash ctl link $ACTOR_KEY $PROVIDER_LOGGING wasmcloud:logging
wash ctl link $ACTOR_KEY $PROVIDER_KEY_VALUE wasmcloud:keyvalue URL=redis://redis-service.todo-backend:6379/
