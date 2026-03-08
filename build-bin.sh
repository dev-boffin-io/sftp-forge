#!/usr/bin/env bash
# sftp-forge - Release Builder

set -Eeuo pipefail

# ==============================
# CONFIG
# ==============================
APP_NAME="sftp-forge"
ENTRY_FILE="sftp-forge.py"
PROJECT_DIR="$(pwd)"

# ==============================
# COLORS
# ==============================
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
NC="\033[0m"

echo -e "${CYAN}====================================${NC}"
echo -e "${MAGENTA}  sftp-forge Release Build  ${NC}"
echo -e "${CYAN}====================================${NC}"
echo

# ==============================
# Checks
# ==============================
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 not found.${NC}"
    exit 1
fi

if ! python3 -m PyInstaller --version &> /dev/null; then
    echo -e "${YELLOW}⚠ Installing PyInstaller...${NC}"
    pip install pyinstaller
fi

# ==============================
# Clean old builds
# ==============================
echo -e "${CYAN}🧹 Cleaning old build files...${NC}"
rm -rf build dist __pycache__ *.spec || true

# ==============================
# Build
# ==============================
echo -e "${GREEN}🚀 Building binary...${NC}"

python3 -m PyInstaller \
    --onefile \
    --windowed \
    --clean \
    --noconfirm \
    --name "$APP_NAME" \
    "$ENTRY_FILE"

# ==============================
# Move binary to root
# ==============================
if [[ -f "$PROJECT_DIR/dist/$APP_NAME" ]]; then
    echo -e "${CYAN}➜ Moving binary to project root...${NC}"
    mv -f "$PROJECT_DIR/dist/$APP_NAME" "$PROJECT_DIR/"
    chmod +x "$PROJECT_DIR/$APP_NAME"
else
    echo -e "${RED}❌ Build failed.${NC}"
    exit 1
fi

# ==============================
# Final Cleanup
# ==============================
echo -e "${CYAN}🧼 Removing build garbage...${NC}"
rm -rf build dist __pycache__ *.spec || true

echo
echo -e "${GREEN}✅ Release Ready!${NC}"
echo -e "${CYAN}Binary Location:${NC} $PROJECT_DIR/$APP_NAME"
echo
