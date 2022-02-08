#!/usr/bin/env bash

num_meta_iter=${1:-5}
num_iter=${2:-5}
sleep_between_curl_time=${3:-1}
sleep_between_iterations=${4:-1}
url=$5

for ((i = 0; i < num_meta_iter; i = i + 1)); do
    for ((j = 0; j < num_iter; j = j + 1)); do
        curl "$url"
        sleep "$sleep_between_curl_time"
    done
    sleep "$sleep_between_iterations"
done
