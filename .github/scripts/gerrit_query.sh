#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

# Usage: ./gerrit_query.sh <gerrit_url> <patchset_number> <ssh_user_name> \
#          [gerrit_server_port]

set -euo pipefail

# Store the current working directory for relative path operations
WORK_DIR="$(pwd)"

# Timeout for SSH operations (30 seconds)
SSH_TIMEOUT=30

if [ "$#" -lt 3 ]; then
  echo "Error: Usage: $0 <gerrit_url> <patchset_number> <ssh_user_name>" \
    "[gerrit_server_port]" >&2
  exit 1
fi

gerrit_url="$1"
cid_patch_set_no="$2"
ssh_user_name="$3"
# Gerrit SSH port; defaults to the standard Gerrit port when omitted.
gerrit_server_port="${4:-29418}"

# Validate inputs
if [[ -z "$gerrit_url" ]]; then
  echo "Error: Gerrit URL cannot be empty" >&2
  exit 1
fi

if [[ -z "$ssh_user_name" ]]; then
  echo "Error: SSH username cannot be empty" >&2
  exit 1
fi

# Validate patchset number if provided
if [[ -n "$cid_patch_set_no" && ! "$cid_patch_set_no" =~ ^[0-9]+$ ]]; then
  echo "Error: Patchset number must be numeric, got: '$cid_patch_set_no'" >&2
  exit 1
fi

# Validate Gerrit URL format
if [[ ! "$gerrit_url" =~ ^https?://[^/]+/.*c/.*/\+/[0-9]+ ]]; then
  echo "Error: Invalid Gerrit URL format." \
    "Expected: https://hostname/gerrit/c/project/+/number" >&2
  exit 1
fi

# Restrict the SSH username to a safe character set; it is used verbatim
# in the SSH connection target. A leading dash is rejected so the value
# cannot be parsed as an SSH option (option-injection).
if [[ ! "$ssh_user_name" =~ ^[A-Za-z0-9._][A-Za-z0-9._-]*$ ]]; then
  echo "Error: Invalid SSH username: '$ssh_user_name'" >&2
  exit 1
fi

# Validate the Gerrit SSH port as a numeric TCP port (1-65535).
if [[ ! "$gerrit_server_port" =~ ^[0-9]+$ ]] \
    || [ "$gerrit_server_port" -lt 1 ] \
    || [ "$gerrit_server_port" -gt 65535 ]; then
  echo "Error: Invalid Gerrit server port: '$gerrit_server_port'" >&2
  exit 1
fi

extract_project() {
  echo "$1" | sed -E 's#.*/c/([^+]+)/\+.*#\1#'
}

extract_change_number() {
  echo "$1" | sed -E 's#.*/\+/([0-9]+).*#\1#'
}

extract_hostname() {
  echo "$1" | sed -E 's#https?://([^/]+)/.*#\1#'
}

gerrit_hostname=$(extract_hostname "$gerrit_url")
change_number=$(extract_change_number "$gerrit_url")
project=$(extract_project "$gerrit_url")

# Validate extracted values against safe character sets before they are
# used to build the (remote) Gerrit query command. This prevents command
# or query injection via a crafted Gerrit change URL.
if [[ ! "$change_number" =~ ^[0-9]+$ ]]; then
  echo "Error: Change number must be numeric, got: '$change_number'" >&2
  exit 1
fi

if [[ ! "$gerrit_hostname" =~ ^[A-Za-z0-9.-]+$ ]]; then
  echo "Error: Invalid Gerrit hostname: '$gerrit_hostname'" >&2
  exit 1
fi

if [[ ! "$project" =~ ^[A-Za-z0-9._/-]+$ ]]; then
  echo "Error: Invalid Gerrit project: '$project'" >&2
  exit 1
fi

# Build the remote Gerrit query command. All interpolated values are
# validated above, and the command is passed to ssh as a single argument
# via an argument array (no local 'eval'), eliminating shell injection on
# the runner.
remote_query="gerrit query --format=JSON project:$project change:$change_number is:open limit:1"

if [ -n "$cid_patch_set_no" ]; then
    remote_query="$remote_query --patch-sets"
else
    remote_query="$remote_query --current-patch-set"
fi

ssh_args=(
    -o ConnectTimeout=10
    -o StrictHostKeyChecking=yes
    -p "$gerrit_server_port"
    --
    "${ssh_user_name}@${gerrit_hostname}"
    "$remote_query"
)

echo "Executing Gerrit query for change $change_number in project $project..." >&2

# Execute SSH command with proper error handling
if ! json_output=$(timeout "$SSH_TIMEOUT" ssh "${ssh_args[@]}" 2>&1); then
  echo "Error: SSH connection to Gerrit failed" >&2
  echo "Output: $json_output" >&2
  exit 1
fi

if [[ -z "$json_output" ]]; then
  echo "Error: Gerrit query returned empty response" >&2
  exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

# Parse with jq and validate JSON
echo "Parsing Gerrit query response..." >&2

# Print raw response for debugging
echo "Raw JSON response:" >&2
echo "$json_output" >&2

# Validate JSON format
if ! echo "$json_output" | jq empty 2>/dev/null; then
  echo "Error: Invalid JSON response from Gerrit" >&2
  echo "Response: $json_output" >&2
  exit 1
fi

# Parse with jq
GERRIT_BRANCH=$(echo "$json_output" | jq -r '.branch | select( . != null )')
GERRIT_CHANGE_ID=$(echo "$json_output" | jq -r '.id | select( . != null )')
GERRIT_CHANGE_URL=$(echo "$json_output" | jq -r '.url | select( . != null )')
GERRIT_PATCHSET_NUMBER=$(echo "$json_output" | jq --argjson num "${cid_patch_set_no:-0}" -r 'if $num > 0 then .patchSets[$num - 1].number else .currentPatchSet.number end | select( . != null )')
GERRIT_PATCHSET_REVISION=$(echo "$json_output" | jq --argjson num "${cid_patch_set_no:-0}" -r 'if $num > 0 then .patchSets[$num - 1].revision else .currentPatchSet.revision end | select( . != null )')
GERRIT_REFSPEC=$(echo "$json_output" | jq --argjson num "${cid_patch_set_no:-0}" -r 'if $num > 0 then .patchSets[$num - 1].ref else .currentPatchSet.ref end | select( . != null )')
GERRIT_PROJECT=$(echo "$json_output" | jq -r '.project | select( . != null )' | sed 's#/#-#')
GERRIT_HOSTNAME=$(extract_hostname "$GERRIT_CHANGE_URL")

# Validate required fields were extracted
if [[ -z "$GERRIT_CHANGE_ID" ]]; then
  echo "Error: Could not extract change ID from Gerrit response" >&2
  echo "This may indicate the change doesn't exist or insufficient permissions" >&2
  exit 1
fi

if [[ -z "$GERRIT_BRANCH" || -z "$GERRIT_PATCHSET_REVISION" ]]; then
  echo "Error: Could not extract required fields from Gerrit response" >&2
  echo "Branch: '$GERRIT_BRANCH', Revision: '$GERRIT_PATCHSET_REVISION'" >&2
  exit 1
fi

# Write output file to the working directory
output_file="$WORK_DIR/$change_number.file"
{
    echo "GERRIT_BRANCH=$GERRIT_BRANCH"
    echo "GERRIT_CHANGE_ID=$GERRIT_CHANGE_ID"
    echo "GERRIT_CHANGE_URL=$GERRIT_CHANGE_URL"
    echo "GERRIT_CHANGE_NUMBER=$change_number"
    echo "GERRIT_EVENT_TYPE=comment_added"
    echo "GERRIT_PATCHSET_NUMBER=$GERRIT_PATCHSET_NUMBER"
    echo "GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION"
    echo "GERRIT_PROJECT=$GERRIT_PROJECT"
    echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
    echo "GERRIT_HOSTNAME=$GERRIT_HOSTNAME"
} > "$output_file"

# Verify output file was created
if [[ ! -f "$output_file" ]]; then
  echo "Error: Failed to create output file: $output_file" >&2
  exit 1
fi

echo "Successfully queried Gerrit change information:" >&2
echo "  Change ID: $GERRIT_CHANGE_ID" >&2
echo "  Branch: $GERRIT_BRANCH" >&2
echo "  Patchset: $GERRIT_PATCHSET_NUMBER" >&2
echo "  Output written to: $output_file" >&2
