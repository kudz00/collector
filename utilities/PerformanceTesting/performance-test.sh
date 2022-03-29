#!/usr/bin/env bash
set -eoux pipefail

cluster_name=$1
test_dir=$2
load_test_name=$3
num_streams=$4
collector_versions_file=${5:-collector_versions.txt}
teardown_script=${6:-$TEARDOWN_SCRIPT}
nrepeat=${7:-5}
sleep_after_start_stack_rox=${8:-60}
load_duration=${9:-600}
query_window=${10:-10m}
artifacts_dir=${11:-/tmp/artifacts}

DIR="$(cd "$(dirname "$0")" && pwd)"

"$DIR"/create-infra.sh "$cluster_name" openshift-4 7h
"$DIR"/wait-for-cluster.sh "$cluster_name"
"$DIR"/get-artifacts-dir.sh "$cluster_name" "$artifacts_dir"
export KUBECONFIG="$artifacts_dir"/kubeconfig
if ((num_streams > 0)); then
    knb_base_dir="$(mktemp -d)"
    "$DIR/initialize-kubenetbench.sh" "$artifacts_dir" "$load_test_name" "$knb_base_dir"
fi

mkdir -p "$test_dir"

for ((n = 0; n < nrepeat; n = n + 1)); do
    while read -r line; do
        collector_image_registry="$(echo "$line" | awk '{print $1}')"
        collector_image_tag="$(echo "$line" | awk '{print $2}')"
        nick_name="$(echo "$line" | awk '{print $3}')"
        printf 'yes\n'  | $teardown_script
        "$DIR"/start-stack-rox.sh "$cluster_name" "$artifacts_dir" "$collector_image_registry" "$collector_image_tag"
        sleep "$sleep_after_start_stack_rox"
        if ((num_streams > 0)); then
            "$DIR/generate-load.sh" "$artifacts_dir" "$load_test_name" "$num_streams" "$knb_base_dir" "$load_duration"
        fi
        "$DIR"/query.sh "$artifacts_dir" "$query_window" > "$test_dir/results_${nick_name}_${n}.txt"
    done < "$collector_versions_file"
done

printf 'yes\n'  | $teardown_script

if ((num_streams > 0)); then
    "$DIR/teardown-kubenetbench.sh" "$artifacts_dir" "$knb_base_dir"
fi

while read -r line; do
    nick_name="$(echo "$line" | awk '{print $3}')"
    python3 "$DIR"/GetAverages.py --filePrefix "${test_dir}/results_${nick_name}_" --numFiles "$nrepeat" --outputFile "${test_dir}/Average_results_${nick_name}.txt"
done < "$collector_versions_file"
