#!/bin/bash
current_script=$(echo "\"$0\"" | xargs readlink -f)
script_directory=$(dirname "${current_script}")

main_function() {
  cd "${script_directory}" || exit 1
  python3 "${script_directory}/setup_config.py" --rcon_address "${INTERNAL_IP}" --io "${script_directory}/config.yaml"

  "${script_directory}/pst-agent" --port "${PST_AGENT_PORT}" --file "${PST_SAV_FILE_PATH}/Level.sav" &
  sleep 100
  pid=$(pgrep pst)

  if [[ "${pid:-false}" != "false" ]]; then
    echo -e "Started"
  fi

  while [[ "${pid:-false}" != "false" ]]; do
    pid=$(pgrep pst)
    sleep 5000
  done

  echo -e "Ended"
}

# { main_function 2>&1; } | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" > "${script_directory}/pst.log"
main_function &> "${script_directory}/pst.log"
