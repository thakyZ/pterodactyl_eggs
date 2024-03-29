#!/bin/bash
# Forge Installation Script
#
# Server Files: /mnt/server
apt update
apt install -y curl jq

if [[ ! -d /mnt/server ]]; then
  mkdir /mnt/server
fi

cd /mnt/server || exit 1

echo "$(cat <<-END
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
END
)" > "startserver.sh"
chmod +x "startserver.sh"
echo "$(cat <<-END
# Version of the specs, only for internal usage if this format should ever change drastically
_specver: 2

# modpack related settings, changes the supposed to change the visual appearance of the launcher
modpack:
  # Name of the mod pack, that is displayed in various places where it fits
  name: \${SERVER_NAME}

  # Description
  description: \${SERVER_DESCRIPTION}



# settings regarding the installation of the modpack
install:
  # version of minecraft, needs the exact version
  mcVersion: \${MC_VERSION}

  # exact version of forge or fabric that is supposed to be used
  # if this value is a null value so ( ~, null, or "" ) then the version from the mod pack is going to be used
  loaderVersion: \${FORGE_VERSION}

  # If a custom installer is supposed to used, specify the url here: (Otherwise put "", ~ or null here)
  # supports variables: {{@loaderversion@}} and {{@mcversion@}}
  # For forge: "https://files.minecraftforge.net/maven/net/minecraftforge/forge/{{@mcversion@}}-{{@loaderversion@}}/forge-{{@mcversion@}}-{{@loaderversion@}}-installer.jar"
  # For Fabric: "https://maven.fabricmc.net/net/fabricmc/fabric-installer/{{@loaderversion@}}/fabric-installer-{{@loaderversion@}}.jar"
  installerUrl: "https://files.minecraftforge.net/maven/net/minecraftforge/forge/{{@mcversion@}}-{{@loaderversion@}}/forge-{{@mcversion@}}-{{@loaderversion@}}-installer.jar"

  # Installer Arguments
  # These Arguments have to be passed to the installer
  #
  # For Fabric:
  # installerArguments:
  #   - "-downloadMinecraft"
  #   - "server"
  #
  # For Forge:
  # installerArguments:
  #   - "--installServer"
  installerArguments:
    - "--installServer"

  # Link to where the file where the modpack can be distributed
  # This supports loading from local files as well for most pack types if there is file://{PathToFile} in the beginning
  modpackUrl: \${MODPACK_URL}

  # This is used to specify in which format the modpack is distributed, the server launcher has to handle each individually if their format differs
  # current supported formats:
  # - curseforge or curse
  # - curseid
  # - zip or zipfile
  modpackFormat: \${MODPACK_FORMAT}

  # Settings which are specific to the format used, might not be needed in some casese
  formatSpecific:
    # optional paramenter used for curse to specify a whole project to ignore (mostly if it is client side only)
    ignoreProject:
      - 263420
      - 317780
      - 232131
      - 231275
      - 367706
      - 261725
      - 243863
      - 305373
      - 325492
      - 296468
      - 308240
      - 362791
      - 291788
      - 326950
      - 237701
      - 391382
      - 358191
      - 271740
      - 428199
      - 431430
      - 272515
      - 250398
      - 363363
      - 495693
      - 324717

  # The base path where the server should be installed to, ~ for current path
  baseInstallPath: setup/

  # a list of files which are supposed to be ignored when installing it from the client files
  # this can either use regex or glob {default glob: https://docs.oracle.com/javase/8/docs/api/java/nio/file/FileSystem.html#getPathMatcher-java.lang.String-}
  # specify with regex:.... or glob:.... if you want to force a matching type
  ignoreFiles:
    - mods/Overrides.txt
    - mods/optifine*.jar
    - mods/optiforge*.jar
    - resources/**
    - packmenu/**
    - openloader/resources/**

  # often a server needs more files, which are nearly useless on the client, such as tickprofiler
  # This is a list of files, each ' - ' is a new file:
  # url is the directlink to the file, destination is the path to where the file should be copied to
  additionalFiles: ~
    #- url: https://media.forgecdn.net/files/2844/278/restrictedportals-1.15-1.0.jar
    #  destination: mods/restrictedportals-1.15-1.0.jar
    #- url: https://media.forgecdn.net/files/2874/966/Morpheus-1.15.2-4.2.46.jar
    #  destination: mods/Morpheus-1.15.2-4.2.46.jar
    #- url: https://media.forgecdn.net/files/2876/89/spark-forge.jar
    #  destination: mods/spark-forge.jar

  # For often there are config which the user wants to change, here is the place to put the local path to configs, jars or whatever
  # You can copy files or folders
  localFiles:
    - from: setup/modpack-download.zip
      to: setup/test/modpack-download-copied.zip
    - from: setup/AOF 2/.minecraft
      to: setup/.

  # This makes the program check the folder for whether it is supposed to use the
  checkFolder: true

  # Whether to install the Loader (Forge or Fabric) or not, should always be true unless you only want to install the pack
  installLoader: true

  # Sponge bootstrapper jar URL
  # Only needed if you have spongefix enabled
  spongeBootstrapper: https://github.com/simon816/SpongeBootstrap/releases/download/v0.7.1/SpongeBootstrap-0.7.1.jar

  # Time in seconds before the connection attempt to any webservice like forge/curseforge times out
  # Only increase this timer if you have problems
  connectTimeout: 30

  # Time in seconds before the read attempt to any webservice like forge/curseforge times out
  # Only increase this timer if you have problems
  readTimeout: 30



# settings regarding the launching of the pack
launch:
  # applies the launch wrapper to fix sponge for a few mods
  spongefix: false

  # Use a RAMDisk for the world folder
  # case-sensitive; use only lowercase \`true\` or \`false\`
  # NOTE: The server must have run once fully before switching to \`true\`!
  ramDisk: false

  # checks with the help of a few unrelated server whether the server is online
  checkOffline: true

  # These servers are going to be checked:
  checkUrls:
    - https://github.com/
    - https://www.curseforge.com/
    - https://cursemeta.dries007.net/

  # specifies the max amount of ram the server is supposed to launch with
  maxRam: \${MAX_RAM}

  # specifies the min amount of ram the server is supposed to launch with
  minRam: \${MIN_RAM}

  # specifies whether the server is supposed to auto restart after crash
  autoRestart: true

  # after a given amount of crashes in a given time the server will stop auto restarting
  crashLimit: 10

  # Time a crash should be still accounted for in the {crashLimit}
  # syntax is either [number]h or [number]min or [number]s
  crashTimer: 60min

  # Arguments that need to go before the 'java' argument, something like linux niceness
  # This is only a string, not a list.
  preJavaArgs: ~

  # Start File Name, variables: {{@loaderversion@}} and {{@mcversion@}}
  # This has to be the name the installer spits out
  # For Forge 1.12-: "forge-{{@mcversion@}}-{{@loaderversion@}}-universal.jar"
  # For Forge 1.13+: "forge-{{@mcversion@}}-{{@loaderversion@}}.jar"
  # For Fabric: "fabric-server-launch.jar"
  startFile: "forge-{{@mcversion@}}-{{@loaderversion@}}.jar"

  # This is the command how the server is supposed to be started
  # For <1.16 it should be
  #  - "-jar"
  #  - "{{@startFile@}}"
  #  - "nogui"
  # For >=1.17 it should be
  # - "@libraries/net/minecraftforge/forge/{{@mcversion@}}-{{@loaderversion@}}/{{@os@}}_args.txt"
  # - "nogui"
  startCommand:
    - "@libraries/net/minecraftforge/forge/{{@mcversion@}}-{{@loaderversion@}}/{{@os@}}_args.txt"
    - "nogui"

  # In case you have multiple javas installed you can add a absolute path to it here
  # The Path has to be enclosed in \" like in the example if it has spaces (or for safety just include them always.)
  # if the value is "", null, or ~ then 'java' from PATH is going to be used
  # Example: "\"C:/Program Files/Java/jre1.8.0_201/bin/java.exe\""
  # It also supports replacing with environment variables with \\\${ENV_VAR} e.g. \\\${JAVA_HOME}/bin/java.exe
  forcedJavaPath: ~

  # If you aren't sure what the java path is you can let serverstarter attempt to find the correct JVM
  # For this you need to have all available JVMs on the PATH
  # -> MC 1.12 to 1.16 requires java [8, 9, 10, 11]
  # -> MC 1.17 requires java [17]
  supportedJavaVersions: [17]

  # Java args that are supposed to be used when the server launches
  # keep in mind java args often need ' - ' in front of it to work, use clarifying parentheses to make sure it uses it correctly
  # Keep in mind that some arguments only work on JRE 1.8
  # reference: https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/
  javaArgs:
    - "-XX:+UseG1GC"
    - "-XX:+ParallelRefProcEnabled"
    - "-XX:MaxGCPauseMillis=200"
    - "-XX:+UnlockExperimentalVMOptions"
    - "-XX:+DisableExplicitGC"
    - "-XX:+AlwaysPreTouch"
    - "-XX:G1NewSizePercent=30"
    - "-XX:G1MaxNewSizePercent=40"
    - "-XX:G1HeapRegionSize=8M"
    - "-XX:G1ReservePercent=20"
    - "-XX:G1HeapWastePercent=5"
    - "-XX:G1MixedGCCountTarget=4"
    - "-XX:InitiatingHeapOccupancyPercent=15"
    - "-XX:G1MixedGCLiveThresholdPercent=90"
    - "-XX:G1RSetUpdatingPauseTimePercent=5"
    - "-XX:SurvivorRatio=32"
    - "-XX:+PerfDisableSharedMem"
    - "-XX:MaxTenuringThreshold=1"
    - "-Dfml.readTimeout=90"                        # servertimeout
    - "-Dfml.queryResult=confirm"                   # auto /fmlconfirm
END
)" > "server-setup-config.temp.yaml"