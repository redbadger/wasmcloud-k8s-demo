#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"/..

wash ctl get hosts | grep --only-matching N'[^ ]*' | xargs -n1 wash ctl get inventory -o json | jq
