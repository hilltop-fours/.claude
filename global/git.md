# git.md — Git Rules

Machine-optimized. Claude-facing only.

---

## Commit Formats

| Context | Format |
|---------|--------|
| Frontend dev (WIP) | `WIP: descriptive message of what was done` |
| Frontend PR title | `type(scope): #[story-id] #[task-id] description` |
| `.claude` repo | `type(scope): description` — single line, no story IDs |

All messages: English, description lowercase.

---

## Commit Types & Scope

**Frontend types**: `feat`, `bug`, `chore`, `docs`, `test`
**`.claude` types only**: `docs`, `feat`, `chore`

**Scope** = main component/feature affected. Examples: `auth`, `api`, `map-controls`, `user-profile`

---

## Frontend WIP Examples

```
WIP: add zoom controls template
WIP: implement service logic for zoom
WIP: fix template binding errors
```

## Frontend PR Title Examples

```
feat(map): #12345 #67890 add map zoom controls
bug(api): #12345 #67890 fix user data not loading
chore(deps): #12345 #67890 update angular to v17
```

---

## SPECIAL CASE — `.claude` Repo Commits

Single line only. No body. No story/task IDs. No Co-Authored-By. No exceptions, even for large changes.

**Scope naming:**
- Single file: `folder/filename` → `global/git`, `validation/angular-style`, `projects/NTM/backend/ntm-tracker-backend`
- Multiple files in one folder: parent folder → `global`, `projects/NTM-Publicatie-overzicht`
- Root files: filename only → `claude`, `readme`

**Examples:**
```
docs(global/git): rewrite for squash merge workflow
docs(projects/NTM/backend/ntm-tracker-backend): update external-organizations endpoints
chore(projects): reorganize backend documentation structure
docs(claude): add execution flow section
```

**Multiple changes across folders → separate commits per scope:**
```
# Changes in: claude.md + global/git.md + projects/NTM/backend/ntm-tracker-backend.md
1. docs(claude): [changes to claude.md]
2. docs(global/git): [changes to git.md]
3. docs(projects/NTM/backend/ntm-tracker-backend): [changes to backend docs]
```
Commit order: root files first, then alphabetical by scope.

---

## Branch Naming

Format: `type/[story-id]/[task-id]/[description]`
Types: `bug`, `feature`
Description: kebab-case
Always branch from `main`.

Example: `bug/106187/108922/fix-verkeersbesluit-id-uppercase-validation`

**Never commit work onto a branch that belongs to a different story/task.** Checkout `main` and create a new branch first.

---

## WIP Commit Suggestions — Frontend Only

Proactively suggest WIP commits at logical moments. Always ask first — never auto-commit.

**When to suggest:**
- After completing a logical chunk (template done, moving to service)
- Before a risky/experimental change (safety checkpoint)
- After significant file changes with no commit
- After a refactoring step, before the next

**How to suggest:** Always as a question: *"Should I make a WIP commit for the template changes before we move on to the service?"*

---

## Git Operation Rules

```
NEVER stage, commit, or push unless user explicitly requests it or approves a WIP suggestion.
Each request is ONE-TIME ONLY:
  "stage these files" → git add, then STOP
  "commit this"       → git commit, then STOP
  "push"              → git push, then STOP
```

Exception: WIP commit approval → `git add` + `git commit` in sequence is OK.

Squash workflow: always `git reset --soft` + new `git commit` — never `git rebase`.
