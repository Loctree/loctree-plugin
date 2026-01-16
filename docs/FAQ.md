# Frequently Asked Questions

## General

### What is loctree?

Loctree is a code intelligence tool that provides semantic understanding of your codebase. Unlike text-based search (grep), loctree understands:
- Where symbols are **defined** (not just mentioned)
- What **depends** on each file
- What code is **unused** (dead code)
- **Similar** symbols (semantic matching)

### Why use loctree instead of grep?

| Feature | grep | loctree |
|---------|------|---------|
| Find text matches | ✓ | ✓ |
| Find definitions | ✗ | ✓ |
| Semantic similarity | ✗ | ✓ |
| Dependency graph | ✗ | ✓ |
| Dead code detection | ✗ | ✓ |
| Impact analysis | ✗ | ✓ |

### Do I need to run `loct scan` manually?

**No.** Loctree automatically scans and caches on first use. The first search takes ~15s, subsequent searches take ~0.3s.

Running `loct scan` manually is optional - it just pre-warms the cache before your first search.

### What languages does loctree support?

- TypeScript / JavaScript
- Rust
- Python
- Go
- Vue / Svelte
- CSS / SCSS

See [supported languages](https://loct.io/docs/languages) for the full list.

---

## Installation

### How do I install loctree CLI?

```bash
cargo install loctree
```

Or with Homebrew:
```bash
brew install loctree
```

### "loct: command not found" - what do I do?

Add Cargo's bin directory to your PATH:

```bash
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### How do I verify the plugin is working?

1. Open Claude Code in a project
2. Search for any symbol (e.g., "useState")
3. Check if you see "LOCTREE CONTEXT" in the response
4. Or watch the log: `tail -f ~/.claude/logs/loct-hook.log`

---

## Usage

### Why is the first search slow?

On first search, loctree scans your entire codebase and creates a cached snapshot in `.loctree/`. This takes ~15s for a medium-sized project.

Subsequent searches use the cache and complete in ~0.3s.

### What patterns trigger the hook?

The hook recognizes:
- **PascalCase**: `UserService`, `AuthProvider`
- **camelCase**: `useAuth`, `handleClick`
- **snake_case**: `user_service`, `handle_request`
- **React hooks**: `useAuth`, `useState`
- **Event handlers**: `onClick`, `handleSubmit`
- **Health keywords**: `dead`, `unused`, `orphan`, `cycle`

### Can I search for multiple symbols at once?

Yes! Use pipe `|` to search for multiple symbols:

```
useAuth|useSession
```

The hook will transform this to `loct find "useAuth|useSession"`.

### What's the `.loctree/` directory?

This is loctree's cache directory containing:
- `snapshot.json` - Symbol index
- `files.json` - File metadata
- `graph.json` - Dependency graph

It's auto-generated and should be added to `.gitignore`.

---

## Troubleshooting

### Hooks aren't triggering

1. **Check hooks are executable**:
   ```bash
   chmod +x ~/.claude/hooks/loct-*.sh
   ```

2. **Verify settings.json**:
   ```bash
   cat ~/.claude/settings.json | jq '.hooks.PostToolUse'
   ```

3. **Restart Claude Code** or run `/clear`

### "No snapshot found" appears every time

This message appears only on first search in a project. If it appears repeatedly, check:
- You have write permission in the project directory
- The `.loctree/` directory exists after the first search

### Hook output is empty

Check the hook log for errors:
```bash
tail -50 ~/.claude/logs/loct-hook.log
```

Common issues:
- `loct` not in PATH
- `jq` not installed
- Hook script has syntax error

### Search returns no results

- Ensure you're searching for actual symbol names, not descriptions
- Check if the symbol exists: `loct find "YourSymbol"` manually
- Verify the project has source files loctree can parse

---

## Advanced

### Can I customize the hook behavior?

Yes, environment variables control hook behavior:

```bash
# Custom log file location
export LOCT_HOOK_LOG_FILE=~/my-custom.log

# Disable logging
export LOCT_HOOK_LOG_FILE=/dev/null
```

### How do I add hooks for other tools?

Edit `~/.claude/settings.json` and add a new matcher:

```json
{
  "matcher": "YourToolName",
  "hooks": [
    {
      "type": "command",
      "command": "bash ~/.claude/hooks/your-hook.sh"
    }
  ]
}
```

### Can I use loctree without the Claude Code plugin?

Yes! The `loct` CLI works standalone:

```bash
loct find "useAuth"          # Find symbol
loct slice src/hooks/auth.ts # File context
loct impact src/hooks/auth.ts # What depends on this
loct health                  # Dead code check
```

### How do I update the plugin?

```bash
# Update loctree CLI
cargo install loctree --force

# Update hook scripts
cd ~/loctree-plugin && git pull
cp hooks/*.sh ~/.claude/hooks/
```

---

## Performance

### How large of a codebase can loctree handle?

Loctree handles large codebases well:
- **Small** (<10K LOC): ~5s initial scan
- **Medium** (10-100K LOC): ~15s initial scan
- **Large** (100K-1M LOC): ~60s initial scan

After initial scan, all queries complete in <1s.

### Does loctree slow down Claude Code?

No. Hooks run asynchronously after tool completion. Claude receives the context as additional information - it doesn't wait for the hook.

### Can I disable hooks for performance?

Remove the PostToolUse section from `~/.claude/settings.json` to disable all loctree hooks.

---

*Created by M&K (c)2026 VetCoders*
