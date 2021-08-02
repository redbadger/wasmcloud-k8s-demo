#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"/..

ls -d1 kubernetes/* | sort --reverse | while read dir; do
    kubectl delete -k $dir || echo "$dir failed to delete. Maybe you deleted it already?"
done
