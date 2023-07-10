#!/usr/bin/env bash

# target image name (fully qualified) to be build with s2i, redeclaring the same parameter name than
# buildah task uses
declare -x PARAMS_IMAGE="${PARAMS_IMAGE:-}"

# full path to the container file generated by s2i
declare -rx S2I_CONTAINERFILE_PATH="${S2I_CONTAINERFILE_PATH:-/s2i-generate/Dockerfile.gen}"

#
# Asserting Environment
#

exported_or_fail \
    WORKSPACES_SOURCE_PATH \
    PARAMS_IMAGE

#
# Verbose Output
#

declare -x S2I_LOGLEVEL="0"

if [[ "${PARAMS_VERBOSE}" == "true" ]]; then
    S2I_LOGLEVEL="2"
    set -x
fi
