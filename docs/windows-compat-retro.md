# Windows Compatibility Retrospective — Muster v5.0.0

**Reported by**: Truck It team (Amandeep Singh Jhajj)
**Date**: 2026-11-15
**Environment**: Windows 11 Home, Git for Windows / Git Bash, PowerShell 5.1, Claude Code CLI

---

## Summary

**Platform context**: Muster's shell scripts were written for macOS/Linux bash.
Windows support is not documented and requires manual workarounds. This
retrospective is the first field report from a Windows 11 user running the
autonomous sprint loop via PowerShell + Git for Windows.

A developer on Windows 11 attempted to run the autonomous sprint loop
(`muster-sprint-run.sh`) from PowerShell for the first time. Five sequential
blockers were encountered. All are Windows-specific — the scripts work
correctly on macOS/Linux.

This document records each issue, its root cause, the workaround applied, and
the recommended permanent fix.

---

## Issue 1 — All `.sh` scripts break immediately on Windows checkout

**Symptom**
```
: invalid option name-sprint-run.sh: line 6: set: pipefail
muster/scripts/muster-sprint-run.sh: line 7: $'\r': command not found
muster/scripts/muster-sprint-run.sh: line 44: syntax error near unexpected token `newline'
```

**Root cause**

The muster repo has no `.gitattributes` file. Git for Windows defaults to
`core.autocrlf=true`, which converts every `LF` to `CRLF` on checkout. Bash
treats the `\r` as part of commands and fails on the very first line of every
script.

**Workaround applied**

Strip CRLF from all scripts in the working copy:
```bash
sed -i 's/\r//' muster/scripts/*.sh
```

**Recommended fix**

Add `.gitattributes` to the muster repo:
```
*.sh text eol=lf
```

This tells Git to always check out `.sh` files with LF regardless of
`core.autocrlf`. It is the standard fix and requires zero developer action after
it lands. **This fix is included in this PR.**

---

## Issue 2 — Worktree guard fires "Not a git repo" on non-interactive bash

**Symptom**

After fixing CRLF, the sprint loop exits immediately:
```
⛔ Not a git repo.
```

**Root cause**

`muster-guard-worktree.sh` calls `git rev-parse --git-dir` to verify it is
running from a git worktree (not the primary checkout). When PowerShell invokes
`bash muster/scripts/muster-sprint-run.sh` as a non-interactive, non-login
shell, `git` is not on the PATH — Git for Windows adds it to PATH only for
interactive sessions (`.bashrc`/`.bash_profile` are not sourced). The command
returns a non-zero exit code, triggering the "Not a git repo" branch instead of
the intended "Refusing to run on primary checkout" message.

The directory **was** a valid linked worktree (`.git` is a file, not a
directory, containing `gitdir: .../worktrees/...`).

**Workaround applied**

The `MUSTER_SPRINT_ALLOW_PRIMARY=1` override was attempted first (via
`$env:MUSTER_SPRINT_ALLOW_PRIMARY = "1"; bash ...` in PowerShell) but the
environment variable was not inherited by the bash subprocess — likely because
the bash binary resolves differently in non-interactive PowerShell invocations
on this system.

**Recommended fix**

Fall back to a filesystem check when `git` is not in PATH. In a linked worktree,
`.git` is always a **file**; in a primary checkout it is a **directory**; in a
non-git directory neither exists:

```bash
if gitdir="$(git rev-parse --git-dir 2>/dev/null)"; then
  # git available — use it (authoritative)
  case "$gitdir" in
    */worktrees/*) : ;;
    *) echo "⛔ Refusing to run on the primary checkout..."; exit 1 ;;
  esac
elif [ -f .git ]; then
  : # .git file → linked worktree confirmed (git not in PATH — filesystem fallback)
elif [ -d .git ]; then
  echo "⛔ Refusing to run on the primary checkout..."; exit 1
else
  echo "⛔ Not a git repo."; exit 1
fi
```

**This fix is included in this PR.**

---

## Issue 3 — `MUSTER_SPRINT_ALLOW_PRIMARY=1` override not usable from PowerShell

**Symptom**

The documented override (`MUSTER_SPRINT_ALLOW_PRIMARY=1 bash ...`) is a
Unix inline env-var prefix — a PowerShell parse error:
```
MUSTER_SPRINT_ALLOW_PRIMARY=1 : The term 'MUSTER_SPRINT_ALLOW_PRIMARY=1'
is not recognized as the name of a cmdlet...
```

**Root cause**

PowerShell does not support the Unix `VAR=value command` syntax. The equivalent
PowerShell form (`$env:VAR = "1"; command`) sets the variable in the PowerShell
session, but due to how `bash` resolves its environment on this system, the
variable was not inherited by the subprocess.

**Recommended fixes**

Two complementary improvements:

1. **Document the PowerShell equivalent** in `muster-guard-worktree.sh`'s
   override message:
   ```
   PowerShell: $env:MUSTER_SPRINT_ALLOW_PRIMARY = "1"; bash muster/scripts/muster-sprint-run.sh
   Unix:       MUSTER_SPRINT_ALLOW_PRIMARY=1 bash muster/scripts/muster-sprint-run.sh
   ```

2. **Add a `.muster/config` read before the guard** so project teams can
   commit `MUSTER_SPRINT_ALLOW_PRIMARY=1` to their `.muster/config` and avoid
   the env-var problem entirely. Currently the config is read AFTER the guard
   sources, making it unusable for this purpose.

**This fix is NOT yet in this PR** — the filesystem fallback (Issue 2 fix) makes
it moot for the linked-worktree case, but the documentation improvement and
config-before-guard reordering are worth pursuing.

---

## Issue 4 — `founder-notices.md` missing causes a non-fatal shell error on startup

**Symptom**

On sprint loop start:
```
muster/scripts/muster-sprint-run.sh: line 156: knowledge-base/founder-notices.md: No such file or directory
```

**Root cause**

`muster-sprint-run.sh` line 156 reads:
```bash
notices_seen="$(wc -l < "$NOTICES" 2>/dev/null | tr -d ' ')"; notices_seen="${notices_seen:-0}"
```

The `2>/dev/null` suppresses the error on the `wc -l` call, but on Windows the
shell error is emitted before redirection takes effect for the `<` input
redirect. The script continues normally (the variable defaults to `0`), but the
error message is alarming to new users.

**Recommended fix**

Guard the read with a file-existence check:
```bash
if [ -f "$NOTICES" ]; then
  notices_seen="$(wc -l < "$NOTICES" | tr -d ' ')"
else
  notices_seen=0
fi
```

Or create `knowledge-base/founder-notices.md` as part of the project scaffold
(`setup-project.sh` / `setup-existing-project.sh`).

---

## Issue 5 — `jq` not installed: formatter falls back to raw JSON

**Symptom**

The sprint loop terminal floods with raw stream-json events
(`thinking_tokens`, `assistant`, `user` JSON objects) instead of the clean
human-readable trail (📖 reads, ✏️ edits, 🧪 bash runs).

**Root cause**

`muster-sprint-format.sh` checks for `jq` at startup:
```bash
if ! command -v jq >/dev/null 2>&1; then
  if [ -n "$RAWLOG" ]; then tee -a "$RAWLOG"; else cat; fi
  exit 0
fi
```

`jq` is not pre-installed on Windows. Without it, the formatter passes every
raw event to the terminal unfiltered. The sprint runs correctly — the output is
just unreadable.

**Workaround applied**

```powershell
winget install jqlang.jq
```

Then restart the terminal so the new PATH is picked up.

**Recommended fix**

Document `jq` as a required dependency for Windows in a `docs/windows-setup.md`
guide. Optionally add a preflight check in `muster-sprint-run.sh` that warns
(not blocks) when `jq` is missing:
```bash
command -v jq >/dev/null 2>&1 || \
  echo "⚠ jq not found — install it for formatted output (winget install jqlang.jq)"
```

---

## Suggested Enhancements for Next Release

| # | Enhancement | Priority |
|---|-------------|----------|
| 1 | Add `.gitattributes` with `*.sh text eol=lf` | **Critical** — blocks Windows entirely |
| 2 | Worktree guard filesystem fallback when `git` not in PATH | **High** — blocks sprint loop on Windows |
| 3 | Add `docs/windows-setup.md` with prerequisites (Git for Windows, jq, etc.) | **High** — no Windows onboarding docs exist |
| 4 | Warn on missing `jq` at sprint startup (non-blocking) | **Medium** |
| 5 | Document PowerShell env-var syntax in guard override message | **Medium** |
| 6 | Read `.muster/config` before guard sources (not after) | **Medium** |
| 7 | Guard `founder-notices.md` read with file-existence check | **Low** |
| 8 | `setup-project.sh` creates `knowledge-base/founder-notices.md` | **Low** |

---

## What Was Already Fixed in This PR

- `.gitattributes` added to enforce `*.sh eol=lf` (Issue 1)
- `muster-guard-worktree.sh` updated with filesystem fallback (Issue 2)
- All existing scripts re-normalized from CRLF to LF (one-time cleanup)
