#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'ghcr.io/parkervcp/installers:debian'

# NOTES:
# Big thanks to Natalie on the PalWorld Modding Discord for already creating a working wine setup.

ATTRIBUTE_RESET="\e[0m"
COLOR_DEFAULT="\e[39m"
COLOR_GREEN="\e[32m"
COLOR_RED="\e[31m"

exit_and_message() {
  local exit_code=$1
  local message=( "${@:2}" )
  local color="${COLOR_DEFAULT}"

  if [[ "${exit_code}" == 1 ]]; then
    color="${COLOR_RED}"
  fi

  for m in "${message[@]}"; do
    echo -e "${ATTRIBUTE_RESET}${color}${m}${ATTRIBUTE_RESET}"
  done
  echo -e "${ATTRIBUTE_RESET}The last exit code was: \`${color}${exit_code}${ATTRIBUTE_RESET}'"

  # shellcheck disable=SC2086
  exit $exit_code
}

main_function() {
  ##
  #
  # Variables
  # STEAM_USER, STEAM_PASS, STEAM_AUTH - Steam user setup. If a user has 2fa enabled it will most likely fail due to timeout. Leave blank for anon install.
  # WINDOWS_INSTALL - if it's a windows server, you want to install set to 1
  # SRCDS_APPID - steam app id found here - https://developer.valvesoftware.com/wiki/Dedicated_Servers_List
  # SRCDS_BETAID - the beta id for the steam app.
  # SRCDS_BETAPASS - the beta access password for the steam app.
  # EXTRA_FLAGS - when a server has extra glas for things like beta installs or updates.
  # AUTO_UPDATE - auto update the server on start.
  # NEXUS_API_KEY - your personal api key for nexus mods to download the extra frills. (unused for now)
  # GITHUB_API_KEY - your personal github api key for downloading the latest release.
  # WINETRICKS_RUN - install extra winetricks packages.
  #
  ##
  #
  # Palworld Variables
  # MAX_PLAYERS - maximum number of players allowed on the server.
  # SERVER_NAME - the display name of the server.
  # SERVER_PASSWORD - the password for the server.
  # ADMIN_PASSWORD - the admin password for the server.
  # PUBLIC_IP - the public, external, ip of the server.
  # RCON_PORT - the rcon port of the server.
  # RCON_ENABLE - when the server starts, enable rcon. must be on.
  # ENABLE_ENEMY - turns off or on bEnableInvaderEnemy, can be used to slow download memory leaks. off should slow down the memory leaks.
  # SERVER_DESCRIPTION - the description of the server.
  #
  ##
  export DEBIAN_FRONTEND=noninteractive

  apt -y update
  dpkg --add-architecture i386
  apt -y --no-install-recommends install curl lib32gcc-s1 ca-certificates gnupg wget software-properties-common unzip gnupg2 ca-certificates curl git unzip zip tar jq wget python3 python3-yaml python3-requests python3-urllib3 lsof net-tools

  ## just in case someone removed the defaults.
  if [[ "${STEAM_USER}" == "" ]] || [[ "${STEAM_PASS}" == "" ]]; then
      echo -e "steam user is not set.\n"
      echo -e "Using anonymous user.\n"
      export STEAM_USER=anonymous
      export STEAM_PASS=""
      export STEAM_AUTH=""
  else
      echo -e "user set to ${STEAM_USER}"
  fi

  # Setup github downloader.
  cd "/mnt/server" || exit_and_message 1 "Failed to go to directory \`/mnt/server'"
  if [[ ! -f "/mnt/server/download_latest.py" ]]; then
    curl -sSL -o "/mnt/server/download_latest.py" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/managers/palworld/download_latest.py" || exit_and_message 1 "Failed to download file \`download_latest.py'"
  fi

  if [[ ! -f "/mnt/server/.env" ]]; then
    touch "/mnt/server/.env" || exit_and_message 1 "Failed to create file at \`/mnt/server/.env'"
  fi

  echo "${GITHUB_API_KEY}" > "/mnt/server/.env"

  install_palserver || exit_and_message 1 "Failed run function \`install_palserver'"
  rm "/mnt/server/.env" || exit_and_message 1 "Failed remove file at \`/mnt/server/.env'"

  ## install end
  echo -e "${COLOR_GREEN}------------------------------------------${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}Installation completed...                 ${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}------------------------------------------${ATTRIBUTE_RESET}"
}

install_palserver() {
  local WINDOWS_INSTALL_OPT=""
  local SRCDS_BETAID_OPT=""
  local SRCDS_BETAPASS_OPT=""
  local exit_code=-1
  ## download and install steamcmd
  cd /tmp || exit_and_message 1 "Failed to change directory to \`/tmp'"
  mkdir -p /mnt/server/steamcmd || exit_and_message 1 "Failed to make directory at \`/mnt/server/steamcmd'"
  curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz || exit_and_message 1 "Failed to download file \`steamcmd.tar.gz'"
  tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd || exit_and_message 1 "Failed to download file \`steamcmd.tar.gz'"
  mkdir -p /mnt/server/steamapps || exit_and_message 1 "Failed to create directory to \`/mnt/server/steamapps'" # Fix steamcmd disk write error when this folder is missing
  cd /mnt/server/steamcmd || exit_and_message 1 "Failed to change directory to \`/mnt/server/steamcmd'"

  # SteamCMD fails otherwise for some reason, even running as root.
  # This is changed at the end of the install process anyways.
  chown -R root:root /mnt || exit_and_message 1 "Failed to change permissions in directory \`/mnt'"
  export HOME=/mnt/server

  ## install game using steamcmd
  if [[ "${WINDOWS_INSTALL}" == "1" ]]; then
    WINDOWS_INSTALL_OPT="+@sSteamCmdForcePlatformType windows"
  fi
  if [[ -z ${SRCDS_BETAID} ]]; then
    SRCDS_BETAID_OPT="-beta ${SRCDS_BETAID}"
  fi
  if [[ -z ${SRCDS_BETAPASS} ]]; then
    SRCDS_BETAPASS_OPT="-beta ${SRCDS_BETAPASS}"
  fi
  eval "/mnt/server/steamcmd/steamcmd.sh +force_install_dir ${STEAMCMD_INSTALLDIR:-/mnt/server/PalServer} +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} ${WINDOWS_INSTALL_OPT} +app_update ${SRCDS_APPID} ${SRCDS_BETAID_OPT} ${SRCDS_BETAPASS_OPT} ${INSTALL_FLAGS} validate +quit" ## other flags may be needed depending on install. looking at you cs 1.6
  exit_code=$?
  if [[ "${exit_code}" != "0" ]]; then
    exit_and_message $exit_code "Failed to run command \`steamcmd.sh'"
  fi

  ## set up 32 bit libraries
  mkdir -p /mnt/server/.steam/sdk32
  cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

  ## set up 64 bit libraries
  mkdir -p /mnt/server/.steam/sdk64
  cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

  if [[ "${WINDOWS_INSTALL}" == "1" ]]; then
    ## add below your custom commands if needed
    ## copy template config file
    echo -e "Copy template config file into config folder!"

    if [[ -f "/mnt/server/PalServer/Pal/Saved/Config/WindowsServer/PalWorldSettings.ini" ]]; then
        echo -e "Config file already exists, backing up and overwriting with a new one"
        new_filename="PalWorldSettings_$(date +"%Y%m%d%H%M%S").ini"
        mv "/mnt/server/PalServer/Pal/Saved/Config/WindowsServer/PalWorldSettings.ini" "/mnt/server/PalServer/Pal/Saved/Config/WindowsServer/${new_filename}" || exit_and_message 1 "Failed to move file from \`PalWorldSettings.ini' to \`${new_filename}'"
        cp "/mnt/server/PalServer/DefaultPalWorldSettings.ini" "/mnt/server/PalServer/Pal/Saved/Config/WindowsServer/PalWorldSettings.ini" || exit_and_message 1 "Failed to copy file from \`DefaultPalWorldSettings.ini' to \`PalWorldSettings.ini'"
    else
        echo -e "Creating new config file"
        mkdir -p /mnt/server/PalServer/Pal/Saved/Config/WindowsServer || exit_and_message 1 "Failed to make dirwctory at \`/mnt/server/PalServer/Pal/Saved/Config/LinuxServer'"
        cp "/mnt/server/PalServer/DefaultPalWorldSettings.ini" "/mnt/server/PalServer/Pal/Saved/Config/WindowsServer/PalWorldSettings.ini" || exit_and_message 1 "Failed to copy file from \`DefaultPalWorldSettings.ini' to \`PalWorldSettings.ini'"
    fi

    cd "/mnt/server" || exit_and_message 1 "Failed to change directory to \`/mnt/server'"
    if [[ ! -f "/mnt/server/PalServer/PalworldServerConfigParser" ]]; then
      # Download self made replace tool
      echo -e "Downloading config parser aplication"
      curl -sSL -o "/mnt/server/PalServer/PalworldServerConfigParser" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://github.com/CuteNatalie/eggs/raw/master/game_eggs/steamcmd_servers/palworld/PalworldServerConfigParser-linux-amd64" || exit_and_message 1 "Failed to download file \`PalworldServerConfigParser'"
      chmod +x "/mnt/server/PalServer/PalworldServerConfigParser" || exit_and_message 1 "Failed to change permissions in directory \`/mnt/server/PalworldServerConfigParser'"
    fi
  fi

  # Check for Modding Framework files and install if needed
  if [[ ! -f "/mnt/server/PalServer/Pal/Binaries/Win64/winmm.dll" ]]; then
    # Setup windows
    cd /tmp || exit_and_message 1 "Failed to change directory to \`/tmp'"
    curl -sSL -o "winmm.zip" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/game_eggs/steamcmd_servers/palworld/binaries/winmm.zip" || exit_and_message 1 "Failed to download file \`winmm.zip'"
    curl -sSL -o "ue4ss.zip" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://github.com/UE4SS-RE/RE-UE4SS/releases/download/v3.0.0/UE4SS_v3.0.0.zip" || exit_and_message 1 "Failed to download file \`ue4ss.zip'"
    unzip -o winmm.zip -d /mnt/server/PalServer/Pal/Binaries/Win64 || exit_and_message 1 "Failed to unzip file \`winmm.zip'"
    rm winmm.zip || exit_and_message 1 "Failed to remove file \`winmm.zip'"
    unzip -o ue4ss.zip -d /mnt/server/PalServer/Pal/Binaries/Win64 || exit_and_message 1 "Failed to unzip file \`ue4ss.zip'"
    rm ue4ss.zip || exit_and_message 1 "Failed to remove file \`ue4ss.zip'"
    cd /mnt/server || exit_and_message 1 "Failed to change directory to \`/mnt/server'"
  fi

  if [[ ! -f "/mnt/server/RunPalServer.sh" ]]; then
    curl -sSL -o "/mnt/server/RunPalServer.sh" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/game_eggs/steamcmd_servers/palworld/w-frills/RunPalServer.sh" || exit_and_message 1 "Failed to download file \`RunPalServer.sh'"
  fi
  chmod +x /mnt/server/RunPalServer.sh || exit_and_message 1 "Failed to change permissions in directory \`/mnt/server/RunPalServer.sh'"

  ## install end
  echo -e "${COLOR_GREEN}------------------------------------------------------${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}PalServer - Installation completed...                 ${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}------------------------------------------------------${ATTRIBUTE_RESET}"
}

main_function 2>&1 | tee /mnt/server/install.log
