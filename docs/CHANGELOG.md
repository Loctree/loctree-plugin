# Changelog

All notable changes to the Loctree Plugin for Claude Code.

## [1.0.0] - 2026-01-16

### Added
- Initial public release
- `loct-grep-augment.sh` v14 - Search augmentation for Grep and Bash tools
- `loct-read-context.sh` v1 - File context injection for Read tool
- `loct-edit-warning.sh` v2 - Impact warnings for Edit tool
- Comprehensive documentation (INSTALLATION, QUICK_START, ARCHITECTURE, FAQ)
- Skill definition with commands reference
- Claude Code marketplace manifest

### Features
- **Pattern Recognition**: PascalCase, camelCase, snake_case, React hooks, event handlers
- **Multi-term Search**: Support for `|` alternation (e.g., `useAuth|useSession`)
- **Auto-caching**: First search creates snapshot, subsequent searches use cache
- **Live Logging**: All hook activity logged to `~/.claude/logs/loct-hook.log`
- **32KB Payload Limit**: Prevents context bloat
- **Smart Routing**: Automatic detection of file paths, directories, health queries

---

## Hook Version History

### loct-grep-augment.sh

| Version | Changes |
|---------|---------|
| v14 | Snake_case support, CWD fix, output cap (32KB) |
| v13 | Multi-term search with `\|` alternation |
| v12 | Python shlex for robust shell parsing |
| v11 | Session CWD support for relative paths |
| v10 | Health keyword detection (dead, unused, cycle) |

### loct-read-context.sh

| Version | Changes |
|---------|---------|
| v1 | Initial release - slice + impact context |

### loct-edit-warning.sh

| Version | Changes |
|---------|---------|
| v2 | Threshold-based warnings (>10 consumers) |
| v1 | Initial release - basic impact warning |

---

## Loctree CLI Compatibility

| Plugin Version | Minimum CLI Version |
|----------------|---------------------|
| 1.0.0 | loctree 0.8.0 |

---

*Created by M&K (c)2026 VetCoders*
