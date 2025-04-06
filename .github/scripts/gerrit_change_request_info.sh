#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

# Test/validation suite for individual actions and workflows

# Script to execute a Gerrit query, parse JSON output, and set environment variables.
# Usage: ./gerrit_query_parse.sh <gerrit_url> [<patchset revision>] [<ssh_user_name>]

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <gerrit_url> [ <patchset revision> ] [<ssh_user_name>]"
  exit 1
fi

gerrit_url="$1"
cid_patch_set_no="$2"
ssh_user_name="$3"

# Extract project from URL
extract_project() {
  local url="$1"
  local project

  project=$(echo "$url" | sed -E 's#.*/c/([^/]+/[^/]+)/\+.*#\1#')

  echo "$project"
}

# Extract change number from URL
extract_change_number() {
  local url="$1"
  local change_number

  change_number=$(echo "$url" | sed -E 's#.*/\+/([0-9]+).*#\1#')

  echo "$change_number"
}

# Extract hostname from URL
extract_hostname() {
  local url="$1"
  local hostname

  hostname=$(echo "$url" | sed -E 's#https?://([^/]+)/.*#\1#')

  echo "$hostname"
}

gerrit_hostname=$(extract_hostname "$gerrit_url")
change_number=$(extract_change_number "$gerrit_url")
project=$(extract_project "$gerrit_url")

if [ ! -z "$cid_patch_set_no" ]; then
    ssh_command="ssh -v -n -p 29418 $ssh_user_name@$gerrit_hostname 'gerrit query --format=JSON project:$project change:$change_number owner:self is:open limit:1' --patch-sets"
elif [ ! -z "$change_number" ]; then
    ssh_command="ssh -v -n -p 29418 $ssh_user_name@$gerrit_hostname 'gerrit query --format=JSON project:$project change:$change_number owner:self is:open limit:1' --current-patch-set"
fi

# Execute the SSH command and capture the JSON output
json_output=$(eval "$ssh_command" 2>/dev/null)

if [[ $? -ne 0 || -z "$json_output" ]]; then
  echo "Error: Gerrit query failed. Check your SSH connection and credentials."
  exit 1
fi

# Parse the JSON output using jq
GERRIT_BRANCH=$(echo "$json_output" | jq -r '.branch | select( . != null )')
GERRIT_CHANGE_ID=$(echo "$json_output" | jq -r '.id | select( . != null )')
GERRIT_CHANGE_URL=$(echo "$json_output" | jq -r '.url | select( . != null )')
GERRIT_CHANGE_NUMBER=$(echo "$json_output" | jq -r '.number | select( . != null )')
GERRIT_PATCHSET_NUMBER=$(echo "$json_output" | jq --argjson num "${cid_patch_set_no:-0}" -r 'if $num > 0 then .patchSets[$num - 1].number else .currentPatchSet.number end | select( . != null )')
GERRIT_PATCHSET_REVISION=$(echo "$json_output" | jq --argjson num "${cid_patch_set_no:-0}" -r 'if $num > 0 then .patchSets[$num - 1].revision else .currentPatchSet.revision end | select( . != null )')
GERRIT_REFSPEC=$(echo "$json_output" | jq --argjson num "${cid_patch_set_no:-0}" -r 'if $num > 0 then .patchSets[$num - 1].ref else .currentPatchSet.ref end | select( . != null )')
GERRIT_PROJECT=$(echo "$json_output" | jq -r '.project | select( . != null )' | sed 's#/#-#')
GERRIT_HOSTNAME=$(extract_hostname "$GERRIT_CHANGE_URL")

{
    # Set the environment variables
    echo "GERRIT_BRANCH=\"$GERRIT_BRANCH\""
    echo "GERRIT_CHANGE_ID=\"$GERRIT_CHANGE_ID\""
    echo "GERRIT_CHANGE_URL=\"$GERRIT_CHANGE_URL\""
    echo "GERRIT_CHANGE_NUMBER=\"$GERRIT_CHANGE_NUMBER\""
    echo "GERRIT_EVENT_TYPE=\"comment_added\"" #hardcoded value
    echo "GERRIT_PATCHSET_NUMBER=\"$GERRIT_PATCHSET_NUMBER\""
    echo "GERRIT_PATCHSET_REVISION=\"$GERRIT_PATCHSET_REVISION\""
    echo "GERRIT_PROJECT=\"opendaylight/$GERRIT_PROJECT\""
    echo "GERRIT_REFSPEC=\"$GERRIT_REFSPEC\""
    echo "GERRIT_HOSTNAME=\"$GERRIT_HOSTNAME\""
} > "$GERRIT_CHANGE_NUMBER.file"

exit 0
