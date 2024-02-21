#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'ghcr.io/parkervcp/installers:debian'

##
#
# Variables
# STEAM_USER, STEAM_PASS, STEAM_AUTH - Steam user setup. If a user has 2fa enabled it will most likely fail due to timeout. Leave blank for anon install.
# WINDOWS_INSTALL - if it's a windows server you want to install set to 1
# SRCDS_APPID - steam app id found here - https://developer.valvesoftware.com/wiki/Dedicated_Servers_List
# SRCDS_BETAID - beta branch of a steam app. Leave blank to install normal branch
# SRCDS_BETAPASS - password for a beta branch should one be required during private or closed testing phases.. Leave blank for no password.
# INSTALL_FLAGS - Any additional SteamCMD  flags to pass during install.. Keep in mind that steamcmd auto update process in the docker image might overwrite or ignore these when it performs update on server boot.
# AUTO_UPDATE - Adding this variable to the egg allows disabling or enabling automated updates on boot. Boolean value. 0 to disable and 1 to enable.
#
 ##

# Install packages. Default packages below are not required if using our existing install image thus speeding up the install process.
apt -y update
apt -y --no-install-recommends install curl lib32gcc-s1 ca-certificates

## just in case someone removed the defaults.
if [[ "${STEAM_USER}" == "" ]] || [[ "${STEAM_PASS}" == "" ]]; then
    echo -e "steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

## download and install steamcmd
cd /tmp || exit 1
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
mkdir -p /mnt/server/steamapps # Fix steamcmd disk write error when this folder is missing
cd /mnt/server/steamcmd || exit 1

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
export HOME=/mnt/server

if [[ "${WINDOWS_INSTALL}" == "1" ]]; then
    WINDOWS_INSTALL_OPT="+@sSteamCmdForcePlatformType windows"
fi
if [[ -z ${SRCDS_BETAID} ]]; then
    SRCDS_BETAID_OPT="-beta ${SRCDS_BETAID}"
fi
if [[ -z ${SRCDS_BETAPASS} ]]; then
    SRCDS_BETAPASS_OPT="-beta ${SRCDS_BETAPASS}"
fi

## install game using steamcmd
eval "./steamcmd.sh +force_install_dir ${STEAMCMD_INSTALLDIR:-/mnt/server} +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} ${WINDOWS_INSTALL_OPT} +app_update ${SRCDS_APPID} ${SRCDS_BETAID_OPT} ${SRCDS_BETAPASS_OPT} ${INSTALL_FLAGS} validate +quit" ## other flags may be needed depending on install. looking at you cs 1.6
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
