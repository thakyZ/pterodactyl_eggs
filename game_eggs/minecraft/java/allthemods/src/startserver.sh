#!/bin/bash

# \`-d64\` option was removed in Java 10, this handles these versions accordingly
JAVA_FLAGS=""
if (( \$(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1) < 10 )); then
    JAVA_FLAGS="-d64"
fi

if [ -f "server-setup-config.temp.yaml" ]; then
    echo "reading \\\`server-setup-config.temp.yaml'"
    new_server_setup_config=\$(envsubst < server-setup-config.temp.yaml)
    if [ \$new_server_setup_config != "# Version of the specs"* ]; then
      echo "Failed to get temp sevrer config."
    fi
    echo "\$new_server_setup_config" > server-setup-config.yaml
else
    echo "Temp file \\\`server-setup-config.temp.yaml' was not found."
fi

DO_RAMDISK=0
if [[ \$(grep 'ramDisk:' < "server-setup-config.yaml" | awk 'BEGIN {FS=":"}{print \$2}') =~ "yes" ]]; then
    SAVE_DIR=\$(grep 'level-name' < "server.properties" | awk 'BEGIN {FS="="}{print \$2}')
    mv "\${SAVE_DIR}" "\${SAVE_DIR}_backup"
    mkdir "\${SAVE_DIR}"
    sudo mount -t tmpfs -o size=2G tmpfs "\${SAVE_DIR}"
    DO_RAMDISK=1
fi
if [ -f serverstarter-2.3.1.jar ]; then
    echo "Skipping download. Using existing serverstarter-2.3.1.jar"
    java \$JAVA_FLAGS -jar serverstarter-2.3.1.jar
    if [[ \$DO_RAMDISK -eq 1 ]]; then
        sudo umount "\${SAVE_DIR}"
        rm -rf "\${SAVE_DIR}"
        mv "\${SAVE_DIR}_backup" "\${SAVE_DIR}"
    fi
    exit 0
else
    export URL="https://github.com/BloodyMods/ServerStarter/releases/download/v2.3.1/serverstarter-2.3.1.jar"
fi
echo "\${URL}"

if [ "\$(which wget)" != "" ]; then
    echo "DEBUG: (wget) Downloading \${URL}"
    wget -O serverstarter-2.3.1.jar "\${URL}"
else
    if [ "\$(which curl)" != 0 ]; then
        echo "DEBUG: (curl) Downloading \${URL}"
        curl -o serverstarter-2.3.1.jar -L "\${URL}"
    else
        echo "Neither wget or curl were found on your system. Please install one and try again"
    fi
fi

java \$JAVA_FLAGS -jar serverstarter-2.3.1.jar
if [[ \$DO_RAMDISK -eq 1 ]]; then
    sudo umount "\${SAVE_DIR}"
    rm -rf "\${SAVE_DIR}"
    mv "\${SAVE_DIR}_backup" "\${SAVE_DIR}"
fi
