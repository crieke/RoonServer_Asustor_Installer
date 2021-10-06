#!/bin/sh

## VARIABLES
APP_NAME="RoonServer"
APKG_PKG_DIR="/usr/local/AppCentral/RoonServer"
ROON_FILENAME="RoonServer_linuxx64.tar.bz2"
ROON_PKG_URL="https://download.roonlabs.com/builds/$ROON_FILENAME"
WEBUI_STATUS="$APKG_PKG_DIR/web-status"
LOCKFILE="/tmp/.RoonServer-webui.lock"
ROON_TMP_DIR="${APKG_PKG_DIR}/tmp"
ROON_WWW_DIR="/usr/local/www/RoonServer"
ROON_ID_DIR="${APKG_PKG_DIR}/id"
ROON_LOG_FILE="/dev/null"
ROON_PID=$(ps aux | grep "${APKG_PKG_DIR}/RoonServer/start.sh" | grep -v grep | awk '{print $1}')

if [ -f $LOCKFILE ]; then
    exit
fi

lockfile() {
    case $1 in
        create)
            if [ ! -f $LOCKFILE ]; then
            echo "Creating Lockfile."
                touch "${LOCKFILE}"
            else
                echo "WebUI_Helper-Process is already running..."
                exit 1
            fi
        ;;
        remove)
            echo "Removing Lockfile."
            rm -f "${LOCKFILE}"
        ;;
        *)
            echo "Usage: $0 {create|remove|check}"
    esac
}

lockfile create

getInfo () {
    # Getting system info for debugging purpose
    ADM_VER=`confutil -get /etc/nas.conf Basic Version`
    ARCH=$(uname -m)
    MODEL=`confutil -get /etc/nas.conf Basic Model`
    NAS_SERIAL=`confutil -get /etc/nas.conf Basic SerialNumber`
    NAS_MEMTOTAL=`awk '/MemTotal/ {print $2}' /proc/meminfo`
    NAS_MEMFREE=`awk '/MemFree/ {print $2}' /proc/meminfo`
    APP_VERSION=$(cat ${APKG_PKG_DIR}/CONTROL/config.json | grep "version" | tr \" " " |  awk '{print $3}')
    ROON_VERSION=`[ -f "${APKG_PKG_DIR}/RoonServer/VERSION" ] && cat "${APKG_PKG_DIR}/RoonServer/VERSION" || echo "not available"`
    ROON_TMP_DIR="${APKG_PKG_DIR}/tmp"
    ROON_WEBACTIONS_PIDFILE="/var/run/RoonServer_webactions.pid"
    WATCH_PID="$([ -f "$ROON_WEBACTIONS_PIDFILE" ] && cat ${ROON_WEBACTIONS_PIDFILE})"
    NAS_DEF_IF=$(route | grep default | awk '{print $8}')
    NAS_IF_MTU=$(cat /sys/class/net/${NAS_DEF_IF}/mtu)
    NAS_HOSTNAME=`confutil -get /etc/nas.conf Basic Hostname`
    if [ -f ${APKG_PKG_DIR}/etc/RoonServer.conf ]; then
       ROON_DATABASE_DIR=`awk -F "= " '/DB_Path/ {print $2}' ${APKG_PKG_DIR}/etc/RoonServer.conf`
       ROON_DATAROOT="${ROON_DATABASE_DIR}/RoonOnNAS"
       ROON_DATABASE_DIR_FS=`df -T "${ROON_DATABASE_DIR}" | grep "^/dev" | awk '{print $2}'`
       ROON_DATABASE_DIR_FREE_INODES=`df -PThi "${ROON_DATAROOT}" | awk '{print $5}' | tail -1`
       ROON_FFMPEG_DIR="${ROON_DATAROOT}/bin"
    fi

}

RoonOnNAS_folderCheck ()
{
  if [ -d "${ROON_DATABASE_DIR}" ]; then
    [ -d "${ROON_DATAROOT}" ] || mkdir "${ROON_DATAROOT}"
    [ -d "${ROON_FFMPEG_DIR}" ] || mkdir "${ROON_FFMPEG_DIR}"
  fi
}

## Log Function
echolog () {
	TIMESTAMP=$(date +%d.%m.%y-%H:%M:%S)
	if [[ $# == 2 ]]; then
		PARAMETER1=$1
		PARAMETER2=$2
		echo -e "${ST_COLOR}${TIMESTAMP}${REG_COLOR} --- ${HL_COLOR}${PARAMETER1}:${REG_COLOR} ${PARAMETER2}"
		echo "${TIMESTAMP} --- ${PARAMETER1}: ${PARAMETER2}" >> $ROON_LOG_FILE
	elif [[ $# == 1 ]]; then
		PARAMETER1=$1
		echo -e "${ST_COLOR}${TIMESTAMP}${REG_COLOR} --- ${PARAMETER1}"
		echo "${TIMESTAMP} --- ${PARAMETER1}" >> $ROON_LOG_FILE
	else
		echo -e "The echolog function requires 1 or 2 parameters."
	fi
}

showInfo ()
{
   ## Echoing System Info
   echolog "ROON_DATAROOT" "${ROON_DATAROOT} - [`[ -d \"${ROON_DATAROOT}\" ] && echo \"available\" || echo \"not available\"`]"
   echolog "ROON_DATABASE_DIR_FS" "${ROON_DATABASE_DIR_FS}"
   echolog "ROON_ID_DIR" "$ROON_ID_DIR - [`[ -d \"$ROON_ID_DIR\" ] && echo \"available\" || echo \"not available\"`]"
   echolog "Free Inodes" "${ROON_DATABASE_DIR_FREE_INODES}"
   echolog "ROON_DIR" "${APKG_PKG_DIR}"
   echolog "Model" "${MODEL}"
   echolog "Asustor Serial" "${NAS_SERIAL}"
   echolog "Architecture" "${ARCH}"
   echolog "Total Memory" "${NAS_MEMTOTAL}"
   echolog "Available Memory" "${NAS_MEMFREE}"
   echolog "ADM Version" "${ADM_VER}"
   echolog "PKG Version" "${APP_VERSION}"
   echolog "Hostname" "${NAS_HOSTNAME}"
   echolog "Default Interface" "${NAS_DEF_IF}"
   echolog "MTU" "${NAS_IF_MTU}"
   echolog "Watch PID" "${WATCH_PID}"
}

startRoonServer() {
    echo "start" > $LOCKFILE
    RoonOnNAS_folderCheck
    getInfo
    if [ ! -z "$ROON_PID" ] && kill -s 0 ${ROON_PID}; then
        if [ -d "/proc/${ROON_PID}" ]; then
            echolog "RoonServer already running."
            return 1
        fi
    fi

    echolog "Starting RoonServer"
    showInfo
    if [ "$ROON_DATABASE_DIR" != "" ] && [ -d "$ROON_DATAROOT" ]; then

      ## Fix missing executable permission for ffmpeg
      [ -f "${ROON_FFMPEG_DIR}/ffmpeg" ] && [ ! -x "${ROON_FFMPEG_DIR}/ffmpeg" ] && chmod 755 "${ROON_FFMPEG_DIR}/ffmpeg"

       export ROON_DATAROOT
	    export ROON_ID_DIR
	    export PATH="$ROON_FFMPEG_DIR:$PATH"
	    export ROON_INSTALL_TMPDIR="${ROON_TMP_DIR}"
	    export TMP="${ROON_TMP_DIR}"

       echo "" | tee -a "$ROON_LOG_FILE"
       echo "############### Used FFMPEG Version ##############" | tee -a "$ROON_LOG_FILE"
       echo -e "ffmpeg Path: $(which ffmpeg)" | tee -a "$ROON_LOG_FILE"
       echo -e $(ffmpeg -version) | tee -a "$ROON_LOG_FILE"
       echo "##################################################" | tee -a "$ROON_LOG_FILE"
       echo "" | tee -a "$ROON_LOG_FILE"

        # Checking for additional start arguments.
	    if [[ -f "${ROON_DATAROOT}/ROON_DEBUG_LAUNCH_PARAMETERS.txt" ]]; then
	        ROON_ARGS=`cat "$ROON_DATAROOT/ROON_DEBUG_LAUNCH_PARAMETERS.txt" | xargs | sed "s/ ---- /\n---- /g"`
        else
	        ROON_ARGS=""
	    fi
	    echolog "ROON_DEBUG_ARGS ${ROON_ARGS}"

        ## Start RoonServer
	    (${APKG_PKG_DIR}/RoonServer/start.sh "${ROON_ARGS}" | while read line; do echo `date +%d.%m.%y-%H:%M:%S` " --- $line"; done >> $ROON_LOG_FILE  2>&1) &

	    echo "" | tee -a $ROON_LOG_FILE
	    echo "" | tee -a $ROON_LOG_FILE
	    echo "########## Installed RoonServer Version ##########" | tee -a $ROON_LOG_FILE
	    echo "${ROON_VERSION}" | tee -a $ROON_LOG_FILE
	    echo "##################################################" | tee -a $ROON_LOG_FILE
	    echo "" | tee -a $ROON_LOG_FILE
	    echo "" | tee -a $ROON_LOG_FILE
   	else
		echolog "Database path not set in web ui."
    fi
}

stopRoonServer() {
    echolog "Stopping RoonServer."
    echo "stop" > $LOCKFILE
    # stop script here
	if [ ! -z "$ROON_PID" ] && kill -s 0 $ROON_PID; then
	   echolog "Roon PID to be killed: $ROON_PID"
		kill ${ROON_PID} >> $ROON_LOG_FILE
	else
    echolog "Could not stop RoonServer. It does not seem to be running."
   fi
}

logs() {
    logDate=$1
    getInfo
    #removing previous logfile (if exists)

    echolog "Creating Log-zipfile."
    echo "logs" > $LOCKFILE
	start_dir=$(pwd)
    zipFile="${ROON_WWW_DIR}/tmp/RoonServer_Asustor_Logs_$logDate.zip"
    cd $ROON_DATAROOT

    if [ -d "$ROON_DATAROOT/RoonServer" ]; then
        echolog "Adding RoonServer/Logs"
        7z a $zipFile RoonServer/Logs
    fi

    if [ -d "$ROON_DATAROOT/RAATServer" ]; then
        echolog "Adding RAATServer/Logs"
        7z a $zipFile RAATServer/Logs
    fi

    if [ -d "$ROON_DATAROOT/RAATServer" ]; then
        echolog "Adding RAATServer/Logs"
        7z a $zipFile RAATServer/Logs
    fi

    cd $start_dir

    echolog "Adding stdout logfile"
    7z a $zipFile $ROON_LOG_FILE
}

downloadBinaries() {
  echo "download" > $LOCKFILE
  if [ -f "$ROON_DATAROOT/ROON_DEBUG_INSTALL_URL.txt" ]; then
    CUSTOM_INSTALL_URL=`/bin/cat "$ROON_DATAROOT/ROON_DEBUG_INSTALL_URL.txt"`
    if [ ${CUSTOM_INSTALL_URL:0:4} == "http" ] && [ $(basename ${CUSTOM_INSTALL_URL}) == $(basename ${ROON_PKG_URL}) ] ; then
      ROON_PKG_URL="${CUSTOM_INSTALL_URL}"
    fi
  fi

  cd "$APKG_PKG_DIR/tmp"

  ## Try Curl if available
  PATH=/usr/builtin/bin:$PATH
  if command -v curl >/dev/null 2>&1; then
    echolog "Downloading Roon Server using curl command."
    STATUSCODE=$(curl --write-out '%{http_code}' -sLfO "$ROON_PKG_URL")
    R=$?
  elif command -v wget >/dev/null 2>&1; then
    echolog "Downloading Roon Server using wget command."
    WGET_OUTPUT=$(wget -S "$ROON_PKG_URL" 2>&1)
    R=$?
    STATUSCODE=$(echo "$WGET_OUTPUT" | grep "HTTP/" | awk '{print $2}')
  fi

  if test "$R" != "0"; then
    echolog "Roon Server download failed!"
    echolog "URL: $ROON_PKG_URL)"
    echolog "Status-Code: $STATUSCODE)"
    exit 1
  fi
  echolog "Download finished! [$STATUSCODE]"

  echolog "Extracting Roon Server from file..."
  /bin/tar xjf "$ROON_FILENAME" -C "$APKG_PKG_DIR/tmp"
  R=$?
  if test "$R" != "0"; then
    echolog "Could not extract downloadeded tar.bz2 file. Download may be corrupted."
    [ -f "$APKG_PKG_DIR/tmp/$ROON_FILENAME" ] && /bin/rm "$APKG_PKG_DIR/tmp/$ROON_FILENAME"
    exit 1
  fi
  [ -d "$APKG_PKG_DIR/RoonServer" ] && mv "$APKG_PKG_DIR/RoonServer" "$APKG_PKG_DIR/RoonServer_Old"
  mv "$APKG_PKG_DIR/tmp/RoonServer" "$APKG_PKG_DIR/"
  [ -f "$APKG_PKG_DIR/tmp/$ROON_FILENAME" ] && /bin/rm "$ROON_FILENAME"
  [ -d "$APKG_PKG_DIR/RoonServer_Old" ] && /bin/rm -R "$APKG_PKG_DIR/RoonServer_Old"
  getInfo
}

#check if RoonServer has initially been downloaded after apkg install
if [ ! -d "$APKG_PKG_DIR/RoonServer" ]; then
   getInfo
	downloadBinaries
fi

#check web ui status
if [ -f "$WEBUI_STATUS" ]; then
    getInfo
    WEBUI_ACTION=`cat "$APKG_PKG_DIR/web-status"`
    echolog "Performing Action: $WEBUI_ACTION"
    set -- $WEBUI_ACTION
    rm $WEBUI_STATUS
        case $1 in
            start)
                startRoonServer
                ;;
            restart)
                echolog "Restarting RoonServer"
                stopRoonServer
                wait 2
                startRoonServer
                ;;
            redownload)
                stopRoonServer
                downloadBinaries
                startRoonServer
                ;;
            logs)
                logs $2
                ;;
            *)
                echo "Illegal action."
                ;;
        esac
fi

lockfile remove
