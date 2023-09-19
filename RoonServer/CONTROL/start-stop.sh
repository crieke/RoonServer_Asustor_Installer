#!/bin/sh

. /etc/script/lib/command.sh

APKG_PKG_DIR=/usr/local/AppCentral/RoonServer
APKG_BASH="$APKG_PKG_DIR/bin/bash"
PID_FILE=/var/run/RoonServer_webui.pid
APKG_NAME="RoonServer"
WEBUI_STATUS="/tmp/web-status"
ROON_TMP_DIR="$APKG_PKG_DIR/tmp"
ROON_PID=$(ps aux | grep "${APKG_PKG_DIR}/RoonServer/start.sh" | grep -v grep | awk '{print $1}')
ROON_WEBACTIONS_PIDFILE="/var/run/RoonServer_webactions.pid"
ROON_DATABASE_DIR=`awk -F "= " '/DB_Path/ {print $2}' ${APKG_PKG_DIR}/etc/RoonServer.conf`
ROON_DATAROOT="${ROON_DATABASE_DIR}/RoonOnNAS"
ROON_DATABASE_DIR_FS=`df -T "${ROON_DATABASE_DIR}" | grep "^/dev" | awk '{print $2}'`
ROON_LOG_FILE="${ROON_DATAROOT}/RoonOnNAS.log.txt"
WEBUI_HELPER_SCRIPT="${APKG_PKG_DIR}/helper-scripts/webui-actions.sh"

JAVA_CMD="/usr/local/bin/java"

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

RoonOnNAS_folderCheck ()
{
  if [ -d "${ROON_DATABASE_DIR}" ]; then
	[ -d "${ROON_DATABASE_DIR}/RoonOnNAS" ] || mkdir "${ROON_DATABASE_DIR}/RoonOnNAS"
	[ -d "${ROON_DATABASE_DIR}/RoonOnNAS/bin" ] || mkdir "${ROON_DATABASE_DIR}/RoonOnNAS/bin"
  fi
}

case $1 in

	start)
		RoonOnNAS_folderCheck
    	echo "" > $ROON_LOG_FILE
		# start script here

		# Check if bash symlink exists
        if [ ! -e /bin/bash ]; then
           echolog "Creating symlink for bash."
           ln -sf $APKG_BASH /bin/bash
        else
            echolog "Using bash at" $(readlink /bin/bash)
        fi


		watch -n 5 $WEBUI_HELPER_SCRIPT &
        echo $! > $ROON_WEBACTIONS_PIDFILE;
		echo "start" > $WEBUI_STATUS
	;;

	stop)
		# Stopping RoonServer itself
		if [ ! -z "$ROON_PID" ] && kill -s 0 ${ROON_PID}; then
			echolog "Stopping RoonServer..."
			echolog "Roon PID to be killed" "$ROON_PID"
			kill ${ROON_PID} >> $ROON_LOG_FILE
		fi

		#Stop watch process, which is watching for processes from the ui
		if [ -f "$ROON_WEBACTIONS_PIDFILE" ]; then
			kill `cat $ROON_WEBACTIONS_PIDFILE` 2> /dev/null
			rm "${ROON_WEBACTIONS_PIDFILE}"
		fi

	    echolog "RoonServer has been stopped."

		#Garbage Cleanup
		#Clean RoonServer's tmp directory
		if [ ! -z "$(ls ${ROON_TMP_DIR})" ]; then
			rm -R "${ROON_TMP_DIR}/*"
		fi

		#Remove old logfiles zip in RoonServer's web tmp directory
		if [ ! -z "$(ls $APKG_PKG_DIR/www/tmp)" ]; then
			rm -R "$APKG_PKG_DIR/www/tmp/*"
		fi

		#Remove lockfile if RoonServer has been stopped when helper process was active
		if [ -f "/tmp/.RoonServer-webui.lock" ]; then
		    rm "/tmp/.RoonServer-webui.lock";
		fi
		;;

	*)
		echo "usage: $0 {start|stop}"
		exit 1
		;;

esac

exit 0
