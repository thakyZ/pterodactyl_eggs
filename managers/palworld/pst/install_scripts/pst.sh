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
  #
  ##
  #
  # Palworld Server Tools Variables
  # PST_ENABLE_TLS - when the server starts, enable tls.
  # PST_CERT_PATH - the file path to the tls certificate.
  # PST_KEY_PATH - the file path to the tls private key.
  # PST_RCON_TIMEOUT - recommended <= 5
  # PST_RCON_SYNC_INTERVAL - interval for syncing online player status with rcon service, in seconds.
  # PST_SAV_FILE_PATH - the path to the save file folder. the folder must contain a file called `Level.sav`.
  # PST_SAV_CLI - the path to the `sav_cli` command for palworld server tools. Usually is in the same directory as the `pst` command.
  # PST_SAV_SYNC_INTERVAL - interval for syncing data from save file, in seconds, recommended >= 120
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

  install_pst || exit_and_message 1 "Failed run function \`install_pst'"
  rm "/mnt/server/.env" || exit_and_message 1 "Failed remove file at \`/mnt/server/.env'"

  ## install end
  echo -e "${COLOR_GREEN}------------------------------------------${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}Installation completed...                 ${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}------------------------------------------${ATTRIBUTE_RESET}"
}

install_pst() {
  local exit_code=-1
  if [[ ! -d "/mnt/server/PST" ]]; then
    mkdir "/mnt/server/PST" || exit_and_message 1 "Failed to make directory \`/mnt/server/PST'"
  fi

  if [[ ! -d "/mnt/server/PST/.temp" ]]; then
    mkdir "/mnt/server/PST/.temp" || exit_and_message 1 "Failed to make directory \`/mnt/server/PST/.temp'"
  fi

  python3 "/mnt/server/download_latest.py" -o "/mnt/server/PST/.temp" --repo "gh:zaigie/palworld-server-tool" --file "r'pst-agent_v[\d\.]+_linux_x86_64'" "r'pst_v[\d\.]+_linux_x86_64.tar.gz'"
  exit_code=$?
  if [[ "${exit_code}" != "0" ]]; then
    exit_and_message $exit_code "Failed to download files with \`download_latest.py'"
  fi

  for i in /mnt/server/PST/.temp/*.tar.gz; do
    tar -C "/mnt/server/PST/" -xvf "${i}" || exit_and_message 1 "Failed untar file at \`${i}'"
    rm "${i}" || exit_and_message 1 "Failed remove file at \`${i}'"
  done

  for i in /mnt/server/PST/linux_x86_64/*; do
    mv "${i}" "/mnt/server/PST/" || exit_and_message 1 "Failed move file from \`${i}' to \`/mnt/server/PST/'"
  done
  rm -r "/mnt/server/PST/linux_x86_64/" || exit_and_message 1 "Failed remove directory at \`/mnt/server/PST/linux_x86_64/'"

  for i in /mnt/server/PST/.temp/*; do
    if [[ "${i}" == "*pst-agent*" ]]; then
      mv "${i}" "/mnt/server/PST/pst-agent" || exit_and_message 1 "Failed move file from \`${i}' to \`/mnt/server/PST/pst-agent'"
    fi
  done

  if [[ "${exit_code}" == "0" ]]; then
    rm -r "/mnt/server/PST/.temp/" || exit_and_message 1 "Failed remove file at \`/mnt/server/PST/.temp/'"
  fi
p
  if [[ ! -f "/mnt/server/PST/config.yaml" ]]; then
    touch "/mnt/server/PST/config.yaml" || exit_and_message 1 "Failed to create file at \`/mnt/server/PST/config.yaml'"
  fi

  if [[ ! -f "/mnt/server/PST/setup_config.py" ]]; then
    curl -sSL -o "/mnt/server/PST/setup_config.py" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/managers/palworld/pst/setup_config.py" || exit_and_message 1 "Failed to download file \`setup_config.py'"
  fi

  command="python3 \"/mnt/server/PST/setup_config.py\" --web_password \"${PASSWORD}\" --web_tls \"${ENABLE_TLS:-false}\""
  if [[ "${ENABLE_TLS:-false}" == "true" ]]; then
   command="${command} --web_cert_path \"${CERT_PATH}\" --web_key_path \"${KEY_PATH}\""
  fi
  command="${command} --rcon_address \"${INTERNAL_IP:-127.0.0.1}\" --rcon_port \"${RCON_PORT:-25575}\" --rcon_timeout"
  command="${command} \"${PST_RCON_TIMEOUT:-5}\" --rcon_sync_interval \"${PST_RCON_SYNC_INTERVAL:-60}\" --rcon_password"
  command="${command} \"${RCON_PASSWORD}\" --save_path \"${PST_SAV_FILE_PATH:-/path/to/you/Level.sav}\" --save_decode_path"
  command="${command} \"${PST_SAV_CLI:-/path/to/your/sav_cli}\" --save_sync_interval \"${PST_SAV_SYNC_INTERVAL:-120}\""
  command="${command} --io \"/mnt/server/PST/config.yaml\""
  eval "${command}" || exit_and_message 1 "Failed to parse config file."

  if [[ ! -f "/mnt/server/PST/run.sh" ]]; then
    curl -sSL -o "/mnt/server/PST/run.sh" -H "Authorization: Bearer ${GITHUB_API_KEY}" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/managers/palworld/pst/run.sh" || exit_and_message 1 "Failed to download file \`run.sh'."
  fi
  chmod +x /mnt/server/PST/run.sh || exit_and_message 1 "Failed to set permissions on file \`run.sh'."

  ## install end
  echo -e "${COLOR_GREEN}-------------------------------------------------------------${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}Pal Server Tools - Installation completed...                 ${ATTRIBUTE_RESET}"
  echo -e "${COLOR_GREEN}-------------------------------------------------------------${ATTRIBUTE_RESET}"
}

main_function 2>&1 | tee /mnt/server/install.log
