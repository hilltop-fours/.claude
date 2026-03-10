# STRUCTURE.md — .claude Repo Map

Machine-optimized. Claude-facing only.
Use for orientation. CLAUDE.md is the router — this file is the reference map.

---

## Root

- `CLAUDE.md` — router (always loaded, zero-context cold-start entry point)
- `MIGRATION.md` — v2 migration plan (reference for understanding redesign decisions)
- `STRUCTURE.md` — this file

---

## global/

Shared rules across all 3 projects.

| File | Purpose |
|------|---------|
| `coding.md` | Angular/TS rules: signals, class structure, simplicity, dead code, RxJS, feedback log |
| `git.md` | Commit formats, branch naming, WIP suggestions, push rules |
| `stories.md` | Story file creation workflow, two-section rule, phased planning |
| `pr-review.md` | PR comment response workflow and output format |
| `voice.md` | Daniel's tone/style for PR comments and code comments. Training log. |
| `backend-update.md` | Autonomous backend doc update workflow (authoritative: backend docs = ground truth) |
| `backend-api-format.md` | Reference format for backend API documentation (read when updating docs) |

---

## projects/{PROJECT}/

One folder per project. All 3 share the same `.claude` git repo.

| File | Purpose |
|------|---------|
| `context.md` | Project overview, language rules, backend registry, pattern references |
| `backend/*.md` | API docs per backend service (100% authoritative ground truth) |
| `patterns/*.md` | Project-specific code patterns (service, repository, styling, etc.) |

**Projects**: `NTM-Publicatie-overzicht`, `GRG-Wegkenmerken-verkeersborden`, `BER-Bereikbaarheidskaart`

---

## validation/

Code quality rules used during validation tasks.

| File | Purpose |
|------|---------|
| `sonarqube-rules.md` | Active SonarQube rules with fixes (dense format) |
| `dead-code-detection.md` | Unused code detection: 5 rules with detection commands |
| `checklists/typescript-component.md` | 48 checks for `.component.ts`, `.service.ts`, `.repository.ts`, etc. |
| `checklists/typescript-interface.md` | 12 checks for `.interface.ts`, `.model.ts`, `.type.ts`, `.enum.ts` |
| `checklists/html-template.md` | 10 checks for `.html` templates |
| `checklists/scss-style.md` | 4 checks for `.scss` files |

---

## stories/

One file per story/task. Transient — used during development, archived after PR merge.

Format: `{sprint}/{storyId-taskId-description}.md`
Two-section rule: original Azure DevOps text (verbatim) + Claude-added analysis (dense)

---

## scripts/

Validation automation. Not Claude-facing docs — shell scripts and a TS checker.

- `validate.sh` — orchestrator (run this for code validation)
- `checks/` — individual check scripts (build, lint, prettier, ts-checks, html-checks, class-structure)
- `report.md` — generated output after running validate.sh (gitignored)
