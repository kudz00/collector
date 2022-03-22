#!/usr/bin/env bash
set -eou pipefail

name=$1

echo "Waiting for infra cluster to be ready"

while true; do
    ready="$({ infractl get "$name" | awk '{if ($1 == "Status:" && $2 == "READY") print}' || true; } | wc -l)"
    if ((ready == 1)); then
        break
    fi
done
