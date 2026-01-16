#!/usr/bin/env bash
# ============================================================================
# Loctree Plugin Installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/VetCoders/loctree-plugin/main/install.sh | bash
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/VetCoders/loctree-plugin/main"

echo ""
echo -e "${BLUE}⌜ Loctree ⌟ Plugin Installer${NC}"
echo ""

# ============================================================================
# Prerequisites
# ============================================================================

echo -e "${BLUE}[1/4]${NC} Checking prerequisites..."

if ! command -v loct >/dev/null 2>&1; then
  echo -e "${RED}✗ loctree CLI not found${NC}"
  echo ""
  echo "  Install first:"
  echo "    cargo install loctree"
  echo "    # or"
  echo "    brew install loctree"
  echo ""
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
# Download hooks
# ============================================================================

echo ""
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
