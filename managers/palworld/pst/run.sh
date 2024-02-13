#!/bin/bash
current_script=$(echo "\"$0\"" | xargs readlink -f)
script_directory=$(dirname "${current_script}")

main_function() {

  python3 "${script_directory}/setup_config.py" --rcon_address "${INTERNAL_IP}" --io "${script_directory}/config.yaml"

  "${script_directory}/pst" &
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

{ main_function > "${script_directory}/pst.log"; } 2>&1
