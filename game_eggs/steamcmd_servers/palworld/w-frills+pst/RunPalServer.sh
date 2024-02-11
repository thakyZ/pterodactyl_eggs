#!/bin/bash

UE_TRUE_SCRIPT_NAME=$(echo "\"$0\"" | xargs readlink -f)
UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")

pst_exit_code=-1
pal_exit_code=-1
exit_code=-1

load_pst() {
  "${UE_PROJECT_ROOT}/PST/run.sh"
  pst_exit_code=$?
  echo -e "PST exited with code ${pst_exit_code}";
}

main_function() {
  if [[ "${WINE}" == "0" ]]; then
    load_pst & "${UE_TRUE_SCRIPT_NAME}/PalServer.sh"
    pal_exit_code=$?
  else
    cd "$UE_PROJECT_ROOT/PalServer/Pal/Binaries/Win64" || (echo "Failed to go to binaries path." && pal_exit_code=1 && return)
    echo -e "pwd=$(pwd)"
    chmod +x "./PalServer-Win64-Test-Cmd.exe" || (echo "Failed to chmod excutable." && pal_exit_code=1 && return)
    export WINEDLLOVERRIDES="${WINEDLLOVERRIDES},wmapi=n,b"
    echo -e "WINEDLLOVERRIDES=\"${WINEDLLOVERRIDES}\""
    if [[ "${XVFB}" == "0" ]]; then
      load_pst & wine "./PalServer-Win64-Test-Cmd.exe" Pal EpicApp=PalServer -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -publicip=${PUBLIC_IP} -port=${SERVER_PORT} -publicport=${SERVER_PORT} -servername="${SERVER_NAME}" -players=${MAX_PLAYERS} $(if [ -n "${SERVER_PASSWORD}" ]; then echo "-serverpassword=\"${SERVER_PASSWORD}\""; fi) -adminpassword="${ADMIN_PASSWORD}"
      pal_exit_code=$?
    else
      load_pst & xvfb-run --auto-servernum wine "./PalServer-Win64-Test-Cmd.exe" Pal EpicApp=PalServer -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -publicip=${PUBLIC_IP} -port=${SERVER_PORT} -publicport=${SERVER_PORT} -servername="${SERVER_NAME}" -players=${MAX_PLAYERS} $(if [ -n "${SERVER_PASSWORD}" ]; then echo "-serverpassword=\"${SERVER_PASSWORD}\""; fi) -adminpassword="${ADMIN_PASSWORD}"
      pal_exit_code=$?
    fi
  fi
}

main_function >&2
echo -e "Exited with exit code: ${pal_exit_code}"
exit $pal_exit_code
