#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

# Usage: ./extract_ssh_inputs.sh <gerrit_url>

set -euo pipefail

# Store the current working directory for relative path operations
WORK_DIR="$(pwd)"

if [ "$#" -ne 1 ]; then
  echo "Error: Usage: $0 <gerrit_url>" >&2
  exit 1
fi

gerrit_url="$1"

# Validate URL format
if [[ ! "$gerrit_url" =~ ^https?://[^/]+/.*c/.*/\+/[0-9]+ ]]; then
  echo "Error: Invalid Gerrit URL format. Expected: https://hostname/gerrit/c/project/+/number" >&2
  exit 1
fi

# Extract hostname from URL
extract_hostname() {
  echo "$1" | sed -E 's#https?://([^/]+)/.*#\1#'
}

# Extract username from URL if embedded (not in your current format)
# Otherwise expect it from action input
# extract_username() {
#   echo "$1" | sed -E 's#.*//([^@]+)@.*#\1#'
# }

# Extract project from URL
extract_project() {
  echo "$1" | sed -E 's#.*/c/([^/]+/[^/]+)/\+.*#\1#'
}

# Extract change number
extract_change_number() {
  echo "$1" | sed -E 's#.*/\+/([0-9]+).*#\1#'
}

gerrit_hostname=$(extract_hostname "$gerrit_url")
project=$(extract_project "$gerrit_url")
change_number=$(extract_change_number "$gerrit_url")

# Validate extracted values
if [[ -z "$gerrit_hostname" || -z "$project" || -z "$change_number" ]]; then
  echo "Error: Failed to extract required information from Gerrit URL" >&2
  echo "Hostname: '$gerrit_hostname', Project: '$project', Change: '$change_number'" >&2
  exit 1
fi

# Validate change number is numeric
if ! [[ "$change_number" =~ ^[0-9]+$ ]]; then
  echo "Error: Change number must be numeric, got: '$change_number'" >&2
  exit 1
fi

{
  echo "GERRIT_HOSTNAME=$gerrit_hostname"
  echo "GERRIT_PROJECT=$project"
  echo "GERRIT_CHANGE_NUMBER=$change_number"
} > "$WORK_DIR/gerrit_ssh_info.env"

echo "Successfully extracted Gerrit information:" >&2
echo "  Hostname: $gerrit_hostname" >&2
echo "  Project: $project" >&2
echo "  Change: $change_number" >&2
echo "  Output file: $WORK_DIR/gerrit_ssh_info.env" >&2
