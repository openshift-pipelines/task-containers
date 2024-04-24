#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/skopeo-common.sh"

phase "Copying '${PARAMS_SOURCE}' into '${PARAMS_DESTINATION}'"

set -x

if [ -n "${PARAMS_SOURCE}" ] && [ -n "${PARAMS_DESTINATION}" ]; then
    skopeo copy "${SKOPEO_DEBUG_FLAG}" \
        --src-tls-verify="${PARAMS_SRC_TLS_VERIFY}" \
        --dest-tls-verify="${PARAMS_DEST_TLS_VERIFY}" \
        "${PARAMS_SOURCE}" \
        "${PARAMS_DESTINATION}"
else
    # Function to copy multiple images.
    copyimages() {
        filename="${WORKSPACES_IMAGES_URL_PATH}/url.txt"
        while IFS= read -r line || [ -n "$line" ]
        do
            cmd=""
            for url in $line
            do
                cmd="$cmd $url"
            done
            read -ra SOURCE <<<"${cmd}"
            skopeo copy "${SOURCE[@]}" --src-tls-verify="${PARAMS_SRC_TLS_VERIFY}" --dest-tls-verify="${PARAMS_DEST_TLS_VERIFY}"
            echo "$cmd"
        done < "$filename"
    }

    copyimages
fi
