#!/usr/bin/env bash
# ============================================================================
# verify-install.sh - Validate Loctree Plugin installation
# ============================================================================
# Usage: bash verify-install.sh
# ============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "  Loctree Plugin Installation Checker"
echo "========================================"
echo ""

ERRORS=0

# Check loctree CLI
echo -n "1. Loctree CLI: "
if command -v loct >/dev/null 2>&1; then
  VERSION=$(loct --version 2>/dev/null | head -1)
  echo -e "${GREEN}✓ $VERSION${NC}"
else
  echo -e "${RED}✗ NOT FOUND${NC}"
  echo "   Install with: cargo install loctree"
  ((ERRORS++))
fi

# Check jq
echo -n "2. jq: "
if command -v jq >/dev/null 2>&1; then
  VERSION=$(jq --version 2>/dev/null)
  echo -e "${GREEN}✓ $VERSION${NC}"
else
  echo -e "${RED}✗ NOT FOUND${NC}"
  echo "   Install with: brew install jq (macOS) or apt install jq (Linux)"
  ((ERRORS++))
fi

# Check Python 3
echo -n "3. Python 3: "
if command -v python3 >/dev/null 2>&1; then
  VERSION=$(python3 --version 2>/dev/null)
  echo -e "${GREEN}✓ $VERSION${NC}"
else
  echo -e "${YELLOW}⚠ NOT FOUND (optional, used for shell parsing)${NC}"
fi

# Check hooks directory
echo ""
echo "4. Hook scripts:"
HOOKS_DIR="$HOME/.claude/hooks"
REQUIRED_HOOKS=(
  "loct-grep-augment.sh"
  "loct-read-context.sh"
  "loct-edit-warning.sh"
)

for hook in "${REQUIRED_HOOKS[@]}"; do
  HOOK_PATH="$HOOKS_DIR/$hook"
  echo -n "   $hook: "
  if [[ -f "$HOOK_PATH" ]]; then
    if [[ -x "$HOOK_PATH" ]]; then
      echo -e "${GREEN}✓ installed & executable${NC}"
    else
      echo -e "${YELLOW}⚠ installed but NOT executable${NC}"
      echo "      Fix with: chmod +x $HOOK_PATH"
      ((ERRORS++))
    fi
  else
    echo -e "${RED}✗ NOT FOUND${NC}"
    ((ERRORS++))
  fi
done

# Check settings.json
echo ""
echo -n "5. PostToolUse hooks in settings: "
SETTINGS_FILE="$HOME/.claude/settings.json"
if [[ -f "$SETTINGS_FILE" ]]; then
  HOOK_COUNT=$(jq -r '.hooks.PostToolUse | length // 0' "$SETTINGS_FILE" 2>/dev/null)
  if [[ "$HOOK_COUNT" -gt 0 ]]; then
    echo -e "${GREEN}✓ $HOOK_COUNT hooks configured${NC}"
  else
    echo -e "${RED}✗ No PostToolUse hooks found${NC}"
    ((ERRORS++))
  fi
else
  echo -e "${RED}✗ settings.json not found${NC}"
  ((ERRORS++))
fi

# Check log directory
echo ""
echo -n "6. Log directory: "
LOG_DIR="$HOME/.claude/logs"
if [[ -d "$LOG_DIR" ]]; then
  echo -e "${GREEN}✓ exists${NC}"
  if [[ -f "$LOG_DIR/loct-hook.log" ]]; then
    LINES=$(wc -l < "$LOG_DIR/loct-hook.log" 2>/dev/null | tr -d ' ')
    echo "   loct-hook.log: $LINES lines"
  fi
else
  echo -e "${YELLOW}⚠ not created yet (will be created on first hook run)${NC}"
fi

# Summary
echo ""
echo "========================================"
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Restart Claude Code or run /clear"
  echo "  2. Search for a symbol (e.g., 'useState')"
  echo "  3. Watch the log: tail -f ~/.claude/logs/loct-hook.log"
else
  echo -e "${RED}✗ $ERRORS issue(s) found${NC}"
  echo ""
  echo "Fix the issues above and run this script again."
fi
echo "========================================"

exit $ERRORS
