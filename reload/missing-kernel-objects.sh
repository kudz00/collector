#!/bin/bash
set -e
# Usage: ./missing-kernel-objects.sh stackrox/collector:1.6.0-317-g903fb094c8

# This script is takes a collector image and prints a list of kernel modules and ebpf probes
# that are availibible in COLLECTOR_MODULES_BUCKET on GCP but that are not contained in the image.
# The list is printed in the form {module_version}/{kernel-object-name}.gz


if [[ $# -eq 0 ]] ; then
  echo "missing image name"
  exit 1
fi

if [[ -z "${COLLECTOR_MODULES_BUCKET}" ]] ; then
  echo "missing env var COLLECTOR_MODULES_BUCKET"
  exit 1
fi

image="$1"
gcp_bucket="${COLLECTOR_MODULES_BUCKET}"

dir="$(mktemp -d)"
name="collector-$RANDOM"

docker create --name="${name}" "${image}" > /dev/null 2>&1
docker cp "${name}:/kernel-modules/" "$dir"

version="$(cat "$dir/kernel-modules/MODULE_VERSION.txt")"

# determine which kernel module and probes are missing from this image
comm -1 -3 \
   <( find "${dir}/kernel-modules/" -name "*.gz" | awk -F '/' -v version="$version" '{print version "/" $NF}' | sort ) \
   <( gsutil ls "${gcp_bucket}/${version}" | grep ".*.gz$" | awk -F '/' '{print $(NF-1) "/" $NF}' | sort )

rm -rf "$dir"
docker rm -fv "${name}" > /dev/null 2>&1
