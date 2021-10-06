#!/bin/sh

APKG_PKG_DIR=/usr/local/AppCentral/RoonServer

case "$APKG_PKG_STATUS" in

	install)
		# pre install script here
		;;
	upgrade)
		# pre upgrade script here (backup data)
		[ -d "$APKG_PKG_DIR/etc" ] && mv "$APKG_PKG_DIR/etc" "$APKG_TEMP_DIR/"
		[ -d "$APKG_PKG_DIR/RoonServer" ] && mv "$APKG_PKG_DIR/RoonServer" "$APKG_TEMP_DIR/"
		[ -d "$APKG_PKG_DIR/id" ] && mv "$APKG_PKG_DIR/id" "$APKG_TEMP_DIR/"


		;;
	*)
		;;

esac

exit 0

