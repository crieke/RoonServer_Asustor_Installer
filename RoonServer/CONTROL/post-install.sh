#!/bin/sh

APKG_PKG_DIR=/usr/local/AppCentral/RoonServer

case "$APKG_PKG_STATUS" in

	install)
		# post install script here
		[ ! -d "$APKG_APKG_DIR/tmp" ] && /bin/mkdir -m 777 "$APKG_PKG_DIR/tmp"
		[ ! -d "$APKG_APKG_DIR/etc" ] && /bin/mkdir -m 777 "$APKG_PKG_DIR/etc"
		[ ! -d "$APKG_APKG_DIR/id" ] && /bin/mkdir -m 777 "$APKG_PKG_DIR/id"
		
		;;
	upgrade)
		# post upgrade script here (restore data)
		# cp -af $APKG_TEMP_DIR/* $APKG_PKG_DIR/etc/.
		
	/bin/mkdir -m 777 "$APKG_PKG_DIR/tmp"
        [ -d "$APKG_TEMP_DIR/etc" ] && cp -R "$APKG_TEMP_DIR/etc" "$APKG_PKG_DIR/" || /bin/mkdir -m 777 "$APKG_PKG_DIR/etc"
        [ -d "$APKG_TEMP_DIR/id" ] && cp -R "$APKG_TEMP_DIR/id" "$APKG_PKG_DIR/" || /bin/mkdir -m 777 "$APKG_PKG_DIR/id"
        [ -d "$APKG_TEMP_DIR/RoonServer" ] && cp -R  "$APKG_TEMP_DIR/RoonServer" "$APKG_PKG_DIR/"

		;;
	*)
		;;

esac

exit 0

