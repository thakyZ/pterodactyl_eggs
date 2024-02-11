#!/bin/bash

UE_TRUE_SCRIPT_NAME=$(echo "\"$0\"" | xargs readlink -f)
UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")

pal_exit_code=-1
exit_code=-1

main_function() {
  if [[ "${WINE}" == "0" ]]; then
    /home/container/PalServer.sh
    pal_exit_code=$?
  else
    UE_TRUE_SCRIPT_NAME=$(echo "\"$0\"" | xargs readlink -f)
    UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")
    cd "$UE_PROJECT_ROOT/PalServer/Pal/Binaries/Win64" || (echo "Failed to go to binaries path." && return 1)
    chmod +x "./PalServer-Win64-Test-Cmd.exe" || (echo "Failed to chmod excutable." && return 1)
    export WINEDLLOVERRIDES="${WINEDLLOVERRIDES},wmapi=n,b"
    echo -e "WINEDLLOVERRIDES=\"${WINEDLLOVERRIDES}\"" >&2
    if [[ "${XVFB}" == "0" ]]; then
      wine "./PalServer-Win64-Test-Cmd.exe" Pal EpicApp=PalServer -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -publicip=${PUBLIC_IP} -port=${SERVER_PORT} -publicport=${SERVER_PORT} -servername="${SERVER_NAME}" -players=${MAX_PLAYERS} $(if [ -n "${SERVER_PASSWORD}" ]; then echo "-serverpassword=\"${SERVER_PASSWORD}\""; fi) -adminpassword="${ADMIN_PASSWORD}"
      pal_exit_code=$?
    else
      xvfb-run --auto-servernum wine "./PalServer-Win64-Test-Cmd.exe" Pal EpicApp=PalServer -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -publicip=${PUBLIC_IP} -port=${SERVER_PORT} -publicport=${SERVER_PORT} -servername="${SERVER_NAME}" -players=${MAX_PLAYERS} $(if [ -n "${SERVER_PASSWORD}" ]; then echo "-serverpassword=\"${SERVER_PASSWORD}\""; fi) -adminpassword="${ADMIN_PASSWORD}"
      pal_exit_code=$?
    fi
  fi
  return $pal_exit_code
}

exit_code=$(main_function)
echo -e "Exited with exit code: ${exit_code}"
exit $exit_code
