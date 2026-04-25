#!/bin/bash

VALIDATE_CMD=""
if [[ "${VALIDATE}" == "true" ]]; then
    VALIDATE_CMD="validate"
fi

LOGIN_CREDENTIALS="anonymous"
if [[ -n "${STEAM_USERNAME}" && "${STEAM_USERNAME}" != "template" ]] && \
   [[ -n "${STEAM_PASSWORD}" && "${STEAM_PASSWORD}" != "template" ]]; then    
    LOGIN_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"
fi

ARK_BIN="${SERVER_DIR}/ShooterGame/Binaries/Win64/ArkAscendedServer.exe"
ARK_DIR="${SERVER_DIR}/ShooterGame/Binaries/Win64"
ARK_RUN_STRING="${MAP}?listen?SessionName=${SERVER_NAME}?ServerPassword=${SRV_PWD}?ServerAdminPassword=${SRV_ADMIN_PWD} ${GAME_PARAMS} ${GAME_PARAMS_EXTRA}"

if [ ${DEBUG} -eq 1 ]; then
    echo -e "${YELLOW}DEBUG: Starting server with the following environment variables:${NC}"
    env | sort
    # custom params
    echo -e "${YELLOW}DEBUG: Normalized variables:${NC}"
    echo "MAP: ${MAP}"
    echo "GAME_ID: ${GAME_ID}"
    echo "SERVER_NAME: ${SERVER_NAME}"
    echo "SRV_PWD: ${SRV_PWD}"
    echo "SRV_ADMIN_PWD: ${SRV_ADMIN_PWD}"
    echo "VALIDATE_CMD: ${VALIDATE_CMD}"
    echo "LOGIN_CREDENTIALS: ${LOGIN_CREDENTIALS}"
    echo "SERVER_DIR: ${SERVER_DIR}"
    echo "STEAMCMD_DIR: ${STEAMCMD_DIR}"
    ARK_RUN_STRING="Astraeos_WP?listen?SessionName=ToolsTest?ServerPassword=Tools123?ServerAdminPassword=AdminTools123  -port=7766 -QueryPort=27001 -WinLiveMaxPlayers=20 -server -log -NoBattlEye -clusterid=toolscluster -clusterDirOverride=/serverdata/serverfiles/clusterfiles -mods=947733,934401,947033,942024,1299726,1188679,930436"
fi

if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "SteamCMD not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${LOGIN_CREDENTIALS} \
    +quit

echo "---Update Server---"
echo "---Validating installation---"
    ${STEAMCMD_DIR}/steamcmd.sh \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir ${SERVER_DIR} \
    +login ${LOGIN_CREDENTIALS} \
    +app_update ${GAME_ID} ${VALIDATE_CMD} \
    +quit

export WINEARCH=win64
export WINEPREFIX=/serverdata/serverfiles/WINE64
export WINEDEBUG=-all

echo "---Checking if WINE workdirectory is present---"
if [ ! -d ${SERVER_DIR}/WINE64 ]; then
  echo "---WINE workdirectory not found, creating please wait...---"
  mkdir ${SERVER_DIR}/WINE64
else
  echo "---WINE workdirectory found---"
fi
echo "---Checking if WINE is properly installed---"
if [ ! -d ${SERVER_DIR}/WINE64/drive_c/windows ]; then
  echo "---Setting up WINE---"
  cd ${SERVER_DIR}
  winecfg > /dev/null 2>&1
  sleep 15
else
  echo "---WINE properly set up---"
fi
echo "---Prepare Server---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
if [ ! -f ${SERVER_DIR}/ShooterGame/Binaries/Win64/ArkAscendedServer.exe ]; then
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
else
  cd ${SERVER_DIR}/ShooterGame/Binaries/Win64
  xvfb-run --auto-servernum --server-args='-screen 0 640x480x24:32' wine ArkAscendedServer.exe ${ARK_RUN_STRING} &
  echo "Waiting for logs..."
  ATTEMPT=0
  sleep 2
  while [ ! -f "${SERVER_DIR}/ShooterGame/Saved/Logs/ShooterGame.log" ]; do
    ((ATTEMPT++))
    if [ $ATTEMPT -eq 10 ]; then
      echo "No log files found after 20 seconds, putting container into sleep mode!"
      sleep infinity
    else
      sleep 2
      echo "Waiting for logs..."
    fi
  done
  # /opt/scripts/start-watchdog.sh &
  tail -n 9999 -f ${SERVER_DIR}/ShooterGame/Saved/Logs/ShooterGame.log
fi