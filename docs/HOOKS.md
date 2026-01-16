# Loctree Hooks — Technical Documentation

Detailed technical documentation for each hook in the loctree plugin.

---

## Table of Contents

- [Overview](#overview)
- [loct-grep-augment.sh](#loct-grep-augmentsh)
- [loct-read-context.sh](#loct-read-contextsh)
- [loct-edit-warning.sh](#loct-edit-warningsh)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

All hooks use the Claude Code `PostToolUse` event, which fires after a tool completes. Hooks output JSON to stdout in this format:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Context string shown to Claude..."
  }
}
```

The `additionalContext` content is injected into Claude's context window, giving it immediate awareness of codebase structure without manual commands.

### Requirements

- **loctree CLI** v0.8.0+ installed and in PATH
- **`.loctree/`** directory present (run `loct scan` in project root)
- **Source files** — hooks only activate for recognized source extensions

### Supported Extensions

```
.ts .tsx .js .jsx .mjs .cjs
.rs
.py
.vue .svelte
.css .scss
```

---

## loct-grep-augment.sh

**Version:** v14
**Matcher:** `Grep`, `Bash` (with `--bash-filter`)
**Purpose:** Augments grep/ripgrep searches with semantic symbol context

### What It Does

1. **Parses** the grep/rg command to extract the search pattern and path
2. **Transforms** regex patterns (e.g., `foo.*bar` → `foo|bar`)
3. **Runs** `loct find <pattern>` to get semantic matches
4. **Adds** symbol definitions, cross-matches, and dead code status

### Pattern Recognition

| Input Pattern | Detection | loctree Command |
|---------------|-----------|-----------------|
| `UserService` | PascalCase | `loct find "UserService"` |
| `handleClick` | camelCase | `loct find "handleClick"` |
| `user_service` | snake_case | `loct find "user_service"` |
| `foo.*bar` | Multi-term | `loct find "foo\|bar"` |
| `A\|B\|C` | Alternation | `loct find "A\|B\|C"` |
| `src/api/` | Directory | `loct focus "src/api/"` |
| `types.ts` | File path | `loct slice "types.ts"` + `loct impact` |

### Filtering

The hook skips augmentation for:

- **Heavy regex patterns** (3+ nested groups, 4+ wildcards, lookaheads)
- **Very short patterns** (< 3 characters)
- **Non-source directories** (node_modules, dist, .git)
- **Non-loctree repos** (no `.loctree/` directory)

### Output Cap

Output is truncated at **32KB** to prevent context overflow:

```
[...truncated, showing first 32768 bytes of 45000 total]
```

### Example Output

```
LOCTREE CONTEXT
repo: my-project
query: UserService

Symbol Matches (3):
  src/services/UserService.ts:15    UserService (class)
  src/api/users.ts:42               userService (instance)
  src/hooks/useUser.ts:8            UserService (import)

Cross-Match Files:
  src/api/users.ts contains BOTH: UserService, userService

Dead Code Status:
  UserService: USED (imported by 12 files)
```

### Bash Filter Mode

When called with `--bash-filter`, the hook:

1. Checks if the Bash command contains `rg` or `grep`
2. Extracts the pattern from the command
3. Proceeds with normal augmentation

---

## loct-read-context.sh

**Version:** v1
**Matcher:** `Read`
**Purpose:** Shows file structure and impact when Claude reads a source file

### What It Does

1. **Detects** if the read file is a source file
2. **Runs** `loct slice <file>` for structure analysis
3. **Runs** `loct impact <file>` for dependency analysis
4. **Combines** both into context for Claude

### When It Activates

- File has a recognized source extension
- File is in a loctree-indexed repo (`.loctree/` exists)
- File is not in excluded directories (node_modules, dist, tests)

### Example Output

```
LOCTREE FILE CONTEXT
repo: my-app
file: src/contexts/AppContext.tsx

--- FILE STRUCTURE (slice) ---
Core (1 files, 420 LOC)
├── src/contexts/AppContext.tsx
Deps (5 files, 1,890 LOC)
├── src/types/auth.ts
├── src/services/api.ts
└── ... (3 more)

--- IMPACT ANALYSIS ---
Direct consumers (12 files)
├── src/components/LoginForm.tsx
├── src/components/UserMenu.tsx
└── ... (10 more)

Transitive impact (38 files)
[!] Removing this file would affect 50 files
```

### Use Case

Before Claude edits a file, it knows:
- How complex the file is (LOC, dependencies)
- What other files depend on it
- The "blast radius" of potential changes

---

## loct-edit-warning.sh

**Version:** v2
**Matcher:** `Edit`
**Purpose:** Warns Claude after editing files with many dependents

### What It Does

1. **Runs** `loct impact <file>` after an edit completes
2. **Counts** direct consumers of the edited file
3. **Warns** if the file has 10+ direct consumers (configurable)
4. **Always** provides impact context, even for low-impact files

### Critical File Threshold

```bash
CRITICAL_THRESHOLD=10  # Files with 10+ direct consumers
```

### Example Output (Critical File)

```
[!] CRITICAL FILE: src/core/StateManager.tsx has 16 direct consumers
(67 total affected). Changes here have HIGH IMPACT.

--- IMPACT ANALYSIS ---
Direct consumers (16 files)
├── src/components/Layout.tsx
├── src/components/Sidebar.tsx
└── ... (14 more)

Transitive impact (51 files)
```

### Example Output (Normal File)

```
LOCTREE EDIT CONTEXT
file: src/utils/format.ts

--- IMPACT ANALYSIS ---
Direct consumers (3 files)
├── src/components/DataTable.tsx
├── src/views/Reports.tsx
└── src/services/export.ts

Transitive impact (8 files)
```

### Why PostToolUse?

The Edit hook uses `PostToolUse` (not `PreToolUse`) because:
- `PreToolUse` doesn't support `additionalContext` in Claude Code
- Post-edit warnings still provide value for subsequent decisions
- Claude can course-correct if it realizes a file was critical

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCT_DEBUG` | `0` | Set to `1` for debug logging |
| `LOCT_SKIP_HEAVY` | `1` | Skip heavy regex patterns |
| `SESSION_CWD` | (from Claude) | Working directory for the session |

### Debug Logging

Each hook writes debug logs:

```
$CLAUDE_LOCAL_DIR/logs/loct-grep-debug.log
$CLAUDE_LOCAL_DIR/logs/loct-read-debug.log
$CLAUDE_LOCAL_DIR/logs/loct-edit-debug.log
```

Enable verbose output:

```bash
export LOCT_DEBUG=1
```

---

## Troubleshooting

### Hook Not Firing

1. **Check `.loctree/` exists** in the project root:
   ```bash
   ls -la .loctree/
   ```

2. **Verify loctree CLI is installed:**
   ```bash
   loct --version
   ```

3. **Restart Claude Code** — hooks are cached at session start

4. **Check debug logs:**
   ```bash
   tail -50 $CLAUDE_LOCAL_DIR/logs/loct-grep-debug.log
   ```

### No Output for Searches

1. **Pattern too short** — patterns < 3 chars are skipped
2. **Heavy regex** — complex patterns are filtered
3. **Non-source path** — searches in node_modules/dist are skipped

### Wrong Context

1. **Check SESSION_CWD** — hook logs show the working directory
2. **Re-run `loct scan`** — index may be stale

### Performance Issues

1. **Large repos** — initial `loct scan` can take time
2. **Output cap** — 32KB limit prevents slowdowns
3. **Skip patterns** — configure `LOCT_SKIP_HEAVY=1`

---

## Version History

### v14 (2025-01-15)

**loct-grep-augment.sh:**
- Fix: cwd mismatch — parser no longer checks FS before cd
- Fix: output cap at 32KB with truncation notice
- Fix: heavy regex filter refined (nested groups, wildcards only)
- Fix: python3 fallback for systems without it

### v1 (2025-01-15)

**loct-read-context.sh:**
- Initial release
- Shows slice + impact for source files

### v2 (2025-01-15)

**loct-edit-warning.sh:**
- Changed from PreToolUse to PostToolUse (additionalContext support)
- Critical file threshold: 10+ direct consumers

---

**Made with (gom_gom)g by the Loctree team (c) 2026**
