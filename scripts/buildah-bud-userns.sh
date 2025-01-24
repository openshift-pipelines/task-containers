#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

function _buildah() {
    buildah \
        --storage-driver="${PARAMS_STORAGE_DRIVER}" \
        --tls-verify="${PARAMS_TLS_VERIFY}" \
        ${*}
}

# Prepare Buildah command
BUILD_CMD="HOME=/workspace/source _buildah bud"

# Extra arguments for the build
if [[ -n "${PARAMS_BUILD_EXTRA_ARGS}" ]]; then
    phase "Extra 'buildah bud' arguments informed: '${PARAMS_BUILD_EXTRA_ARGS}'"
    BUILD_CMD+=" ${PARAMS_BUILD_EXTRA_ARGS}"
fi

# User Namespace Configuration
if [[ -n "${PARAMS_USER_NAMESPACE}" ]]; then
    BUILD_CMD+=" --userns=${PARAMS_USER_NAMESPACE}"
fi

if [[ -n "${PARAMS_UID_MAP}" ]]; then
    BUILD_CMD+=" --userns-uid-map=${PARAMS_UID_MAP}"
fi

if [[ -n "${PARAMS_GID_MAP}" ]]; then
    BUILD_CMD+=" --userns-gid-map=${PARAMS_GID_MAP}"
fi

ENTITLEMENT_VOLUME=""
if [[ "${WORKSPACES_RHEL_ENTITLEMENT_BOUND}" == "true" ]]; then
    ENTITLEMENT_VOLUME="--volume ${WORKSPACES_RHEL_ENTITLEMENT_PATH}:/etc/pki/entitlement"
fi

# Adding entitlement volume and build arguments
BUILD_CMD+=" ${ENTITLEMENT_VOLUME} ${BUILD_ARGS[@]}"

# Check for /etc/subgid and /etc/subuid
if [[ -f /etc/subgid ]]; then
    phase "Contents of /etc/subgid:"
    ls -l /etc/subgid
    cat /etc/subgid
else
    phase "/etc/subgid does not exist."
fi

if [[ -f /etc/subuid ]]; then
    phase "Contents of /etc/subuid:"
    ls -l /etc/subuid
    cat /etc/subuid
else
    phase "/etc/subuid does not exist."
fi

# Building the image
phase "Building '${PARAMS_IMAGE}' based on '${DOCKERFILE_FULL}'"
BUILD_CMD+=" --file='${DOCKERFILE_FULL}' --tag='${PARAMS_IMAGE}' '${PARAMS_CONTEXT}'"

# Execute the command
eval ${BUILD_CMD}

if [[ "${PARAMS_SKIP_PUSH}" == "true" ]]; then
    phase "Skipping pushing '${PARAMS_IMAGE}' to the container registry!"
    exit 0
fi

#
# Push
#

phase "Pushing '${PARAMS_IMAGE}' to the container registry"

[[ -n "${PARAMS_PUSH_EXTRA_ARGS}" ]] &&
    phase "Extra 'buildah bud' arguments informed: '${PARAMS_PUSH_EXTRA_ARGS}'"

# temporary file to store the image digest, information only obtained after pushing the image to the
# container registry
declare -r digest_file="/tmp/buildah-digest.txt"

_buildah push ${PARAMS_PUSH_EXTRA_ARGS} \
    --digestfile="${digest_file}" \
    "${PARAMS_IMAGE}" \
    "docker://${PARAMS_IMAGE}"

#
# Results
#


phase "Inspecting digest report ('${digest_file}')"

[[ ! -r "${digest_file}" ]] &&
    fail "Unable to find digest-file at '${digest_file}'"

declare -r digest_sum="$(cat ${digest_file})"

[[ -z "${digest_sum}" ]] &&
    fail "Digest file '${digest_file}' is empty!"

phase "Successfuly built container image '${PARAMS_IMAGE}' ('${digest_sum}')"
echo -n "${PARAMS_IMAGE}" | tee ${RESULTS_IMAGE_URL_PATH}
echo -n "${digest_sum}" | tee ${RESULTS_IMAGE_DIGEST_PATH}
