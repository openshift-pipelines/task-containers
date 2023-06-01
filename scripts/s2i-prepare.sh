 [2:52 pm, 01/06/2023] $De: #!/usr/bin/env bash

declare -rx PARAMS_VERSION="${PARAMS_VERSION:-}"
declare -rx PARAMS_PATH_CONTEXT="${PARAMS_PATH_CONTEXT:-}"
declare -rx PARAMS_TLS_VERIFY="${PARAMS_TLS_VERIFY:-}"
declare -rx PARAMS_VERBOSE="${PARAMS_VERBOSE:-}"

declare -rx RESULTS_IMAGE_DIGEST_PATH="${RESULTS_IMAGE_DIGEST_PATH:-}"

#
# Asserting Environment
#

declare -ra required_vars=(
    PARAMS_VERSION
    PARAMS_PATH_CONTEXT
    RESULTS_IMAGE_DIGEST_PATH
)

for v in "${required_vars[@]}"; do
    [[ -z "${!v}" ]] &&
        fail "'${v}' environment variable is not set!"
done

#
# S2I Authentication
#

declare -x REGISTRY_AUTH_FILE=""

docker_config="${HOME}/.docker/config.json"
if [[ -f "${docker_config}" ]]; then
    phase "Setting REGISTRY_AUTH_FILE to '${docker_config}'"
    REGISTRY_AUTH_FILE=${docker_config}
fi

#
# Verbose Output
#

declare -x S2I_GO_DEBUG_FLAG=""

if [[ "${PARAMS_VERBOSE}" == "true" ]]; then
    S2I_GO_DEBUG_FLAG="--debug"
    set -x
fi
