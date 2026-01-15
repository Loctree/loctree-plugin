# /loctree:health - Codebase Health Check

Run a comprehensive health analysis of the current codebase.

## Usage

```
/loctree:health
```

## What It Does

1. Runs `loct health` to analyze the codebase
2. Reports:
   - Dead exports (unused code)
   - Circular dependencies
   - Duplicate exports
   - Overall health score

## Instructions

When this command is invoked:

1. Run `loct health` in the project root
2. Summarize the findings:
   - List any HIGH severity issues first
   - Provide actionable suggestions for each issue
   - Report the overall health score

3. If there are dead exports, suggest files that can be safely deleted.

4. If there are circular dependencies, explain the cycle and suggest how to break it.

## Example Output

```
Codebase Health Report
======================

Health Score: 78/100

Issues Found:
- 3 dead exports (unused code)
- 1 circular dependency cycle

Dead Exports:
- src/utils/deprecated.ts:oldHelper (not imported anywhere)
- src/api/legacy.ts:LegacyClient (not imported anywhere)

Circular Dependencies:
- src/a.ts → src/b.ts → src/c.ts → src/a.ts
  Suggestion: Move shared types to src/types/shared.ts

Quick Wins:
- Delete src/utils/deprecated.ts (saves 45 LOC)
- Break cycle at src/b.ts → src/c.ts
```
