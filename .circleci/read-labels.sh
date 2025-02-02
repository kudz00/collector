#!/usr/bin/env bash

#!/bin/sh
set -eo pipefail

# This script is intended to be run in CircleCI, and tells you whether or not the pull request you're on has a label
# passed in. The script exits with code
# 0 if the PR has the label
# 1 if it could parse the labels, and found out that the PR does not have the required label,
# >1 it couldn't parse the labels (either it's not on a PR, or the required env variables were not found.
# Most clients should just check for a 0 exit code, and do the default thing if the code is non-zero.

usage() {
    echo "Usage: $0 <label file path>"
    exit 1
}

[[ -n "${CIRCLE_PULL_REQUEST}" ]] || {
    echo "Not on a PR, ignoring labels"
    exit 0
}

labels_path="$1"
[[ -n "$labels_path" ]] || usage

mkdir -p "$labels_path"
cd "$labels_path"

[[ -n "${GITHUB_TOKEN}" ]] || {
    echo "No GitHub token found"
    exit 2
}
[[ -n "${CIRCLE_PROJECT_USERNAME}" ]] || {
    echo "CIRCLE_PROJECT_USERNAME not found"
    exit 2
}
[[ -n "${CIRCLE_PROJECT_REPONAME}" ]] || {
    echo "CIRCLE_PROJECT_REPONAME not found"
    exit 2
}

pull_request_number="${CIRCLE_PULL_REQUEST##*/}"
url="https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls/${pull_request_number}"
while IFS= read -r tag || [[ -n "$tag" ]]; do
    [[ -n "$tag" ]] || continue
    echo "Detected tag '${tag}'"
    touch "$tag"
done < <(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "${url}" | jq '([.labels | .[].name]  // []) | .[]' -r)
