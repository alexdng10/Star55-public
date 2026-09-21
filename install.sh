#!/bin/sh
# Star55 public installer
# Copyright (c) 2026 Hung Dang
# SPDX-License-Identifier: MIT

set -eu

if [ "$(/usr/bin/uname -s)" != "Darwin" ]; then
    echo "error: Star55 currently supports macOS only" >&2
    exit 1
fi

if [ "$(/usr/bin/uname -m)" != "arm64" ]; then
    echo "error: Star55 currently supports Apple Silicon (arm64) only" >&2
    exit 1
fi

RELEASE_BASE="https://github.com/alexdng10/star55-public/releases/latest/download"
ARCHIVE_NAME="Star55-macos-arm64.tar.gz"
CHECKSUM_NAME="Star55-macos-arm64.sha256"
TMP_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/star55-install.XXXXXX")"
NEW_APP=""
LAUNCHER_TMP=""
trap '/bin/rm -rf "$TMP_DIR" "$NEW_APP" "$LAUNCHER_TMP"' EXIT INT TERM

ARCHIVE_PATH="$TMP_DIR/$ARCHIVE_NAME"
CHECKSUM_PATH="$TMP_DIR/$CHECKSUM_NAME"

/usr/bin/curl --fail --silent --show-error --location --retry 3 \
    "$RELEASE_BASE/$ARCHIVE_NAME" --output "$ARCHIVE_PATH"
/usr/bin/curl --fail --silent --show-error --location --retry 3 \
    "$RELEASE_BASE/$CHECKSUM_NAME" --output "$CHECKSUM_PATH"

EXPECTED_SHA="$(/usr/bin/awk 'NF { print $1; exit }' "$CHECKSUM_PATH")"
case "$EXPECTED_SHA" in
    ""|*[!0123456789abcdefABCDEF]*|?????????????????????????????????????????????????????????????????*)
        echo "error: invalid SHA-256 checksum asset" >&2
        exit 1
        ;;
esac
if [ "${#EXPECTED_SHA}" -ne 64 ]; then
    echo "error: invalid SHA-256 checksum asset" >&2
    exit 1
fi
ACTUAL_SHA="$(/usr/bin/shasum -a 256 "$ARCHIVE_PATH" | /usr/bin/awk '{print $1}')"
if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
    echo "error: SHA-256 verification failed" >&2
    exit 1
fi

/usr/bin/tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"
APP_SOURCE="$TMP_DIR/Star55.app"
if [ ! -d "$APP_SOURCE" ] || [ ! -f "$TMP_DIR/LICENSE" ]; then
    echo "error: release archive is missing Star55.app or LICENSE" >&2
    exit 1
fi
BUNDLE_ID="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$APP_SOURCE/Contents/Info.plist" 2>/dev/null || true)"
if [ "$BUNDLE_ID" != "dev.star55.engine" ]; then
    echo "error: release archive does not contain the Star55 application" >&2
    exit 1
fi
if [ ! -x "$APP_SOURCE/Contents/MacOS/Star55Editor" ]; then
    echo "error: Star55.app is missing its executable" >&2
    exit 1
fi

path_contains() {
    case ":${PATH:-}:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

if path_contains "$HOME/.local/bin"; then
    LAUNCHER_DIR="$HOME/.local/bin"
elif path_contains /opt/homebrew/bin && [ -d /opt/homebrew/bin ] && [ -w /opt/homebrew/bin ]; then
    LAUNCHER_DIR="/opt/homebrew/bin"
elif path_contains /usr/local/bin && [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
    LAUNCHER_DIR="/usr/local/bin"
elif path_contains "$HOME/bin"; then
    LAUNCHER_DIR="$HOME/bin"
else
    LAUNCHER_DIR="$HOME/.local/bin"
fi
/bin/mkdir -p "$LAUNCHER_DIR"
LAUNCHER="$LAUNCHER_DIR/star55"
if [ -e "$LAUNCHER" ] && {
    [ "$(/usr/bin/sed -n '2p' "$LAUNCHER" 2>/dev/null || true)" != "# Star55 public launcher" ] ||
    [ "$(/usr/bin/sed -n '3p' "$LAUNCHER" 2>/dev/null || true)" != "# Installed by star55-public/install.sh" ];
}; then
    echo "error: refusing to replace unrelated launcher at $LAUNCHER" >&2
    exit 1
fi

APP_DEST="$HOME/Applications/Star55.app"
/bin/mkdir -p "$HOME/Applications"
if [ -e "$APP_DEST" ]; then
    EXISTING_ID="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$APP_DEST/Contents/Info.plist" 2>/dev/null || true)"
    if [ "$EXISTING_ID" != "dev.star55.engine" ]; then
        echo "error: refusing to replace unrelated application at $APP_DEST" >&2
        exit 1
    fi
fi
NEW_APP="$HOME/Applications/.Star55.app.new.$$"
/usr/bin/ditto "$APP_SOURCE" "$NEW_APP"
if [ -e "$APP_DEST" ]; then
    /bin/rm -rf "$APP_DEST"
fi
/bin/mv "$NEW_APP" "$APP_DEST"
NEW_APP=""

LAUNCHER_TMP="$LAUNCHER.tmp.$$"
cat > "$LAUNCHER_TMP" <<'LAUNCHER'
#!/bin/sh
# Star55 public launcher
# Installed by star55-public/install.sh
# SPDX-License-Identifier: MIT

set -eu
APP_PATH="$HOME/Applications/Star55.app"
if [ ! -d "$APP_PATH" ]; then
    echo "error: Star55.app is not installed at $APP_PATH" >&2
    exit 1
fi
exec /usr/bin/env -u OMPCODE -u STAR55_BACKGROUND STAR55_FOREGROUND=1 \
    /usr/bin/open "$APP_PATH" --args "$@"
LAUNCHER
/bin/chmod 755 "$LAUNCHER_TMP"
/bin/mv "$LAUNCHER_TMP" "$LAUNCHER"
LAUNCHER_TMP=""

# A per-user PATH is preferred. Never edit shell startup files automatically.
echo "Star55 installed successfully."
echo
echo "Application: $APP_DEST"
echo "Launcher:    $LAUNCHER"
if ! path_contains "$LAUNCHER_DIR"; then
    echo
    echo "Add the launcher directory to PATH for this shell:"
    echo "  export PATH=\"$LAUNCHER_DIR:\$PATH\""
fi
echo
echo "Run:"
echo
echo "star55"
