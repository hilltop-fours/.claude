# CLAUDE.md — Router

Machine-optimized. Claude-facing only. No human reads or maintains this.
Zero-context-per-session: this file alone must be enough to route any task from a cold start.

---

## Ownership

Every file in `.claude/` is Claude-facing only. Claude owns and maintains this repo.
When writing or editing any `.claude/` file: dense format, no prose padding, no human-friendly explanations.

---

## Hook Rules

| Rule | Hook | Behavior | Comply by |
|------|------|----------|-----------|
| Git only from valid dirs | `check-git-repo.sh` | blocks (exit 2) | Always `git -C <abs-path>` or `cd <abs-path> && git` in same Bash call |
| Commit message format | `check-commit-message.sh` | blocks (exit 2) | Use heredoc syntax — hook can't parse heredocs, but still write correct format |
| File edits only in allowed paths | `check-edit-path.sh` | blocks (exit 2) | Never edit config files (package.json, angular.json, tsconfig.json) |
| No console.log/warn/error/debug | `check-console-log.sh` | blocks (exit 2) | Remove before staging. Allowed: console.info/table/time/trace |
| Push branch format | `check-push-branch.sh` | warns only (exit 0) | No action needed |
| Missing index.ts | `check-index-ts.sh` | warns only (exit 0) | After new file in src/, check if index.ts exists, create if missing |

**Allowed edit paths**: `*/.claude/**`, `~/.claude/**`, `*/ntm-frontend/src/**`, `*/traffic-sign-frontend/src/**`, `*/accessibility-map-frontend/src/**`, `*/areleon/**`

---

## Project Identification

Match cwd path to set `$CLAUDE_ROOT`:

| Path contains | Project | $CLAUDE_ROOT |
|---------------|---------|-------------|
| `/NTM-Publicatie-overzicht` | NTM | `/Users/daniel/Developer/NTM-Publicatie-overzicht/.claude` |
| `/GRG-Wegkenmerken-verkeersborden` | GRG | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/.claude` |
| `/BER-Bereikbaarheidskaart` | BER | `/Users/daniel/Developer/BER-Bereikbaarheidskaart/.claude` |

---

## Workflow Router

| Trigger | Load these files |
|---------|-----------------|
| New story / task / bug | `$CLAUDE_ROOT/global/stories.md` |
| Any git operation (commit/branch/push/pull) | `$CLAUDE_ROOT/global/git.md` |
| Edit any code (components, services, styles) | `$CLAUDE_ROOT/global/coding.md` + `$CLAUDE_ROOT/projects/{P}/context.md` |
| Validate code | Run `bash $CLAUDE_ROOT/scripts/validate.sh` → read `scripts/report.md` → read all 4 `validation/checklists/*.md` → read `projects/{P}/context.md` → present findings |
| Respond to PR review comment on own PR | `$CLAUDE_ROOT/global/pr-review.md` + `$CLAUDE_ROOT/global/voice.md` |
| Leave a comment on own PR (not a review response) | `$CLAUDE_ROOT/global/voice.md` |
| Comment on someone else's PR | `$CLAUDE_ROOT/global/voice.md` |
| Write code comments | `$CLAUDE_ROOT/global/voice.md` |
| Implement feature | `$CLAUDE_ROOT/projects/{P}/context.md` + relevant `projects/{P}/backend/*.md` |
| Update backend docs | `$CLAUDE_ROOT/global/backend-update.md` |
| Dev panel (load/set up/add/remove) | `$CLAUDE_ROOT/projects/{P}/patterns/dev-auth-panel-instructions.md` |
| Implement skeleton screen / loading placeholder | `$CLAUDE_ROOT/global/skeleton-screens.md` |
| Story file lookup ("read story file" / "load story") | Extract numeric IDs from branch name → search `$CLAUDE_ROOT/stories/` for matching file |
| Debug build errors | Run `npm run build` from frontend dir, read output |

**Validate code — single trigger**: Run script + apply all checklists in one response. No two-step workaround needed.

---

## Git Execution Context

Valid git dirs only — project roots are NOT git repos.

| Repo | Execute git from |
|------|-----------------|
| `.claude/` changes | `$CLAUDE_ROOT` (e.g. `/Users/daniel/Developer/NTM-Publicatie-overzicht/.claude`) |
| Frontend changes | `{project-root}/{prefix}-frontend/` (e.g. `NTM-Publicatie-overzicht/ntm-frontend`) |

`.claude/` is a shared git repo — commits here apply to all 3 projects on next pull.

**Commit "this"** (no repo specified): check both repos for changes, commit each separately.

---

## Frontend File Types

Only `.ts`, `.html`, `.scss` — never `.js/.jsx/.tsx/.css/.less/.vue`.
Glob pattern: `**/*.{ts,html,scss}`
