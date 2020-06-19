#!/bin/sh

APKG_PKG_DIR=/usr/local/AppCentral/RoonServer

case "$APKG_PKG_STATUS" in

	install)
		# post install script here
		/bin/mkdir -m 777 "$APKG_PKG_DIR/tmp"
		/bin/mkdir -m 777 "$APKG_PKG_DIR/etc"
		/bin/mkdir -m 777 "$APKG_PKG_DIR/id"
		
		;;
	upgrade)
		# post upgrade script here (restore data)
		# cp -af $APKG_TEMP_DIR/* $APKG_PKG_DIR/etc/.
		mv $APKG_TEMP_DIR/RoonServer.conf $APKG_PKG_DIR/etc/RoonServer.conf

		;;
	*)
		;;

esac

exit 0
