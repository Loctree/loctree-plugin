<p align="center">
  <img src="assets/loctree-logo.png" alt="Loctree Logo" width="400">
</p>

<h1 align="center">Loctree Plugin for Claude Code</h1>

<p align="center">
  <strong>A holographic map of code for AI agents.</strong><br>
  When Claude searches, loctree understands.
</p>

<p align="center">
  <a href="https://loct.io">Website</a> •
  <a href="https://github.com/Loctree/loctree-suite">CLI & MCP</a> •
  <a href="#installation">Install</a>
</p>

---

```
┌─────────────────────────────────────────────────────────────┐
│ Claude runs: grep "canonical_model.*vision"                 │
│                         ↓                                   │
│ Hook detects pattern, transforms: canonical_model|vision    │
│                         ↓                                   │
│ loct find "canonical_model|vision"                          │
│                         ↓                                   │
│ LOCTREE CONTEXT ADDED TO RESPONSE:                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Symbol Matches (5):                                     │ │
│ │   types/ai.rs:88      canonical_model (field)           │ │
│ │   vision/prompt.rs:12 vision_prompt (function)          │ │
│ │   chat/commands.rs:533 canonical_model: "vision"        │ │
│ │                                                         │ │
│ │ Semantic Matches: vision_analysis, model_config         │ │
│ │ Cross-Match Files: chat/commands.rs has BOTH terms      │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## The Problem

Claude Code's built-in search tools (Grep, ripgrep) find **text matches**. But you need **code understanding**:

- Where is `MyComponent` **defined**?
- What **imports** this file?
- What would **break** if I change this?
- Is this code **actually used**?

## The Solution

Loctree automatically augments Claude's searches with semantic context:

| Claude Searches | Claude Receives |
|-----------------|-----------------|
| `grep "UserService"` | 10 text matches |
| `grep "UserService"` + loctree hook | 10 text matches **+ 47 symbol definitions + usages + dead code status** |

**Zero friction.** No manual commands. Just search normally.

## Features

### Automatic Search Augmentation

The PostToolUse hook intercepts Grep/Bash searches and adds:

- **Symbol definitions** (where code is declared)
- **Semantic matches** (similar names)
- **Cross-match files** (files with multiple query terms)
- **Dead code status** (is it actually used?)

### Smart Pattern Recognition

| Pattern | Detection | Action |
|---------|-----------|--------|
| `PascalCase` | Component/Class | `loct find` |
| `camelCase` | Function/Variable | `loct find` |
| `snake_case` | Rust/Python/Tauri | `loct find` |
| `A.*B` or `A\|B` | Multi-term regex | Transform & search both |
| `path/to/file.ts` | File path | `loct slice` |
| `src/api/` | Directory | `loct focus` |

### Deep Analysis Commands

```bash
loct --for-ai          # Codebase overview (start here!)
loct find <symbol>     # Symbol search with semantics
loct impact <file>     # What breaks if I change this?
loct slice <file>      # Minimal dependency context
loct health            # Dead code, cycles, duplicates
```

## Installation

### 1. Install loctree CLI

```bash
cargo install loctree
# or
brew install loctree
```

### 2. Install the plugin

In Claude Code:

```
/plugin marketplace add Loctree/loctree-plugin
/plugin install loctree
```

### 3. Initialize your project

```bash
cd your-project
loct scan
```

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Claude Code Session                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. You ask: "Find where UserAuth is defined"               │
│                    ↓                                        │
│  2. Claude runs: grep "UserAuth"                            │
│                    ↓                                        │
│  3. PostToolUse Hook activates                              │
│     - Detects "UserAuth" = PascalCase symbol                │
│     - Runs: loct find "UserAuth"                            │
│                    ↓                                        │
│  4. Hook adds to response:                                  │
│     ┌─────────────────────────────────────────────────┐    │
│     │ LOCTREE CONTEXT                                  │    │
│     │ ─────────────────                                │    │
│     │ Symbol Matches (3):                              │    │
│     │   src/auth/UserAuth.ts:15 (definition)          │    │
│     │   src/hooks/useUserAuth.ts:8 (usage)            │    │
│     │   src/api/auth.ts:42 (usage)                    │    │
│     │                                                  │    │
│     │ Dead Code Status: USED (imported by 7 files)    │    │
│     └─────────────────────────────────────────────────┘    │
│                                                             │
│  5. Claude now understands the codebase structure!          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## vs. ast-grep

| Feature | ast-grep | loctree |
|---------|----------|---------|
| **Activation** | Manual ("Use ast-grep to...") | **Automatic** (hook-based) |
| **Learning curve** | Write AST patterns | **Zero** - just grep normally |
| **Focus** | Pattern matching | **Codebase understanding** |
| **Dead code** | ❌ | ✅ |
| **Dependency graph** | ❌ | ✅ |
| **Impact analysis** | ❌ | ✅ |

## Supported Languages

- TypeScript / JavaScript / JSX / TSX
- Rust
- Python
- Vue / Svelte
- CSS / SCSS

## Requirements

- Claude Code v1.0.0+
- loctree CLI v0.8.0+
- Git repository with `.loctree/` initialized

## Performance

| Operation | Time |
|-----------|------|
| `loct find` | ~280ms |
| `loct impact` | ~50ms |
| `loct slice` | ~80ms |
| `loct health` | ~370ms |

Hook overhead: **< 300ms** per augmented search.

## Contributing

- [loctree-suite](https://github.com/Loctree/loctree-suite) - Core CLI and MCP server
- [Issues](https://github.com/Loctree/loctree-plugin/issues) - Bug reports and feature requests

## License

MIT License - see [LICENSE](LICENSE)

---

**Made with (งಠ_ಠ)ง by the ⌜ Loctree ⌟ 𝖙𝖊𝖆𝖒 (c) 2026
Maciej & Monika + Klaudiusz (AI)**
