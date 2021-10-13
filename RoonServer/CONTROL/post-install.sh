#!/bin/sh

APKG_PKG_DIR=/usr/local/AppCentral/RoonServer

case "$APKG_PKG_STATUS" in

	install)
		# post install script here
		[ ! -d "$APKG_PKG_DIR/tmp" ] && /bin/mkdir -m 777 "$APKG_PKG_DIR/tmp"
		[ ! -d "$APKG_PKG_DIR/etc" ] && /bin/mkdir -m 777 "$APKG_PKG_DIR/etc"
		[ ! -d "$APKG_PKG_DIR/id" ] && /bin/mkdir -m 777 "$APKG_PKG_DIR/id"

		;;
	upgrade)
		# post upgrade script here (restore data)
		# cp -af $APKG_TEMP_DIR/* $APKG_PKG_DIR/etc/.
		[ -f "$APKG_TEMP_DIR/etc/RoonServer.conf" ] && ROON_DB_PATH=$(awk -F "= " '/DB_Path/ {print $2}' "${APKG_TEMP_DIR}/etc/RoonServer.conf")


		# Migrate to new database folder structure
		if [ ${APKG_PKG_INST_VER//[!0-9]/} -le 20210726 ] && [ -n "${ROON_DB_PATH+set}" ] && [ -d "${ROON_DB_PATH}" ]; then
			if [ -d "${ROON_DB_PATH}" ] && [ -d "${ROON_DB_PATH}/RoonServer" ] && [ -d "${ROON_DB_PATH}/RAATServer" ] && [ ! -d "${ROON_DB_PATH}/RoonOnNAS" ]; then
				/bin/mkdir -m 777 "${ROON_DB_PATH}/RoonOnNAS"
				/bin/mkdir -m 777 "${ROON_DB_PATH}/RoonOnNAS/bin"
				/bin/mv "${ROON_DB_PATH}/RoonServer" "${ROON_DB_PATH}/RoonOnNAS/"
				/bin/mv "${ROON_DB_PATH}/RAATServer" "${ROON_DB_PATH}/RoonOnNAS/"
				[ -d "${ROON_DB_PATH}/RoonGoer" ] && /bin/mv "${ROON_DB_PATH}/RoonGoer" "${ROON_DB_PATH}/RoonOnNAS/"
			fi
		fi

	/bin/mkdir -m 777 "$APKG_PKG_DIR/tmp"
        [ -d "$APKG_TEMP_DIR/etc" ] && /bin/mv "$APKG_TEMP_DIR/etc" "$APKG_PKG_DIR/" || /bin/mkdir -m 777 "$APKG_PKG_DIR/etc"
        [ -d "$APKG_TEMP_DIR/id" ] && /bin/mv "$APKG_TEMP_DIR/id" "$APKG_PKG_DIR/" || /bin/mkdir -m 777 "$APKG_PKG_DIR/id"
        [ -d "$APKG_TEMP_DIR/RoonServer" ] && /bin/mv  "$APKG_TEMP_DIR/RoonServer" "$APKG_PKG_DIR/"

		;;
	*)
		;;

esac

exit 0

