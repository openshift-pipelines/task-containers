#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/s2i-common.sh"

# file storing image digest
filename="workspace/source/image-digest"

if [ -e "$filename" ]; then
  echo "File exists: $filename"
else
  echo "File does not exist: $filename"
  exit 1
fi

# Writing image digest to results
cat "$filename" | tee /tekton/results/IMAGE_DIGEST