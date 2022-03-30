#!/usr/bin/env bash
set -eo pipefail

echo "ls 1"
for i in "${WORKSPACE_ROOT}"/*perf.json; do
    echo "Performance data file: $i"
    cat "$i" >> "${WORKSPACE_ROOT}"/all-perf.json
done

## TODO put into script
#jq '. | select(.Metrics.hackbench_avg_time != null) | {kernel: .VmConfig, collection_method: .CollectionMethod, (.TestName): .Metrics.hackbench_avg_time } ' < all-perf.json | jq -rs  ' group_by(.kernel) | .[] | group_by(.collection_method) | .[] | add | [.kernel, .collection_method, .baseline_benchmark, .collector_benchmark ] | @csv' > "${WORKSPACE_ROOT}/benchmark.csv"

# I could not come up with a better variable name than temp
temp=$(jq '. | select(.Metrics.hackbench_avg_time != null) | {kernel: .VmConfig, collection_method: .CollectionMethod, (.TestName): .Metrics.hackbench_avg_time } ' < "${WORKSPACE_ROOT}"/all-perf.json)
temp=$(echo "$temp" | jq -rs  ' group_by(.kernel) | .[] | group_by(.collection_method) | .[] ')
echo "$temp" | jq -r ' add | [.kernel, .collection_method, .baseline_benchmark, .collector_benchmark ] | @csv' > "${WORKSPACE_ROOT}/benchmark.csv"

##cat "${WORKSPACE_ROOT}/benchmark.csv" | sort | awk -v FS="," 'BEGIN{print "|Kernel|Method|Without Collector Time (secs)|With Collector Time (secs)|";print "|---|---|---|---|"}{printf "|%s|%s|%s|%s|%s",$1,$2,$3,$4,ORS}' > "${WORKSPACE_ROOT}/benchmark.md"
#

echo "|Kernel|Method|Without Collector Time (secs)|With Collector Time (secs)|" > "${WORKSPACE_ROOT}/benchmark.md"
echo "|---|---|---|---|" >> "${WORKSPACE_ROOT}/benchmark.md"
sort "${WORKSPACE_ROOT}/benchmark.csv" | awk -v FS="," '{printf "|%s|%s|%s|%s|%s",$1,$2,$3,$4,ORS}' >> "${WORKSPACE_ROOT}/benchmark.md"
