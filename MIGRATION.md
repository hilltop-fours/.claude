# .claude Repo — v2 Migration Plan

Machine-optimized. Not for human reading. Every line written for Claude to parse and execute.

---

## Core Principle

Every file in this repo is Claude-facing only. No human reads, edits, or maintains any of it.
This changes what "good" means:
- No prose padding, no rationale, no "why this matters"
- No examples unless they carry information the summary doesn't
- No paragraph where a table or list works
- Structure for fast lookup, not linear reading
- Assume full Angular/TypeScript/git knowledge — never explain basics

**Zero-context-per-session rule**: CLAUDE.md must work as a cold-start router every time. After compaction, re-reading CLAUDE.md alone should be enough to resume any workflow.

**Backend docs are 100% authoritative ground truth.** Never hedge about them. Never say "this may be outdated" or "verify against the actual API." They are the API contract.

---

## Phase Structure

Each phase has 3 steps. Do not skip steps. Do not start step 2 before step 1 is complete.

**Step 1 — READ**: Read every file listed. Confirm understanding in a brief summary before proceeding.
**Step 2 — EXECUTE**: Make the changes. Write new files, delete old ones, edit as needed.
**Step 3 — VALIDATE**: Verify the output meets the goal. Check for: completeness, no prose bloat, correct cross-references, nothing lost from source files.

---

## Phase 1 — Rewrite CLAUDE.md as a pure router

### Step 1 — READ
- [ ] Read `CLAUDE.md` (current version — already in context if session just started)
- [ ] Understand: what sections are essential vs bloat

**Goal**: Know exactly what to keep and what to cut.

### Step 2 — EXECUTE

Write new `CLAUDE.md`. Target: ~80 lines max. Structure:

```
## Ownership & File Policy
## Hook Rules (5 rules, table format)
## Project Identification (path → $CLAUDE_ROOT mapping)
## Workflow Router (trigger → files table)
## Git Execution Context
## Frontend File Types
```

**Rules for new CLAUDE.md:**
- Remove the entire "AUTOMATED BACKEND UPDATE WORKFLOW" section — it lives in `global/backend-update.md`
- Remove "PURPOSE - READ FIRST" section — condense to 2 lines under Ownership
- Remove "EDITING THIS FILE" section — obvious, not needed
- Remove "FOLDER STRUCTURE REFERENCE" section — will live in a separate `STRUCTURE.md`
- Remove "EXECUTION FLOW" section — redundant with Workflow Router table
- Remove "CRITICAL REMINDERS" section — fold critical items into relevant sections
- Convert "READ RULES ON-DEMAND" prose → compact trigger table
- Keep hook rules but convert to table format
- Keep project identification (path matching)
- Keep git execution context
- Keep frontend file type restrictions (short)

**Workflow Router table format:**
| Trigger | Load these files |
|---------|-----------------|
| new story / task / bug | `global/stories.md` |
| any git operation | `global/git.md` |
| edit code | `global/coding.md` + `projects/{P}/context.md` |
| validate code | run script → read report → read 4 checklists → `projects/{P}/context.md` |
| PR comment on own PR | `global/pr-review.md` + `global/voice.md` |
| comment on someone else's PR | `global/voice.md` |
| write code comments | `global/voice.md` |
| implement feature | `projects/{P}/context.md` + relevant `projects/{P}/backend/*.md` |
| update backend docs | `global/backend-update.md` |
| dev panel | `projects/{P}/patterns/dev-auth-panel-instructions.md` |
| story file lookup | search `stories/` by branch IDs |
| debug build errors | run `npm run build` from frontend dir, read output |

### Step 3 — VALIDATE
- [ ] New CLAUDE.md is ≤80 lines
- [ ] Every workflow from the old file has a row in the router table
- [ ] No prose padding remains
- [ ] Backend update workflow is NOT in CLAUDE.md (just a row pointing to the file)
- [ ] Cold-start test: reading only the new CLAUDE.md, would a fresh Claude know where to go for any task?

---

## Phase 2 — Write global/coding.md (merge 4 files)

### Step 1 — READ
- [ ] Read `global/angular-instructions.md`
- [ ] Read `global/code-simplicity.md`
- [ ] Read `validation/angular-style.md`
- [ ] Read `validation/angular-class-structure.md`
- [ ] Summarize: what unique rules does each file contribute? What overlaps?

**Goal**: Understand the full rule set before writing the merged file.

### Step 2 — EXECUTE

Write `global/coding.md`. Structure:

```
## Signals & Reactivity
## Template Syntax
## Class Structure (member ordering)
## Style Rules (ternary, nullish coalescing, readonly, private #)
## Simplicity Rules (anti-patterns, over-engineering warnings)
## Dead Code
## RxJS
## Feedback Log (from code-simplicity.md — preserve verbatim)
```

**Rules:**
- Every rule is a single line or short bullet — no paragraph explanations
- No examples unless the example is the only way to express the rule
- Merge overlapping rules (angular-instructions + angular-style have overlapping signal rules)
- Preserve the Feedback Log section from code-simplicity.md verbatim — it's real codebase history
- Delete `global/angular-instructions.md`, `global/code-simplicity.md`, `validation/angular-style.md`, `validation/angular-class-structure.md` after writing

### Step 3 — VALIDATE
- [ ] All rules from all 4 source files are present in merged file
- [ ] No rule appears twice (de-duped)
- [ ] Feedback Log section preserved exactly
- [ ] Source files deleted
- [ ] Checklist files in `validation/checklists/` still reference correct file names (update if needed)

---

## Phase 3 — Density pass: global/git.md

### Step 1 — READ
- [ ] Read `global/git-instructions.md`
- [ ] Identify: what's prose padding vs essential rule?

### Step 2 — EXECUTE

Write `global/git.md` (replaces `global/git-instructions.md`). Rules:
- Keep all commit format rules, branch naming, push workflow
- Table format for commit message formats per repo type
- Remove any "why" explanations — just the rules
- Keep the SPECIAL CASE section for `.claude` commits (it's non-obvious)
- Delete `global/git-instructions.md` after writing

### Step 3 — VALIDATE
- [ ] All commit formats present (frontend WIP, frontend PR title, .claude format)
- [ ] Branch naming convention present
- [ ] SPECIAL CASE for .claude commits present
- [ ] No prose explanations remain
- [ ] Source file deleted

---

## Phase 4 — Density pass: global/stories.md

### Step 1 — READ
- [ ] Read `global/new-story-instructions.md`
- [ ] Identify: what's the two-section rule (Azure DevOps text preserved verbatim / Claude-added content is dense)?

### Step 2 — EXECUTE

Write `global/stories.md` (replaces `global/new-story-instructions.md`). Rules:
- Keep the step-by-step story file creation workflow
- Add explicit two-section rule: original Azure DevOps text preserved verbatim, everything Claude adds is Claude-facing dense format
- Keep the checklist format for story files
- Remove prose explanations
- Delete `global/new-story-instructions.md` after writing

### Step 3 — VALIDATE
- [ ] Two-section rule is explicit
- [ ] Story file creation workflow complete
- [ ] Source file deleted

---

## Phase 5 — Density pass: global/pr-review.md + global/voice.md

### Step 1 — READ
- [ ] Read `global/pr-review-workflow.md`
- [ ] Read `global/daniel-voice.md`

### Step 2 — EXECUTE

Write `global/pr-review.md` (replaces `global/pr-review-workflow.md`):
- Keep response workflow and tone rules
- Remove prose padding
- Delete `global/pr-review-workflow.md` after writing

Write `global/voice.md` (replaces `global/daniel-voice.md`):
- Keep all tone/style rules for PR comments and code comments
- Remove prose padding
- Delete `global/daniel-voice.md` after writing

### Step 3 — VALIDATE
- [ ] Both files present, source files deleted
- [ ] No prose padding in either

---

## Phase 6 — Density pass: global/backend-update.md

### Step 1 — READ
- [ ] Read `global/update-backend-api-instructions.md`
- [ ] Note: this file also contains the full autonomous backend update workflow that was duplicated in CLAUDE.md

### Step 2 — EXECUTE

Write `global/backend-update.md` (replaces `global/update-backend-api-instructions.md`):
- Keep the full autonomous workflow (this is the canonical location — CLAUDE.md just points here)
- Add at top: **"Backend markdown docs are 100% authoritative ground truth. Never hedge about accuracy."**
- Remove prose padding
- Keep `global/backend-api-format.md` as-is (reference format, used rarely, fine as-is)
- Delete `global/update-backend-api-instructions.md` after writing

### Step 3 — VALIDATE
- [ ] Full workflow present (all steps from original)
- [ ] Authoritative ground truth statement at top
- [ ] Source file deleted
- [ ] `backend-api-format.md` untouched

---

## Phase 7 — Delete dead file + update checklist references

### Step 1 — READ
- [ ] Read `global/angular-testing.md` — confirm it is not referenced anywhere in CLAUDE.md or any workflow
- [ ] Read all 4 checklist files: `validation/checklists/typescript-component.md`, `typescript-interface.md`, `html-template.md`, `scss-style.md`
- [ ] Note which files each checklist references (the "from:" list at top)

### Step 2 — EXECUTE

- Delete `global/angular-testing.md` (dead file, never triggered by any workflow)
- Update checklist file references:
  - `typescript-component.md`: remove `angular-instructions.md`, `code-simplicity.md`, `angular-style.md`, `angular-class-structure.md` → replace with `coding.md`
  - `html-template.md`: update `angular-instructions.md` → `coding.md`, `angular-style.md` → `coding.md`
  - `scss-style.md`: update `code-simplicity.md` → `coding.md`
  - `typescript-interface.md`: update if it references any renamed files

### Step 3 — VALIDATE
- [ ] `angular-testing.md` deleted
- [ ] All 4 checklist files have correct source references
- [ ] No checklist references a file that no longer exists

---

## Phase 8 — Rename project-instructions.md → context.md

### Step 1 — READ
- [ ] Read `projects/NTM-Publicatie-overzicht/project-instructions.md`
- [ ] Read `projects/GRG-Wegkenmerken-verkeersborden/project-instructions.md`
- [ ] Read `projects/BER-Bereikbaarheidskaart/project-instructions.md`
- [ ] Note: these files are referenced in CLAUDE.md router (already updated in Phase 1 to use `context.md`)

### Step 2 — EXECUTE

For each project:
- Write content to `projects/{P}/context.md` (same content, density pass if verbose)
- Delete `projects/{P}/project-instructions.md`

Density pass rules:
- Remove human-facing onboarding prose
- Keep: backend service registry, project-specific patterns, file structure notes
- Keep all backend service paths (critical for backend update workflow)

### Step 3 — VALIDATE
- [ ] All 3 `context.md` files exist
- [ ] All 3 `project-instructions.md` files deleted
- [ ] Backend service registry complete in each
- [ ] CLAUDE.md router references `context.md` (set in Phase 1)

---

## Phase 9 — Write STRUCTURE.md

### Step 1 — READ
- [ ] Review the final file structure after all phases complete
- [ ] No files to read — this is a new file

### Step 2 — EXECUTE

Write `STRUCTURE.md` — a compact map of the repo for cold-start orientation:

```
# .claude Repo Structure

## Root
- CLAUDE.md — router (always loaded)
- MIGRATION.md — this migration plan
- STRUCTURE.md — this file

## global/
- coding.md — Angular/TS rules, class structure, simplicity, dead code
- git.md — commit formats, branch naming, push workflow
- stories.md — story file creation, two-section rule
- pr-review.md — PR comment response workflow
- voice.md — tone/style for PR comments and code comments
- backend-update.md — autonomous backend doc update workflow
- backend-api-format.md — reference format for backend docs

## projects/{PROJECT}/
- context.md — project overview, backend registry, patterns
- backend/*.md — API docs per backend (100% authoritative ground truth)
- patterns/*.md — project-specific code patterns

## validation/
- sonarqube-rules.md — active Sonar rules with fixes
- dead-code-detection.md — unused code detection rules
- checklists/ — per-filetype validation checklists (4 files)

## stories/
- {sprint}/*.md — one file per story, transient

## scripts/
- validate.sh — orchestrator
- checks/ — individual check scripts
- report.md — generated output (gitignored)
```

### Step 3 — VALIDATE
- [ ] Every file/folder in the repo is represented
- [ ] No deleted files appear in STRUCTURE.md

---

## Phase 10 — Final commit

### Step 1 — READ
- [ ] Run `git status` in `.claude/` to see all changed/deleted/new files

### Step 2 — EXECUTE

Commit all changes with message:
```
chore(repo): v2 migration — machine-optimized claude-facing structure
```

Use heredoc syntax. Single commit for the entire migration.

### Step 3 — VALIDATE
- [ ] `git status` is clean
- [ ] All 10 phases complete

---

## Files Being Deleted

| File | Replaced by |
|------|------------|
| `global/angular-instructions.md` | `global/coding.md` |
| `global/code-simplicity.md` | `global/coding.md` |
| `global/angular-testing.md` | (dead file, deleted) |
| `global/git-instructions.md` | `global/git.md` |
| `global/new-story-instructions.md` | `global/stories.md` |
| `global/pr-review-workflow.md` | `global/pr-review.md` |
| `global/daniel-voice.md` | `global/voice.md` |
| `global/update-backend-api-instructions.md` | `global/backend-update.md` |
| `validation/angular-style.md` | `global/coding.md` |
| `validation/angular-class-structure.md` | `global/coding.md` |
| `projects/*/project-instructions.md` | `projects/*/context.md` |

## Files NOT Changing

- `global/backend-api-format.md` — fine as-is
- `validation/sonarqube-rules.md` — already rewritten to dense format ✓
- `validation/dead-code-detection.md` — review density but content is solid
- `validation/checklists/*.md` — format is good, only update file references
- `projects/*/backend/*.md` — API docs, long by nature, format already dense
- `projects/*/patterns/` — project-specific patterns, leave alone
- `scripts/` — automation, not Claude-facing docs
- `stories/` — transient, format is fine
