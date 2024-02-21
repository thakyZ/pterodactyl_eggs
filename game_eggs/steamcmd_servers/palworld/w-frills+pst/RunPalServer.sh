#!/bin/bash

log_file="/home/container/palserver.log"
backup_log_file="/home/container/palserver.2.log"

if [ -f "${log_file}" ]; then
  mv "${log_file}" "${backup_log_file}"
fi

exec &> >(tee -a "${log_file}")

current_script=$(echo "\"$0\"" | xargs readlink -f)
script_directory=$(dirname "${current_script}")

pst_exit_code=-1
pal_exit_code=-1

load_pst() {
  "${script_directory}/PST/run.sh"
  pst_exit_code=$?
  echo -e "PST exited with code ${pst_exit_code}";
}

main_function() {
  cd "${script_directory}/PalServer/Pal/Binaries/Win64" || (echo "Failed to go to binaries path." && pal_exit_code=1 && return)
  chmod +x "${script_directory}/PalServer/Pal/Binaries/Win64/PalServer-Win64-Test.exe" || (echo "Failed to chmod excutable." && pal_exit_code=1 && return)
  load_pst & proton run "${script_directory}/PalServer/Pal/Binaries/Win64/PalServer-Win64-Test.exe" EpicApp=PalServer -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -publicip=${PUBLIC_IP} -port=${SERVER_PORT} -publicport=${SERVER_PORT} -servername="${SERVER_NAME}" -players=${MAX_PLAYERS} $(if [ -n "$SERVER_PASSWORD" ]; then echo "-serverpassword=\"${SERVER_PASSWORD}\""; fi) -adminpassword="${ADMIN_PASSWORD}"
  pal_exit_code=$?

  echo -e "Exited with exit code: ${pal_exit_code}"
}

dt=$(date '+%d/%m/%Y %H:%M:%S');
echo -e "\e[34m${dt}\e[39m"
main_function >&2
dt=$(date '+%d/%m/%Y %H:%M:%S');
echo -e "\e[34m${dt}\e[39m"
exit $pal_exit_code