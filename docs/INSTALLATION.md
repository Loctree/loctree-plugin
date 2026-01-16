# Installation Guide

Complete step-by-step guide for installing the Loctree Plugin for Claude Code.

## Prerequisites

Before installing the plugin, ensure you have:

- **Claude Code** (latest version) - [claude.ai/code](https://claude.ai/code)
- **Rust toolchain** - For installing loctree CLI
- **jq** - For JSON processing in hooks
- **Python 3** - For shell command parsing (usually pre-installed on macOS/Linux)

## Step 1: Install Loctree CLI

The plugin requires the `loctree` CLI tool. Install it using Cargo (Rust's package manager):

```bash
# Install Rust if you don't have it
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install loctree
cargo install loctree

# Verify installation
loct --version
# Expected: loctree 0.8.x or higher
```

### Alternative Installation Methods

```bash
# macOS with Homebrew (if available)
brew install loctree

# Or build from source
git clone https://github.com/Loctree/loctree-suite.git
cd loctree-suite
cargo install --path crates/loctree
```

### Verify loctree is in PATH

```bash
which loct
# Expected: /Users/yourname/.cargo/bin/loct

# If not found, add to your shell profile:
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Step 2: Install jq (if not present)

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Verify
jq --version
# Expected: jq-1.6 or higher
```

## Step 3: Install the Plugin

### Option A: From Claude Code Marketplace (Recommended)

```
/plugin marketplace add Loctree/loctree-plugin
/plugin install loctree
```

### Option B: Manual Installation

1. **Clone the plugin repository:**

```bash
git clone https://github.com/Loctree/loctree-plugin.git ~/loctree-plugin
```

2. **Copy hook scripts to Claude Code hooks directory:**

```bash
mkdir -p ~/.claude/hooks
cp ~/loctree-plugin/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/loct-*.sh
```

3. **Register hooks in Claude Code settings:**

Edit `~/.claude/settings.json` and add the PostToolUse hooks:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Grep",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/loct-grep-augment.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/loct-grep-augment.sh --bash-filter"
          }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/loct-read-context.sh"
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/loct-edit-warning.sh"
          }
        ]
      }
    ]
  }
}
```

4. **Install the skill (optional):**

```bash
mkdir -p ~/.claude/skills
cp -r ~/loctree-plugin/skills/loctree ~/.claude/skills/
```

## Step 4: Initialize Your Project (Optional)

Loctree **automatically creates a snapshot** on first search and caches it for subsequent calls:

```
First search:  ~15s (scans codebase, creates .loctree/)
Second search: ~0.3s (uses cached snapshot)
```

If you want to pre-warm the cache before your first search:

```bash
cd /path/to/your/project
loct scan  # Optional - creates snapshot proactively

# Verify snapshot was created
ls -la .loctree/
# Expected: snapshot.json and other index files
```

> **Note:** The `.loctree/` directory is auto-generated. Add it to `.gitignore` if not already present.

## Step 5: Verify Installation

Run this verification script to check everything is set up correctly:

```bash
# Check loctree CLI
echo -n "loctree CLI: "
loct --version 2>/dev/null && echo "✓" || echo "✗ NOT FOUND"

# Check jq
echo -n "jq: "
jq --version 2>/dev/null && echo "✓" || echo "✗ NOT FOUND"

# Check hooks are executable
echo "Hooks:"
for hook in ~/.claude/hooks/loct-*.sh; do
  echo -n "  $(basename $hook): "
  [[ -x "$hook" ]] && echo "✓ executable" || echo "✗ not executable"
done

# Check settings.json has PostToolUse
echo -n "PostToolUse hooks configured: "
cat ~/.claude/settings.json 2>/dev/null | jq -e '.hooks.PostToolUse' >/dev/null 2>&1 && echo "✓" || echo "✗"
```

Expected output:
```
loctree CLI: loctree 0.8.7 ✓
jq: jq-1.7.1 ✓
Hooks:
  loct-edit-warning.sh: ✓ executable
  loct-grep-augment.sh: ✓ executable
  loct-read-context.sh: ✓ executable
PostToolUse hooks configured: ✓
```

## Step 6: Restart Claude Code

After installation, restart Claude Code or run `/clear` to load the new hooks.

## Troubleshooting

### "loct: command not found"

Ensure `~/.cargo/bin` is in your PATH:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

Add this line to `~/.zshrc` or `~/.bashrc` for persistence.

### Hooks not triggering

1. Check hooks are executable: `chmod +x ~/.claude/hooks/loct-*.sh`
2. Verify settings.json syntax: `jq . ~/.claude/settings.json`
3. Check hook logs: `tail -f ~/.claude/logs/loct-hook.log`

### First search is slow (~15s)

This is normal - loctree scans the codebase and creates a cached snapshot in `.loctree/`. Subsequent searches will be fast (~0.3s).

If you want to avoid the initial delay, run `loct scan` before your first search session.

### "No snapshot found" message

This informational message appears only on the first search. Loctree automatically creates and caches the snapshot - no action required.

## Next Steps

- Read the [Quick Start Guide](./QUICK_START.md) for a 5-minute tutorial
- Check [HOOKS.md](./HOOKS.md) for hook configuration details
- See [FAQ](./FAQ.md) for common questions

---

*Created by M&K (c)2026 VetCoders*
