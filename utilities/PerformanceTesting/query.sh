#!/usr/bin/env bash
set -eo pipefail 

do_prometheus_query() {
  query_expression="$1"

  curl -sk -H "Authorization: Bearer $token" \
       --data-urlencode "query=${query_expression}" \
       https://"$url"/api/v1/query
}

get_value_from_query_result() {
	query_result=$1

	echo "$query_result" | jq -r '(.data.result | .[].value | .[1])'
}

do_prometheus_query_and_get_value() {
  query_expression="$1"

  query_result=$(do_prometheus_query "$query_expression")
  get_value_from_query_result "$query_result"
}
  
get_reports_for_collector_timers() {
  echo ""
  echo "#################"
  echo ""
  echo "Report for collector timers"

  total_max_time=0
  total_avg_time=0
  for timer in net_scrape_update net_scrape_read net_write_message net_create_message
  do
    avg_time_query='avg by (job) (rox_collector_timers{type="'${timer}'_times_us_avg"})'
    max_time_query='max by (job) (rox_collector_timers{type="'${timer}'_times_us_avg"})'

    avg_time=$(do_prometheus_query_and_get_value "$avg_time_query")
    max_time=$(do_prometheus_query_and_get_value "$max_time_query")

    total_avg_time=$(echo "$total_avg_time+$avg_time" | bc)
    total_max_time=$(echo "$total_max_time+$max_time" | bc)

    echo ""
    echo "Average time taken by $timer (microseconds): $avg_time"
    echo "Maximum time taken by $timer in any pod (microseconds): $max_time"
    echo ""
  done
  
  echo "Total time taken by collector timers in worst case (Sum of max times in microseconds): $total_max_time"
  echo "Total average time taken by collector timers (microseconds): $total_avg_time"
  echo ""
  echo "#################"
  echo ""
}

get_reports_for_collector_counters() {
  echo ""
  echo "#################"
  echo ""
  echo "Report for collector counters"

  for counter in net_conn_deltas net_conn_updates net_conn_inactive
  do
    avg_query='avg by (job) (rox_collector_counters{type="'${counter}'"})'
    max_query='max by (job) (rox_collector_counters{type="'${counter}'"})'

    avg=$(do_prometheus_query_and_get_value "$avg_query")
    max=$(do_prometheus_query_and_get_value "$max_query")

    echo ""
    echo "Average of $counter over pods: $avg"
    echo "Maximum of $counter over pods: $max"
    echo ""

  done
  echo ""
  echo "#################"
  echo ""
}

get_reports_for_sensor_network_flow() {
  echo ""
  echo "#################"
  echo ""
  echo "Report for sensor network flow"

  for flow_type in incoming outgoing
  do
     for protocol in L4_PROTOCOL_TCP L4_PROTOCOL_UDP
     do
       avg_query='avg by (job) (rox_sensor_network_flow_total_per_node{Protocol="'${protocol}'",Type="'${flow_type}'"})'
       max_query='max by (job) (rox_sensor_network_flow_total_per_node{Protocol="'${protocol}'",Type="'${flow_type}'"})'

       avg=$(do_prometheus_query_and_get_value "$avg_query")
       max=$(do_prometheus_query_and_get_value "$max_query")

       echo ""
       echo "Average number of $flow_type $protocol network flows over pods: $avg"
       echo "Maximum number of $flow_type $protocol network flows over pods: $max"
       echo ""
     done
  done

  for metric in rox_sensor_network_flow_host_connections_added rox_sensor_network_flow_host_connections_removed rox_sensor_network_flow_external_flows
  do
    query=$metric
    rate_query='rate('$metric'[10m])'

    value=$(do_prometheus_query_and_get_value "$query")
    rate_value=$(do_prometheus_query_and_get_value "$rate_query")

    echo ""
    echo "$metric: $value"
    echo "Average $metric per second: $rate_value"
    echo ""
  done

  echo ""
  echo "#################"
  echo ""

}

get_reports_for_cpu_mem_and_network_usage() {
  echo ""
  echo "#################"
  echo "Report for cpu and memory usage"
  echo ""

  avg_cpu_query='avg by (job) (rate(container_cpu_usage_seconds_total{namespace="stackrox"}[10m]) * 100)'
  max_cpu_query='max by (job) (rate(container_cpu_usage_seconds_total{namespace="stackrox"}[10m]) * 100)'
  avg_mem_query='avg by (job) (container_memory_usage_bytes{namespace="stackrox"})'
  max_mem_query='max by (job) (container_memory_usage_bytes{namespace="stackrox"})'
  avg_network_receive_query='avg by (job) (rate(container_network_receive_bytes_total{namespace="stackrox"}[10m]))'
  max_network_receive_query='max by (job) (rate(container_network_receive_bytes_total{namespace="stackrox"}[10m]))'
  avg_network_transmit_query='avg by (job) (rate(container_network_transmit_bytes_total{namespace="stackrox"}[10m]))'
  max_network_transmit_query='max by (job) (rate(container_network_transmit_bytes_total{namespace="stackrox"}[10m]))'
  avg_total_network_receive_query='avg by (job) (container_network_receive_bytes_total{namespace="stackrox"})'
  max_total_network_receive_query='max by (job) (container_network_receive_bytes_total{namespace="stackrox"})'
  avg_total_network_transmit_query='avg by (job) (container_network_transmit_bytes_total{namespace="stackrox"})'
  max_total_network_transmit_query='max by (job) (container_network_transmit_bytes_total{namespace="stackrox"})'

  avg_cpu_value=$(do_prometheus_query_and_get_value "$avg_cpu_query")
  max_cpu_value=$(do_prometheus_query_and_get_value "$max_cpu_query")
  avg_mem_value=$(do_prometheus_query_and_get_value "$avg_mem_query")
  max_mem_value=$(do_prometheus_query_and_get_value "$max_mem_query")
  avg_network_receive_value=$(do_prometheus_query_and_get_value "$avg_network_receive_query")
  max_network_receive_value=$(do_prometheus_query_and_get_value "$max_network_receive_query")
  avg_network_transmit_value=$(do_prometheus_query_and_get_value "$avg_network_transmit_query")
  max_network_transmit_value=$(do_prometheus_query_and_get_value "$max_network_transmit_query")
  avg_total_network_receive_value=$(do_prometheus_query_and_get_value "$avg_total_network_receive_query")
  max_total_network_receive_value=$(do_prometheus_query_and_get_value "$max_total_network_receive_query")
  avg_total_network_transmit_value=$(do_prometheus_query_and_get_value "$avg_total_network_transmit_query")
  max_total_network_transmit_value=$(do_prometheus_query_and_get_value "$max_total_network_transmit_query")

  echo "Average cpu usage: $avg_cpu_value"
  echo "Maximum cpu usage: $max_cpu_value"
  echo ""
  echo "Average memory usage (bytes): $avg_mem_value"
  echo "Maximum memory usage (bytes): $max_mem_value"
  echo ""
  echo "Average network received (bytes per second): $avg_network_receive_value"
  echo "Maximum network received (bytes per second): $max_network_receive_value"
  echo ""
  echo "Average network transmit (bytes per second): $avg_network_transmit_value"
  echo "Maximum network transmit (bytes per second): $max_network_transmit_value"
  echo ""
  echo "Average total network received (bytes): $avg_total_network_receive_value"
  echo "Maximum total network received (bytes): $max_total_network_receive_value"
  echo ""
  echo "Average total network transmit (bytes): $avg_total_network_transmit_value"
  echo "Maximum total network transmit (bytes): $max_total_network_transmit_value"

  echo ""
  echo "#################"
  echo ""

}

artifacts_dir=${1:-/tmp/artifacts}

export KUBECONFIG=$artifacts_dir/kubeconfig

password="$(cat "$artifacts_dir"/kubeadmin-password)"
printf '%s\n' "$password" | oc login -u kubeadmin

token="$(oc whoami -t)"
url="$(oc get routes -A | grep prometheus-k8s | awk '{print $3}' | head -1)"

get_reports_for_collector_timers
get_reports_for_collector_counters
get_reports_for_sensor_network_flow
get_reports_for_cpu_mem_and_network_usage
