#!/usr/bin/env bash
#
# Uses s2i to generate the repesctive Containerfile based on the infomred builder. The Containerfile
# is stored on a temporary location.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/s2i-common.sh"

# re-using the same parameters than buildah, s2i needs buildah abilities to create the final
# container image based on what s2i generates
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

#
# Prepare
#

# making sure the required workspace "source" is bounded, which means its volume is currently mounted
# and ready to use
phase "Inspecting source workspace '${WORKSPACES_SOURCE_PATH}' (PWD='${PWD}')"
[[ "${WORKSPACES_SOURCE_BOUND}" != "true" ]] &&
    fail "Workspace 'source' is not bounded"

phase "Inspecting context subdirectory '${PARAMS_SUBDIRECTORY}'"
[[ ! -d "${PARAMS_SUBDIRECTORY}" ]] &&
    fail "Application source code directory not found at '${PARAMS_SUBDIRECTORY}'"

#
# S2I Generate
#

phase "Generating the Containerfile for S2I builder image '${PARAMS_BUILDER_IMAGE}'"
s2i --loglevel "${S2I_LOGLEVEL}" \
    build "${PARAMS_SUBDIRECTORY}" "${PARAMS_BUILDER_IMAGE}" \
        --as-dockerfile "${S2I_CONTAINERFILE_PATH}"

phase "Inspecting the Containerfile generated at '${S2I_CONTAINERFILE_PATH}'"
[[ ! -f "${S2I_CONTAINERFILE_PATH}" ]] &&
    fail "Generated Containerfile is not found!"

set +x
phase "Generated Containerfile payload"
echo -en ">>> ${S2I_CONTAINERFILE_PATH}\n$(cat ${S2I_CONTAINERFILE_PATH})\n<<< EOF\n"
