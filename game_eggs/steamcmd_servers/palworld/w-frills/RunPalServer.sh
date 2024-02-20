#!/bin/bash

UE_TRUE_SCRIPT_NAME=$(echo "\"$0\"" | xargs readlink -f)
UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")

pst_exit_code=-1
pal_exit_code=-1

main_function() {
  if [[ "${WINE}" == "0" ]]; then
    "${UE_TRUE_SCRIPT_NAME}/PalServer.sh"
    pal_exit_code=$?
  else
    cd "${UE_PROJECT_ROOT}/PalServer/Pal/Binaries/Win64" || (echo "Failed to go to binaries path." && pal_exit_code=1 && return)
    chmod +x "${UE_PROJECT_ROOT}/PalServer/Pal/Binaries/Win64/PalServer-Win64-Test.exe" || (echo "Failed to chmod excutable." && pal_exit_code=1 && return)
    proton run "${UE_PROJECT_ROOT}/PalServer/Pal/Binaries/Win64/PalServer-Win64-Test.exe" EpicApp=PalServer -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -publicip=${PUBLIC_IP} -port=${SERVER_PORT} -publicport=${SERVER_PORT} -servername="${SERVER_NAME}" -players=${MAX_PLAYERS} $(if [ -n "$SERVER_PASSWORD" ]; then echo "-serverpassword=\"${SERVER_PASSWORD}\""; fi) -adminpassword="${ADMIN_PASSWORD}"
    pal_exit_code=$?
  fi
}

main_function >&2 | tee "/home/container/palserver.log"
echo -e "Exited with exit code: ${pal_exit_code}"
exit $pal_exit_code
