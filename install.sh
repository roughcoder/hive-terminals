#!/usr/bin/env bash
set -euo pipefail

# hive installer
# curl -fsSL https://raw.githubusercontent.com/roughcoder/hive-terminals/main/install.sh | bash

INSTALL_DIR="$HOME/.local/bin"
HIVE_REPO="roughcoder/hive-terminals"
HIVE_RAW_URL="https://raw.githubusercontent.com/${HIVE_REPO}/main/hive"

BOLD="\033[1m"
RESET="\033[0m"
HONEY="\033[38;5;214m"
GREEN="\033[38;5;114m"
RED="\033[38;5;203m"
DIM="\033[2m"

echo -e "\n${HONEY}${BOLD}⬡ hive installer${RESET}\n"

# Check deps
for dep in tmux ssh; do
    if command -v "$dep" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $dep found"
    else
        echo -e "  ${RED}✗${RESET} $dep not found — install it first"
        if [[ "$dep" == "tmux" ]]; then
            echo -e "    ${DIM}brew install tmux${RESET}"
        fi
        exit 1
    fi
done

# Install
mkdir -p "$INSTALL_DIR"

# Try local copy first (cloned repo), fall back to downloading from GitHub
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/hive" ]]; then
    cp "$SCRIPT_DIR/hive" "$INSTALL_DIR/hive"
    echo -e "  ${GREEN}✓${RESET} Installed from local repo"
else
    echo -e "  ${DIM}Downloading hive from GitHub...${RESET}"
    if curl -fsSL "$HIVE_RAW_URL" -o "$INSTALL_DIR/hive"; then
        echo -e "  ${GREEN}✓${RESET} Downloaded from GitHub"
    else
        echo -e "  ${RED}✗${RESET} Failed to download hive from GitHub"
        exit 1
    fi
fi

chmod +x "$INSTALL_DIR/hive"
echo -e "  ${GREEN}✓${RESET} Installed to ${DIM}${INSTALL_DIR}/hive${RESET}"

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "\n  ${HONEY}!${RESET} Add to your shell profile:"
    echo -e "    ${DIM}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc${RESET}"
    echo -e "    ${DIM}source ~/.zshrc${RESET}"
else
    echo -e "  ${GREEN}✓${RESET} Already in PATH"
fi

echo -e "\n${HONEY}${BOLD}⬡ Next steps:${RESET}"
echo -e "  ${DIM}On your always-on Mac:${RESET}  ${HONEY}hive init core${RESET}"
echo -e "  ${DIM}On your laptops:${RESET}        ${HONEY}hive init link${RESET}"
echo ""