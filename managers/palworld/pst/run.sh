#!/bin/bash

log_file="/home/container/pst.log"
backup_log_file="/home/container/pst.2.log"

if [ -f "${log_file}" ]; then
  mv "${log_file}" "${backup_log_file}"
fi

exec &> >(tee -a "${log_file}")

current_script=$(echo "\"$0\"" | xargs readlink -f)
script_directory=$(dirname "${current_script}")

pst_exit_code=-1

main_function() {
  cd "${script_directory}" || exit 1
  python3 "${script_directory}/setup_config.py" --rcon_address "${INTERNAL_IP}" --io "${script_directory}/config.yaml"

  "${script_directory}/pst" &
  pst_exit_code=$?

  echo -e "Stopped"
}

dt=$(date '+%d/%m/%Y %H:%M:%S');
echo -e "\e[34m${dt}\e[39m"
main_function 2>&1
dt=$(date '+%d/%m/%Y %H:%M:%S');
echo -e "\e[34m${dt}\e[39m"
exit $pst_exit_code
