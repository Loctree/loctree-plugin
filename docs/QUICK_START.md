# Quick Start Guide

Get semantic code intelligence in Claude Code in under 5 minutes.

## What You'll Learn

1. How loctree automatically augments your searches
2. How file context is injected when reading code
3. How to use the live debug log

## Prerequisites

- Loctree plugin installed ([Installation Guide](./INSTALLATION.md))
- A project with source code (TypeScript, Rust, Python, etc.)

---

## Step 1: Your First Augmented Search

Open Claude Code in your project directory and search for a symbol:

```
You: Find where useAuth is defined
Claude: [Uses Grep tool to search for "useAuth"]
```

**What happens behind the scenes:**

```
┌─────────────────────────────────────────────────────────┐
│ 1. Claude runs: Grep "useAuth"                          │
│ 2. Hook intercepts the search                           │
│ 3. Hook transforms: loct find "useAuth"                 │
│ 4. Loctree returns semantic results                     │
│ 5. Claude receives BOTH grep results AND:               │
│    - Symbol definitions (where it's declared)           │
│    - Semantic matches (similar names)                   │
│    - Dead code status (is it used?)                     │
└─────────────────────────────────────────────────────────┘
```

**Example output Claude sees:**

```
Found 5 files (grep results)

LOCTREE CONTEXT:
=== Symbol Matches (2) ===
  File: src/hooks/useAuth.ts
    [DEF] src/hooks/useAuth.ts:15 - export function useAuth
  File: src/contexts/AuthContext.tsx
    [DEF] src/contexts/AuthContext.tsx:42 - export const useAuth

=== Semantic Matches (8) ===
  useAuth (score: 1.00) in src/hooks/useAuth.ts
  useAuthState (score: 0.67) in src/hooks/useAuthState.ts
  AuthProvider (score: 0.54) in src/contexts/AuthContext.tsx
  ...

=== Dead Code Status ===
  OK: Symbol is used.
```

---

## Step 2: File Context on Read

When Claude reads a source file, loctree automatically adds context:

```
You: Show me the useAuth hook implementation
Claude: [Uses Read tool on src/hooks/useAuth.ts]
```

**Claude automatically receives:**

```
LOCTREE FILE CONTEXT:
--- FILE STRUCTURE (slice) ---
Core (1 files, 85 LOC):
  hooks/useAuth.ts (85 LOC, ts)

Deps (4 files, 320 LOC):
  [d1] contexts/AuthContext.tsx (120 LOC)
  [d1] services/authService.ts (95 LOC)
  [d2] utils/storage.ts (55 LOC)
  [d2] types/auth.ts (50 LOC)

Total: 5 files, 405 LOC

--- IMPACT ANALYSIS ---
Direct consumers (3 files):
  components/LoginForm.tsx (import)
  components/ProtectedRoute.tsx (import)
  hooks/index.ts (reexport)

Transitive impact (12 files):
  [depth 2] pages/Dashboard.tsx
  [depth 2] pages/Settings.tsx
  ...

[!] Removing this file would affect 15 files (max depth: 4)
```

---

## Step 3: Watch the Debug Log

Open a terminal and watch the hook activity in real-time:

```bash
tail -f ~/.claude/logs/loct-hook.log
```

**Example log output:**

```
==== CLAUDE: Grep ====
time:    2026-01-16 10:30:45
pattern: useAuth
path:    src/
result:  5 files (files_with_matches)
  -> src/hooks/useAuth.ts
  -> src/contexts/AuthContext.tsx
============================

---- LOCT CALL ----
time: 2026-01-16 10:30:45
cwd:  /Users/you/myproject
ms:   287
exit: 0
cmd:  loct find useAuth
output:
  === Symbol Matches (2) ===
  ...
-------------------
```

This shows exactly what Claude searched for and what loctree found.

---

## Step 4: Try Different Search Patterns

The hook recognizes various patterns:

| You Search For | Hook Transforms To | Result |
|----------------|-------------------|--------|
| `UserService` | `loct find UserService` | PascalCase symbol |
| `handle_request` | `loct find handle_request` | snake_case symbol |
| `useAuth` | `loct find useAuth` | React hook |
| `dead\|unused` | `loct health` | Health check |
| `src/hooks/` | `loct focus src/hooks/` | Directory analysis |

---

## What's Next?

- **Deep dive into hooks**: Read [HOOKS.md](../HOOKS.md) for configuration options
- **Architecture overview**: See [ARCHITECTURE.md](./ARCHITECTURE.md) for how it works
- **Common questions**: Check [FAQ.md](./FAQ.md)

---

## Tips for Best Results

1. **Use symbol names, not descriptions**: Search for `UserService` not "the user service class"

2. **First search is slow**: Loctree scans and caches on first use (~15s). Subsequent searches are fast (~0.3s).

3. **Watch the log**: `tail -f ~/.claude/logs/loct-hook.log` shows what's happening

4. **Snake_case and camelCase both work**: `user_service` and `userService` are both recognized

5. **Multi-term searches work**: `useAuth|useSession` finds both symbols

---

*Created by M&K (c)2026 VetCoders*
