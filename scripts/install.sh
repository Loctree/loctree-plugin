#!/usr/bin/env bash
# ============================================================================
# install.sh - Install Loctree Plugin for Claude Code
# ============================================================================
# Usage: bash install.sh
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ⌜ Loctree ⌟ Plugin Installer         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Pre-flight checks
# ============================================================================

echo -e "${BLUE}[1/5]${NC} Checking prerequisites..."

# Check loctree CLI
if ! command -v loct >/dev/null 2>&1; then
  echo -e "${RED}✗ loctree CLI not found${NC}"
  echo ""
  echo "Install loctree first:"
  echo "  cargo install loctree"
  echo "  # or"
  echo "  brew install loctree"
  echo ""
  exit 1
fi
LOCT_VERSION=$(loct --version 2>/dev/null | head -1)
echo -e "  loctree: ${GREEN}✓${NC} $LOCT_VERSION"

# Check jq
if ! command -v jq >/dev/null 2>&1; then
  echo -e "${RED}✗ jq not found${NC}"
  echo ""
  echo "Install jq first:"
  echo "  brew install jq      # macOS"
  echo "  apt install jq       # Linux"
  echo ""
  exit 1
fi
JQ_VERSION=$(jq --version 2>/dev/null)
echo -e "  jq: ${GREEN}✓${NC} $JQ_VERSION"

# Check Python 3 (optional)
if command -v python3 >/dev/null 2>&1; then
  PY_VERSION=$(python3 --version 2>/dev/null)
  echo -e "  python3: ${GREEN}✓${NC} $PY_VERSION"
else
  echo -e "  python3: ${YELLOW}⚠${NC} not found (optional)"
fi

# ============================================================================
# Create directories
# ============================================================================

echo ""
echo -e "${BLUE}[2/5]${NC} Creating directories..."

mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/logs
mkdir -p ~/.claude/skills

echo -e "  ~/.claude/hooks: ${GREEN}✓${NC}"
echo -e "  ~/.claude/logs: ${GREEN}✓${NC}"
echo -e "  ~/.claude/skills: ${GREEN}✓${NC}"

# ============================================================================
# Copy hook scripts
# ============================================================================

echo ""
echo -e "${BLUE}[3/5]${NC} Installing hook scripts..."

HOOKS_SRC="$PLUGIN_DIR/hooks"

if [[ ! -d "$HOOKS_SRC" ]]; then
  echo -e "${RED}✗ hooks/ directory not found in $PLUGIN_DIR${NC}"
  exit 1
fi

for hook in "$HOOKS_SRC"/*.sh; do
  if [[ -f "$hook" ]]; then
    HOOK_NAME=$(basename "$hook")
    cp "$hook" ~/.claude/hooks/
    chmod +x ~/.claude/hooks/"$HOOK_NAME"
    echo -e "  $HOOK_NAME: ${GREEN}✓${NC}"
  fi
done

# ============================================================================
# Configure settings.json
# ============================================================================

echo ""
echo -e "${BLUE}[4/5]${NC} Configuring Claude Code hooks..."

SETTINGS_FILE="$HOME/.claude/settings.json"

# PostToolUse hooks configuration
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
  # Backup existing settings
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
  echo -e "  Backed up existing settings: ${GREEN}✓${NC}"

  # Check if PostToolUse already exists
  if jq -e '.hooks.PostToolUse' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} PostToolUse hooks already configured"
    echo ""
    echo -e "  ${YELLOW}Existing hooks found. To avoid conflicts:${NC}"
    echo "  1. Review ~/.claude/settings.json"
    echo "  2. Merge loctree hooks manually, or"
    echo "  3. Run with --force to overwrite"
    echo ""

    if [[ "${1:-}" == "--force" ]]; then
      echo -e "  ${YELLOW}--force specified, overwriting...${NC}"
      # Merge: replace hooks section
      jq --argjson hooks "$HOOKS_CONFIG" '. * $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
      mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      echo -e "  PostToolUse hooks: ${GREEN}✓${NC} (overwritten)"
    else
      echo -e "  PostToolUse hooks: ${YELLOW}skipped${NC}"
    fi
  else
    # Merge hooks into existing settings
    jq --argjson hooks "$HOOKS_CONFIG" '. * $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo -e "  PostToolUse hooks: ${GREEN}✓${NC}"
  fi
else
  # Create new settings file
  echo "$HOOKS_CONFIG" | jq '.' > "$SETTINGS_FILE"
  echo -e "  Created settings.json: ${GREEN}✓${NC}"
  echo -e "  PostToolUse hooks: ${GREEN}✓${NC}"
fi

# ============================================================================
# Install skill (optional)
# ============================================================================

echo ""
echo -e "${BLUE}[5/5]${NC} Installing skill definition..."

SKILLS_SRC="$PLUGIN_DIR/skills/loctree"

if [[ -d "$SKILLS_SRC" ]]; then
  cp -r "$SKILLS_SRC" ~/.claude/skills/
  echo -e "  loctree skill: ${GREEN}✓${NC}"
else
  echo -e "  loctree skill: ${YELLOW}skipped${NC} (not found)"
fi

# ============================================================================
# Done!
# ============================================================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code or run /clear"
echo "  2. Search for any symbol (e.g., 'useState')"
echo "  3. Watch the magic: tail -f ~/.claude/logs/loct-hook.log"
echo ""
echo "Verify installation:"
echo "  bash $SCRIPT_DIR/verify-install.sh"
echo ""
