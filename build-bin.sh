#!/usr/bin/env bash
# sftp-forge - Release Builder

set -Eeuo pipefail

# ==============================
# CONFIG
# ==============================
APP_NAME="sftp-forge"
ENTRY_FILE="sftp-forge.py"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/.build-venv"

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
echo -e "${MAGENTA}  sftp-forge Release Build          ${NC}"
echo -e "${CYAN}====================================${NC}"
echo

# ==============================
# Cleanup trap — always runs
# ==============================
cleanup() {
    echo
    echo -e "${CYAN}🧼 Cleaning up build artifacts...${NC}"
    rm -rf \
        "$PROJECT_DIR/build" \
        "$PROJECT_DIR/dist" \
        "$PROJECT_DIR/__pycache__" \
        "$PROJECT_DIR"/*.spec \
        "$VENV_DIR" \
        || true
    echo -e "${GREEN}✔ Cleanup done.${NC}"
}
trap cleanup EXIT

# ==============================
# Detect python3 binary
# ==============================
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null; then
        ver=$("$candidate" -c "import sys; print(sys.version_info[:2])" 2>/dev/null || true)
        if "$candidate" -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" 2>/dev/null; then
            PYTHON="$candidate"
            echo -e "${GREEN}✔ Found Python:${NC} $($PYTHON --version) → $(command -v $PYTHON)"
            break
        else
            echo -e "${YELLOW}⚠ $candidate found but version < 3.10 (got $ver), skipping.${NC}"
        fi
    fi
done

if [[ -z "$PYTHON" ]]; then
    echo -e "${RED}❌ Python 3.10+ not found. Please install python3.${NC}"
    exit 1
fi

# ==============================
# Detect venv support
# ==============================
if ! "$PYTHON" -m venv --help &>/dev/null; then
    echo -e "${RED}❌ python3-venv module not found.${NC}"
    echo -e "${YELLOW}   Install it with:  sudo apt install python3-venv${NC}"
    exit 1
fi
echo -e "${GREEN}✔ venv module available.${NC}"

# ==============================
# Clean old builds
# ==============================
echo
echo -e "${CYAN}🧹 Cleaning old build files...${NC}"
rm -rf \
    "$PROJECT_DIR/build" \
    "$PROJECT_DIR/dist" \
    "$PROJECT_DIR/__pycache__" \
    "$PROJECT_DIR"/*.spec \
    "$VENV_DIR" \
    || true

# ==============================
# Create temporary venv
# ==============================
echo
echo -e "${CYAN}🔧 Creating temporary build venv...${NC}"
"$PYTHON" -m venv "$VENV_DIR"

VENV_PY="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

# Upgrade pip silently
"$VENV_PIP" install --upgrade pip --quiet

# ==============================
# Install dependencies
# ==============================
echo -e "${CYAN}📦 Installing PyQt6 and PyInstaller into venv...${NC}"
"$VENV_PIP" install PyQt6 pyinstaller --quiet
echo -e "${GREEN}✔ Dependencies installed.${NC}"

# ==============================
# Build
# ==============================
echo
echo -e "${GREEN}🚀 Building binary...${NC}"

"$VENV_PY" -m PyInstaller \
    --onefile \
    --windowed \
    --clean \
    --noconfirm \
    --name "$APP_NAME" \
    "$PROJECT_DIR/$ENTRY_FILE"

# ==============================
# Move binary to project root
# ==============================
if [[ -f "$PROJECT_DIR/dist/$APP_NAME" ]]; then
    if [[ -f "$PROJECT_DIR/$APP_NAME" ]]; then
        echo -e "${YELLOW}🗑 Removing existing binary...${NC}"
        rm -f "$PROJECT_DIR/$APP_NAME"
    fi
    echo -e "${CYAN}➜ Moving binary to project root...${NC}"
    mv -f "$PROJECT_DIR/dist/$APP_NAME" "$PROJECT_DIR/"
    chmod +x "$PROJECT_DIR/$APP_NAME"
else
    echo -e "${RED}❌ Build failed — binary not found in dist/.${NC}"
    exit 1
fi

# cleanup() runs automatically via trap EXIT
echo
echo -e "${GREEN}✅ Release Ready!${NC}"
echo -e "${CYAN}Binary:${NC} $PROJECT_DIR/$APP_NAME"
echo
