# Architecture

How the Loctree Plugin integrates with Claude Code.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   User: "Find where useAuth is defined"                          │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │         Claude (LLM)                  │                      │
│   │   Decides to use Grep tool            │                      │
│   └──────────────────────────────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │         Grep Tool                     │                      │
│   │   pattern: "useAuth"                  │                      │
│   │   result: 5 files                     │                      │
│   └──────────────────────────────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │      PostToolUse Hook System          │◄─── hooks.json      │
│   │   matcher: "Grep"                     │                      │
│   └──────────────────────────────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │    loct-grep-augment.sh              │                      │
│   │                                       │                      │
│   │  1. Parse hook input (JSON)           │                      │
│   │  2. Extract pattern: "useAuth"        │                      │
│   │  3. Detect pattern type (camelCase)   │                      │
│   │  4. Run: loct find "useAuth"          │                      │
│   │  5. Format output as JSON             │                      │
│   └──────────────────────────────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │         Loctree CLI                   │                      │
│   │                                       │                      │
│   │  - Reads .loctree/snapshot.json       │                      │
│   │  - Symbol search (AST-based)          │                      │
│   │  - Semantic matching (fuzzy)          │                      │
│   │  - Dead code detection                │                      │
│   └──────────────────────────────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │     Hook Output (JSON)                │                      │
│   │                                       │                      │
│   │  {                                    │                      │
│   │    "hookSpecificOutput": {            │                      │
│   │      "additionalContext": "..."       │◄─── Injected to LLM │
│   │    }                                  │                      │
│   │  }                                    │                      │
│   └──────────────────────────────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────────────────────────────────┐                      │
│   │         Claude (LLM)                  │                      │
│   │                                       │                      │
│   │   Now has:                            │                      │
│   │   - Original grep results (5 files)   │                      │
│   │   - Symbol definitions                │                      │
│   │   - Semantic matches                  │                      │
│   │   - Dead code status                  │                      │
│   └──────────────────────────────────────┘                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Hook Registration (`hooks/hooks.json`)

Defines which tools trigger which hooks:

```json
{
  "hooks": [
    {
      "event": "PostToolUse",
      "matcher": { "tool_name": "Grep" },
      "command": "bash ~/.claude/hooks/loct-grep-augment.sh"
    },
    {
      "event": "PostToolUse",
      "matcher": { "tool_name": "Bash" },
      "command": "bash ~/.claude/hooks/loct-grep-augment.sh --bash-filter"
    },
    {
      "event": "PostToolUse",
      "matcher": { "tool_name": "Read" },
      "command": "bash ~/.claude/hooks/loct-read-context.sh"
    },
    {
      "event": "PostToolUse",
      "matcher": { "tool_name": "Edit" },
      "command": "bash ~/.claude/hooks/loct-edit-warning.sh"
    }
  ]
}
```

### 2. Hook Scripts

#### `loct-grep-augment.sh` (v14)

**Purpose**: Augment Grep and Bash searches with semantic context.

**Flow**:
1. Receive JSON input from Claude Code via stdin
2. Parse `tool_input.pattern` or `tool_input.command`
3. Detect pattern type (PascalCase, camelCase, snake_case, etc.)
4. Transform to appropriate loctree command
5. Execute loctree and capture output
6. Format as JSON and return via stdout

**Pattern Detection**:
```bash
# PascalCase → loct find
if printf '%s' "$PATTERN" | grep -qE '^[A-Z][a-zA-Z0-9]{2,}$'; then
  augment_symbol "$PATTERN"
fi

# camelCase → loct find
if printf '%s' "$PATTERN" | grep -qE '^[a-z]+[A-Z][a-zA-Z0-9]*$'; then
  augment_symbol "$PATTERN"
fi

# snake_case → loct find
if printf '%s' "$PATTERN" | grep -qE '^[a-z][a-z0-9]*_[a-z_0-9]+$'; then
  augment_symbol "$PATTERN"
fi

# Health keywords → loct health
if printf '%s' "$PATTERN" | grep -qiE 'dead|unused|orphan'; then
  augment_health
fi
```

#### `loct-read-context.sh` (v1)

**Purpose**: Add file structure and impact analysis when reading source files.

**Flow**:
1. Extract file path from `tool_input.file_path`
2. Run `loct slice <file>` for dependencies
3. Run `loct impact <file>` for consumers
4. Combine and return as additionalContext

#### `loct-edit-warning.sh` (v2)

**Purpose**: Warn about editing critical/high-impact files.

**Flow**:
1. Extract file path from `tool_input.file_path`
2. Run `loct impact <file>` to count consumers
3. If >10 consumers, add warning to context

### 3. Loctree CLI

The `loct` command-line tool provides the semantic analysis:

| Command | Purpose |
|---------|---------|
| `loct find <symbol>` | Search for symbol definitions |
| `loct slice <file>` | File structure with dependencies |
| `loct impact <file>` | What depends on this file |
| `loct health` | Dead code, cycles, duplicates |
| `loct scan` | Create/update snapshot |

### 4. Snapshot (`.loctree/`)

Loctree creates a snapshot of your codebase for fast queries:

```
.loctree/
├── snapshot.json      # Main index (symbols, imports, exports)
├── files.json         # File metadata
└── graph.json         # Dependency graph
```

**Auto-caching**: First query scans the codebase (~15s) and creates the snapshot. Subsequent queries use the cache (~0.3s).

## Data Flow

### Hook Input (from Claude Code)

```json
{
  "hook_event_name": "PostToolUse",
  "tool_name": "Grep",
  "tool_input": {
    "pattern": "useAuth",
    "path": "src/"
  },
  "tool_response": {
    "numFiles": 5,
    "filenames": ["src/hooks/useAuth.ts", ...]
  },
  "session_cwd": "/Users/you/myproject"
}
```

### Hook Output (to Claude Code)

```json
{
  "suppressOutput": true,
  "systemMessage": "LOCTREE | sym:2 sem:8 | 287ms",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "=== Symbol Matches (2) ===\n..."
  }
}
```

## Logging

All hook activity is logged to `~/.claude/logs/loct-hook.log`:

```
==== CLAUDE: Grep ====
time:    2026-01-16 10:30:45
pattern: useAuth
path:    src/
result:  5 files

---- LOCT CALL ----
time: 2026-01-16 10:30:45
ms:   287
cmd:  loct find useAuth
output:
  === Symbol Matches (2) ===
  ...
```

## Performance

| Operation | Cold (no snapshot) | Warm (with snapshot) |
|-----------|-------------------|---------------------|
| `loct find` | ~15s | ~0.3s |
| `loct slice` | ~15s | ~0.2s |
| `loct impact` | ~15s | ~0.2s |
| `loct health` | ~20s | ~0.5s |

The snapshot is automatically created on first query and reused for subsequent queries.

---

*Created by M&K (c)2026 VetCoders*
