#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"/..

ls -d1 kubernetes/* | sort --reverse | xargs -n1 kubectl delete -k
