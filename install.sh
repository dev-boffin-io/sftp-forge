#!/usr/bin/env bash
# =========================================================
# Desktop Entry Installer (User + System Mode)
# Usage:
#   ./install.sh            → user local install
#   sudo ./install.sh       → system-wide install
#   ./install.sh remove     → uninstall (user)
#   sudo ./install.sh remove → uninstall (system)
# =========================================================

set -Eeuo pipefail
IFS=$'\n\t'

APP_NAME="sftp-forge"
APP_TITLE="SFTP Forge"
APP_COMMENT="Mount remote server as a local folder"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/$APP_NAME"
ICON="$SCRIPT_DIR/$APP_NAME.png"

USER_DESKTOP_DIR="$HOME/.local/share/applications"
SYSTEM_DESKTOP_DIR="/usr/local/share/applications"

DESKTOP_FILE_NAME="$APP_NAME.desktop"

# ─────────────────────────────────────────────
info() { echo -e "➜ $1"; }
error() { echo -e "✖ $1"; exit 1; }

# ─────────────────────────────────────────────
check_files() {
    [[ -f "$BINARY" ]] || error "Binary not found: $BINARY"
    [[ -x "$BINARY" ]] || error "Binary exists but not executable. Run: chmod +x $APP_NAME"
    [[ -f "$ICON" ]] || error "PNG icon not found: $ICON"
}

generate_entry() {
cat <<EOF
[Desktop Entry]
Version=1.0
Name=$APP_TITLE
Comment=$APP_COMMENT
Exec=$BINARY
Icon=$ICON
Terminal=false
Type=Application
Categories=Network;FileMount;Utility;
StartupNotify=true
EOF
}

install_entry() {

    if [[ "$EUID" -eq 0 ]]; then
        TARGET_DIR="$SYSTEM_DESKTOP_DIR"
        info "System-wide install mode"
    else
        TARGET_DIR="$USER_DESKTOP_DIR"
        info "User local install mode"
    fi

    mkdir -p "$TARGET_DIR"
    TARGET_FILE="$TARGET_DIR/$DESKTOP_FILE_NAME"

    check_files

    TMP_FILE="$(mktemp)"
    generate_entry > "$TMP_FILE"

    if [[ -f "$TARGET_FILE" ]]; then
        if cmp -s "$TMP_FILE" "$TARGET_FILE"; then
            info "Desktop entry already up-to-date."
            rm -f "$TMP_FILE"
            exit 0
        else
            info "Updating existing desktop entry..."
        fi
    else
        info "Creating desktop entry..."
    fi

    mv -f "$TMP_FILE" "$TARGET_FILE"
    chmod 644 "$TARGET_FILE"

    info "Refreshing desktop database..."
    update-desktop-database "$TARGET_DIR" 2>/dev/null || true

    info "✔ Installation complete"
}

remove_entry() {

    if [[ "$EUID" -eq 0 ]]; then
        TARGET_DIR="$SYSTEM_DESKTOP_DIR"
        info "System-wide uninstall mode"
    else
        TARGET_DIR="$USER_DESKTOP_DIR"
        info "User uninstall mode"
    fi

    TARGET_FILE="$TARGET_DIR/$DESKTOP_FILE_NAME"

    if [[ -f "$TARGET_FILE" ]]; then
        rm -f "$TARGET_FILE"
        update-desktop-database "$TARGET_DIR" 2>/dev/null || true
        info "✔ Desktop entry removed"
    else
        info "No desktop entry found to remove"
    fi
}

# ─────────────────────────────────────────────
case "${1:-}" in
    remove)
        remove_entry
        ;;
    *)
        install_entry
        ;;
esac
