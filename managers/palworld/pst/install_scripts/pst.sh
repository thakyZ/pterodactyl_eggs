#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'debian:bookworm-slim'

main_function() {
  ##
  #
  # Variables
  # STEAM_USER, STEAM_PASS, STEAM_AUTH - Steam user setup. If a user has 2fa enabled it will most likely fail due to timeout. Leave blank for anon install.
  # WINDOWS_INSTALL - if it's a windows server you want to install set to 1
  # SRCDS_APPID - steam app id ffound here - https://developer.valvesoftware.com/wiki/Dedicated_Servers_List
  # EXTRA_FLAGS - when a server has extra glas for things like beta installs or updates.
  #
  ##
  apt update -y
  apt install -y --no-install-recommends ca-certificates curl git unzip zip tar jq wget python3 python3-yaml python3-requests python3-urllib3 lsof net-tools

  cd "/mnt/server" || exit 1
  if [[ ! -f "/mnt/server/download_latest.py" ]]; then
    wget -q -O "/mnt/server/download_latest.py" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/managers/palworld/download_latest.py"
  fi

  if [[ ! -f "/mnt/server/.env" ]]; then
    touch "/mnt/server/.env"
  fi

  echo "${GITHUB_API_KEY}" > "/mnt/server/.env"

  if [[ ! -d "/mnt/server/.temp" ]]; then
    mkdir "/mnt/server/.temp"
  fi

  python3 download_latest.py -o "/mnt/server/.temp" --repo "gh:zaigie/palworld-server-tool" --file "r'pst-agent_v[\d\.]+_linux_x86_64'" "r'pst_v[\d\.]+_linux_x86_64.tar.gz'"
  exit_code=$?
  echo "LastExitCode ${exit_code}"

  for i in /mnt/server/.temp/*.tar.gz; do
    tar -C "/mnt/server" -xvf "${i}" || exit 1
    rm "${i}"
  done

  for i in /mnt/server/linux_x86_64/*; do
    mv "${i}" "/mnt/server/pst-agent"
  done
  rm -r "/mnt/server/linux_x86_64/"

  for i in /mnt/server/.temp/*; do
    if [[ "${i}" == "*pst-agent*" ]]; then
      mv "${i}" "/mnt/server/pst-agent"
    fi
  done

  if [[ "${exit_code}" == "0" ]]; then
    rm "/mnt/server/.env"
    rm -r "/mnt/server/.temp/"
  fi

  if [[ ! -f "/mnt/server/config.yaml" ]]; then
    touch "/mnt/server/config.yaml"
  fi
  if [[ ! -f "/mnt/server/setup_config.py" ]]; then
    wget -q -O "/mnt/server/setup_config.py" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/managers/palworld/pst/setup_config.py"
  fi
  command="python3 \"/mnt/server/setup_config.py\" --web_password \"${PASSWORD}\" --web_tls \"${ENABLE_TLS:-false}\""
  if [[ "${ENABLE_TLS:-false}" == "true" ]]; then
   command="${command} --web_cert_path \"${CERT_PATH}\" --web_key_path \"${KEY_PATH}\""
  fi
  command="${command} --rcon_address \"${INTERNAL_IP:-127.0.0.1}\" --rcon_port \"${RCON_PORT:-25575}\" --rcon_timeout \"${RCON_TIMEOUT:-5}\" --rcon_sync_interval \"${RCON_SYNC_INTERVAL:-60}\""
  command="${command} --rcon_password \"${RCON_PASSWORD}\""
  command="${command} --save_path \"${SAV_FILE_PATH:-/path/to/you/Level.sav}\" --save_decode_path \"${SAV_CLI:-/path/to/your/sav_cli}\" --save_sync_interval \"${SAV_SYNC_INTERVAL:-120}\""
  command="${command} --io \"/mnt/server/config.yaml\""
  eval "${command}"

  if [[ ! -f "/mnt/server/run.sh" ]]; then
    wget -q -O "/mnt/server/run.sh" "https://raw.githubusercontent.com/thakyZ/pterodactyl_eggs/master/managers/palworld/pst/run.sh"
  fi
  chmod +x /mnt/server/run.sh

  ## install end
  echo "-----------------------------------------"
  echo "Installation completed..."
  echo "-----------------------------------------"

  lsof -i :11000 2>&1
  lsof -i :11001 2>&1
  lsof -i :11002 2>&1
  lsof -i :11003 2>&1
  ifconfig 2>&1
}

main_function 2>&1 | tee /mnt/server/install.log