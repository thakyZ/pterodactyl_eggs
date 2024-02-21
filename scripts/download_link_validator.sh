#!/bin/bash
## this is a simple script to validate a download url actaully exists

if [ -n "${DOWNLOAD_URL}" ]; then
    if [[ "$(curl --output /dev/null --silent --head --fail "${DOWNLOAD_URL}"; echo $?)" == "0" ]]; then
        echo -e "Link is valid. setting download link to ${DOWNLOAD_URL}"
        DOWNLOAD_LINK=${DOWNLOAD_URL}
    else
        echo -e "Link is invalid closing out"
        exit 2
    fi
fi
