#!/usr/bin/env bash
# ============================================================================
# Loctree Plugin Installer for Claude Code
# Usage:
#   Remote: curl -fsSL https://raw.githubusercontent.com/Loctree/loctree-plugin/refs/heads/main/install.sh | bash
#   Local:  bash install.sh
# ============================================================================

set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "This installer must be run with bash."
  echo "Use: curl -fsSL https://raw.githubusercontent.com/Loctree/loctree-plugin/refs/heads/main/install.sh | bash"
  exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/Loctree/loctree-plugin/refs/heads/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}" 2>/dev/null)" 2>/dev/null && pwd 2>/dev/null || echo "")"

# Detect if running locally (hooks/ directory exists next to script)
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/hooks" ]]; then
  LOCAL_MODE=true
  HOOKS_SRC="$SCRIPT_DIR/hooks"
else
  LOCAL_MODE=false
fi

echo ""
echo -e "${BLUE}⌜ Loctree ⌟ Plugin Installer${NC}"
if $LOCAL_MODE; then
  echo -e "  ${YELLOW}(local mode)${NC}"
fi
echo ""

# ============================================================================
# Prerequisites
# ============================================================================

echo -e "${BLUE}[1/4]${NC} Checking prerequisites..."

if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}✗ curl not found${NC}"
  echo ""
  echo "  Install first:"
  echo "    brew install curl    # macOS"
  echo "    apt install curl     # Linux"
  echo ""
  exit 1
fi
echo -e "  curl: ${GREEN}✓${NC}"

ensure_loct_on_path() {
  if command -v loct >/dev/null 2>&1; then
    return 0
  fi
  for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/bin"; do
    if [[ -x "$dir/loct" ]]; then
      export PATH="$dir:$PATH"
      return 0
    fi
  done
  return 1
}

if ! command -v loct >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠ loctree CLI not found${NC}"
  echo "  Installing loctree CLI..."
  curl -fsSL https://loct.io/install.sh | sh
fi
if ! ensure_loct_on_path; then
  echo -e "${RED}✗ loctree CLI not available on PATH${NC}"
  echo ""
  echo "  If loctree was installed, ensure its bin directory is on PATH."
  echo "  Common location: $HOME/.local/bin"
  echo "  Then re-run this installer."
  exit 1
fi
echo -e "  loct: ${GREEN}✓${NC} $(loct --version 2>/dev/null | head -1)"

if ! command -v jq >/dev/null 2>&1; then
  echo -e "${RED}✗ jq not found${NC}"
  echo ""
  echo "  Install first:"
  echo "    brew install jq      # macOS"
  echo "    apt install jq       # Linux"
  echo ""
  exit 1
fi
echo -e "  jq: ${GREEN}✓${NC}"

# ============================================================================
# Create directories
# ============================================================================

echo ""
echo -e "${BLUE}[2/4]${NC} Creating directories..."

mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/logs
echo -e "  ~/.claude/hooks: ${GREEN}✓${NC}"

# ============================================================================
# Install hooks (local copy or remote download)
# ============================================================================

echo ""
if $LOCAL_MODE; then
  echo -e "${BLUE}[3/4]${NC} Copying hook scripts..."
  shopt -s nullglob
  for hook in "$HOOKS_SRC"/*.sh; do
    if [[ -f "$hook" ]]; then
      HOOK_NAME=$(basename "$hook")
      cp "$hook" ~/.claude/hooks/
      chmod +x ~/.claude/hooks/"$HOOK_NAME"
      echo -e "  ${HOOK_NAME}: ${GREEN}✓${NC}"
    fi
  done
  shopt -u nullglob
else
  echo -e "${BLUE}[3/4]${NC} Downloading hook scripts..."
  for hook in loct-grep-augment.sh loct-read-context.sh loct-edit-warning.sh; do
    if curl -fsSL "${REPO_RAW}/hooks/${hook}" -o ~/.claude/hooks/"${hook}"; then
      chmod +x ~/.claude/hooks/"${hook}"
      echo -e "  ${hook}: ${GREEN}✓${NC}"
    else
      echo -e "  ${hook}: ${RED}✗ download failed${NC}"
      exit 1
    fi
  done
fi

# ============================================================================
# Configure settings.json
# ============================================================================

echo ""
echo -e "${BLUE}[4/4]${NC} Configuring Claude Code..."

SETTINGS_FILE="$HOME/.claude/settings.json"

HOOKS_CONFIG='{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Grep",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/loct-grep-augment.sh" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/loct-grep-augment.sh --bash-filter" }]
      },
      {
        "matcher": "Read",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/loct-read-context.sh" }]
      },
      {
        "matcher": "Edit",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/loct-edit-warning.sh" }]
      }
    ]
  }
}'

if [[ -f "$SETTINGS_FILE" ]]; then
  # Backup
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"

  if jq -e '.hooks.PostToolUse' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} PostToolUse hooks exist - merging..."
    # Merge loctree hooks with existing
    jq --argjson new "$HOOKS_CONFIG" '.hooks.PostToolUse = (.hooks.PostToolUse + $new.hooks.PostToolUse | unique_by(.matcher))' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    jq --argjson hooks "$HOOKS_CONFIG" '. * $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  fi
  echo -e "  settings.json: ${GREEN}✓${NC} (merged)"
else
  echo "$HOOKS_CONFIG" | jq '.' > "$SETTINGS_FILE"
  echo -e "  settings.json: ${GREEN}✓${NC} (created)"
fi

# ============================================================================
# Done
# ============================================================================

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or run /clear)"
echo "  2. Search for any symbol - loctree augments automatically"
echo "  3. Watch: tail -f ~/.claude/logs/loct-hook.log"
echo ""
echo -e "Made with ${RED}(งಠ_ಠ)ง${NC} by ${BLUE}⌜ Loctree ⌟${NC} team"
echo ""
