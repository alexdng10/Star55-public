#!/bin/sh
# Star55 public uninstaller
# Copyright (c) 2026 Hung Dang
# SPDX-License-Identifier: MIT

set -eu

APP_DEST="$HOME/Applications/Star55.app"
LAUNCHER_CANDIDATES="$HOME/.local/bin/star55
/opt/homebrew/bin/star55
/usr/local/bin/star55
$HOME/bin/star55"
CONFIRM="${1:-}"

is_star55_app() {
    [ -d "$APP_DEST" ] || return 1
    [ "$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$APP_DEST/Contents/Info.plist" 2>/dev/null || true)" = "dev.star55.engine" ]
}

is_star55_launcher() {
    [ -f "$1" ] || return 1
    [ -L "$1" ] && return 1
    [ "$(/usr/bin/sed -n '2p' "$1" 2>/dev/null || true)" = "# Star55 public launcher" ] &&
    [ "$(/usr/bin/sed -n '3p' "$1" 2>/dev/null || true)" = "# Installed by star55-public/install.sh" ]
}

REMOVE_APP=0
if is_star55_app; then
    REMOVE_APP=1
fi
REMOVE_LAUNCHERS=""
REMOVE_COUNT=0
OLD_IFS="$IFS"
IFS='
'
for launcher in $LAUNCHER_CANDIDATES; do
    if is_star55_launcher "$launcher"; then
        REMOVE_LAUNCHERS="$REMOVE_LAUNCHERS$launcher
"
        REMOVE_COUNT=$((REMOVE_COUNT + 1))
    fi
done
IFS="$OLD_IFS"

if [ "$REMOVE_APP" -eq 0 ] && [ "$REMOVE_COUNT" -eq 0 ]; then
    echo "Nothing to remove."
    exit 0
fi

echo "This will remove:"
if [ "$REMOVE_APP" -eq 1 ]; then
    echo "  $APP_DEST"
fi
IFS='
'
for launcher in $REMOVE_LAUNCHERS; do
    echo "  $launcher"
done
IFS="$OLD_IFS"

if [ "$CONFIRM" != "--yes" ]; then
    printf "Proceed? [y/N] "
    read -r answer || true
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "aborted"; exit 1 ;;
    esac
fi

if [ "$REMOVE_APP" -eq 1 ]; then
    /bin/rm -rf "$APP_DEST"
    echo "removed $APP_DEST"
fi
IFS='
'
for launcher in $REMOVE_LAUNCHERS; do
    /bin/rm -f "$launcher"
    echo "removed $launcher"
done
IFS="$OLD_IFS"
