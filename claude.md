# CLAUDE CODE - INSTRUCTIONS

## ⚠️ PURPOSE - READ FIRST

**Everything in this `.clinerules/` repository is written EXCLUSIVELY for Claude Code.**

This is not human documentation. Every file, every structure, every detail exists for one purpose only:
- **For Claude to read and understand**
- **For Claude to make better decisions**
- **For Claude to write better code**
- **For Claude to locate information quickly**

When creating or editing files in `.clinerules/`:
- Optimize for Claude's comprehension, not human readability
- Structure for Claude's navigation patterns
- Write explanations for Claude's task-based reading
- Format files so Claude can find and apply the rules efficiently

The user should never need to read this. If the user needs information, Claude reads it and explains. If the user needs to change something, they ask Claude to edit it.

---

## CLAUDE.MD FILE SYNCHRONIZATION - CRITICAL

**When user asks to edit/update this claude.md file:**

1. **ALWAYS edit `.clinerules/claude.md` FIRST** (the source of truth, version controlled in git)
2. **Commit the change** to .clinerules repository with git
3. **THEN sync to root claude.md** (copy the exact same content to `$PROJECT_ROOT/claude.md`)
   - Root file is NOT version controlled (reference copy only)
   - Root file must match .clinerules file exactly

**NEVER edit only the root `claude.md`** - changes will not be in git history and will be lost.

**Workflow**:
```
Edit .clinerules/claude.md
  ↓
Commit to .clinerules with git
  ↓
Copy exact content to root claude.md (no commit needed)
```

---

## FOLDER STRUCTURE REFERENCE

Quick overview of `.clinerules/` organization:

- `global/` - Shared rules for all projects
  - `git-instructions.md` - Git workflow, commit messages, branch naming, pushing
  - `angular-instructions.md` - Angular coding standards and patterns
  - `code-simplicity.md` - Code simplicity, anti-patterns, and human-appropriate output
  - `update-backend-api-instructions.md` - How to update backend documentation
  - `backend-api-format.md` - Format reference for backend API documentation
  - `pr-review-workflow.md` - PR review comment handling workflow and response style
  - `story-workflow.md` - Standard workflow when starting a new story/task/bug

- `validation/` - Detailed validation and style enforcement rules
  - `angular-*.md` - Specific Angular style and validation rules

- `projects/` - Project-specific configurations
  - `{PROJECT-NAME}/`
    - `project-instructions.md` - Frontend coding rules, backend API mapping, patterns
    - `patterns/` - Project-specific code patterns and conventions (optional)
    - `backend/` - Backend API documentation for this project
      - `{backend-name}.md` - API endpoints, models, request/response formats

- `claude.md` - This file (Claude Code instructions and task rules)

---

## PROJECT IDENTIFICATION

Check your current working directory path and match it against these patterns:

**IF path contains `/NTM-Publicatie-overzicht`**:
- Project: NTM Publicatie Overzicht
- $CLINERULES_ROOT = `/Users/daniel/Developer/NTM-Publicatie-overzicht/.clinerules`
- Read: `$CLINERULES_ROOT/projects/NTM-Publicatie-overzicht/project-instructions.md`

**IF path contains `/GRG-Wegkenmerken-verkeersborden`**:
- Project: GRG Wegkenmerken Verkeersborden
- $CLINERULES_ROOT = `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/.clinerules`
- Read: `$CLINERULES_ROOT/projects/GRG-Wegkenmerken-verkeersborden/project-instructions.md`

**IF path contains `/BER-Bereikbaarheidskaart`**:
- Project: BER Bereikbaarheidskaart
- $CLINERULES_ROOT = `/Users/daniel/Developer/BER-Bereikbaarheidskaart/.clinerules`
- Read: `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/project-instructions.md`

---

## PATH VARIABLES

For file references in `.clinerules/` documentation, use the `$CLINERULES_ROOT` variable:

**$CLINERULES_ROOT** = Absolute path to `.clinerules/` directory for the current project
- NTM: `/Users/daniel/Developer/NTM-Publicatie-overzicht/.clinerules`
- GRG: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/.clinerules`
- BER: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/.clinerules`

All file references use this pattern: `$CLINERULES_ROOT/path/to/file.md`

---

## READ RULES ON-DEMAND

**BEFORE any git operation** (commit, branch, push, pull, status, checkout):
→ **ALWAYS** read `$CLINERULES_ROOT/global/git-instructions.md` first — no exceptions, even if read earlier in the session
→ **CRITICAL FOR .CLINERULES COMMITS**: Single line only, `type(scope): description` format, separate commits per scope (see git-instructions.md SPECIAL CASE section)

**WHEN user says "commit this" / "commit" / "stage and commit"** (without specifying a repo):
→ Read `$CLINERULES_ROOT/global/git-instructions.md` first
→ Check BOTH repositories for uncommitted changes:
  1. Run `git status --short` in `.clinerules/` directory
  2. Run `git status --short` in `{project-prefix}-frontend/` directory
→ Commit changes in whichever repo(s) have them
→ If both repos have changes, commit each repo separately following git-instructions rules
→ If user specifies a repo (e.g., "commit the frontend changes"), only commit that repo

**WHEN user starts a new story or task** (new story, start story, new task, start task, new bug, start bug, here's the story, here's the task):
→ Read `$CLINERULES_ROOT/global/story-workflow.md`
→ Follow the workflow steps defined in that file
→ Also read project-specific `project-instructions.md` for context

**BEFORE editing ANY code** (components, services, templates, styles):
→ Read `$CLINERULES_ROOT/global/angular-instructions.md`
→ Read `$CLINERULES_ROOT/global/code-simplicity.md`
→ Reference `$CLINERULES_ROOT/validation/angular-*.md` files for detailed style and validation rules
→ During development: if code is getting complex, add `// COMPLEXITY: reason` in code and flag in response (see code-simplicity.md)

**WHEN user reports a PR review comment** (PR comment, review comment, got feedback on PR, reviewer said):
→ Read `$CLINERULES_ROOT/global/pr-review-workflow.md`

**WHEN user asks to update backend API docs**:
→ Read `$CLINERULES_ROOT/global/update-backend-api-instructions.md`

**WHEN implementing features or need project context**:
→ Read project-specific `project-instructions.md` (found via project identification above)

**WHEN implementing features that use backend APIs**:
→ Project's `project-instructions.md` has backend mapping with `$CLINERULES_ROOT` paths

**IF confused about backend API documentation format**:
→ Read `$CLINERULES_ROOT/global/backend-api-format.md` (reference only)

**WHEN user asks to validate code** (validate, review, check code quality):

Execute validation in MANDATORY PHASES. You MUST complete ALL steps in each phase before proceeding to next phase.

**PHASE 1: Setup and File Reading (MANDATORY - NO SKIPPING)**

1. Read ALL validation rule files (read each file, do not assume you remember):
   - Read `$CLINERULES_ROOT/global/angular-instructions.md`
   - Read `$CLINERULES_ROOT/global/code-simplicity.md`
   - Read `$CLINERULES_ROOT/validation/angular-style.md`
   - Read `$CLINERULES_ROOT/validation/angular-class-structure.md`
   - Read `$CLINERULES_ROOT/validation/sonarqube-rules.md`
   - Read `$CLINERULES_ROOT/projects/{PROJECT}/project-instructions.md`

2. Get baseline and changed files:
   - Run: `git merge-base HEAD origin/main` (get baseline commit hash)
   - Run: `git diff {baseline}...HEAD --name-only --diff-filter=ACMR` (get all changed files)

3. OUTPUT phase 1 results:
   - Baseline commit: {hash}
   - Files to validate: {list all changed files}

**PHASE 2: Automated Checks (MANDATORY - RUN ALL, WAIT FOR EACH)**

From frontend directory, run these commands sequentially:

1. Run `npm run build` → WAIT for completion → Output: ✓ PASS / ✗ FAIL with full error details
2. Run `npm run lint` → WAIT for completion → Output: ✓ PASS / ✗ FAIL with full error details
3. Get changed formatting files: `git diff {baseline}...HEAD --name-only --diff-filter=ACMR '*.ts' '*.html' '*.scss'`
4. Run `npx prettier --check {each file from step 3}` → Output: ✓ PASS / ✗ N files need formatting (list files)
5. Get changed .ts files: `git diff {baseline}...HEAD --name-only --diff-filter=ACMR '*.ts'`
6. Run `grep -n '^\s*/\*\*' {each .ts file from step 5}` → Output: ✓ PASS / ✗ N JSDoc violations (list line numbers)
7. Run dead code checks:
   - TypeScript: `npx tsc --noEmit --noUnusedLocals --noUnusedParameters`
   - ESLint: `npx eslint {each .ts file from step 5} --rule "no-unused-private-class-members: error"`
   → Output: ✓ PASS / ✗ N unused code violations (list details)

OUTPUT Section 1: Automated Checks Summary (use format below)

**PHASE 3: Per-File Manual Review (MANDATORY - ONE FILE AT A TIME, ALL CHECKS ENUMERATED)**

For EACH changed .ts file (do NOT batch, process ONE file completely before next):

1. Read the complete file
2. Get file diff: `git diff {baseline}...HEAD -- {filename}`

3. Execute EVERY check below and output result (✓ PASS / ✗ FAIL with line numbers):

**Angular Instructions checks:**
- [ ] Line-by-line: Uses @if/@for/@let (not *ngIf/*ngFor) → ✓/✗ with lines
- [ ] Line-by-line: Uses input()/output() (not @Input/@Output) → ✓/✗ with lines
- [ ] Line-by-line: Uses viewChild() (not @ViewChild) → ✓/✗ with lines
- [ ] Line-by-line: Signal references use () → ✓/✗ with lines
- [ ] Line-by-line: No decorative JSDoc → ✓/✗ with lines
- [ ] Line-by-line: No `any` type → ✓/✗ with lines
- [ ] Line-by-line: No nested subscribes → ✓/✗ with lines
- [ ] Line-by-line: No toSignal() in components → ✓/✗ with lines
- [ ] Check: Naming conventions (kebab-case, PascalCase, camelCase) → ✓/✗

**Code Simplicity checks:**
- [ ] For each method: Tied to specific requirement → ✓/✗ with method names
- [ ] For each pattern: Matches existing codebase → ✓/✗ with details
- [ ] Check: No single-use abstractions → ✓/✗
- [ ] Check: No // COMPLEXITY: markers → ✓/✗
- [ ] Check: Mid-level developer readable → ✓/✗

**Style Preferences checks:**
- [ ] Line-by-line: Ternary for simple conditionals → ✓/✗ with lines
- [ ] Line-by-line: Nullish coalescing (??) for defaults → ✓/✗ with lines
- [ ] Line-by-line: readonly for immutable values → ✓/✗ with lines
- [ ] Check: [class]/[style] bindings (not ngClass/ngStyle) → ✓/✗ with lines
- [ ] Check: Event handlers describe action → ✓/✗
- [ ] Line-by-line: Private fields use # syntax → ✓/✗ with lines

**Class Structure checks:**
- [ ] Check order: Dependencies first → ✓/✗
- [ ] Check order: Public → protected → private → ✓/✗
- [ ] Check order: Signals before variables → ✓/✗
- [ ] Check order: Computed signals grouped → ✓/✗
- [ ] Check order: Constructor position → ✓/✗
- [ ] Check order: Lifecycle hooks position → ✓/✗
- [ ] Check order: Methods last → ✓/✗

**SonarQube Rules checks:**
- [ ] Line-by-line: No any type (S4202) → ✓/✗ with lines
- [ ] Line-by-line: No magic numbers (S109) → ✓/✗ with lines
- [ ] Check: No deep nesting >3 (S134) → ✓/✗
- [ ] Check: No duplicate strings (S1192) → ✓/✗
- [ ] Line-by-line: No console.log (S106) → ✓/✗ with lines
- [ ] Check: No unused imports (S1128) → ✓/✗

**Dead Code Detection checks:**
- [ ] No unused local variables → ✓/✗ with lines
- [ ] No unused function parameters → ✓/✗ with lines
- [ ] No dead stores/assignments → ✓/✗ with lines
- [ ] No unused private methods/properties → ✓/✗ with method names
- [ ] No unreachable code → ✓/✗ with lines

**Project Patterns checks:**
- [ ] Check: Follows project-specific patterns → ✓/✗
- [ ] Check: Matches backend API docs if applicable → ✓/✗
- [ ] Check: Uses design system correctly → ✓/✗

OUTPUT Section 2: Detailed checklist for this file (show ALL checks above with results)

REPEAT Phase 3 for next file (do NOT proceed until current file is 100% complete)

**ANTI-CORNER-CUTTING ENFORCEMENT**

Claude has a tendency to cut corners during validation. The following rules MUST be enforced:

1. **NO BATCHING FILES**
   - NEVER group multiple files together like "Files: Type definitions (4 files)"
   - Each file gets its own dedicated section with full checklist
   - Even similar files must be validated independently

2. **MANDATORY LINE NUMBER CITATIONS**
   - EVERY "✓ PASS" must cite specific line ranges: "✓ PASS - Lines 1-44: No @Input decorators found"
   - EVERY "✗ FAIL" must cite exact line number: "✗ FAIL - Line 99: console.error() usage"
   - NEVER write "✓ PASS" without evidence
   - If check doesn't apply, write "N/A - [reason]" not "✓ PASS"

3. **ALL CHECKBOXES MUST BE SHOWN**
   - Output ALL 35+ checks for .ts files
   - Output ALL applicable checks for .html/.scss/interface files
   - NEVER summarize with "the rest pass" or "all others ✓ PASS"
   - If a check doesn't apply, still show it marked as "N/A"

4. **NO ASSUMPTIONS - USE TOOLS**
   - For "No @Input" check → MUST use Grep tool to search for `@Input`
   - For "No console" check → MUST use Grep tool to search for `console.`
   - For "No any type" check → MUST use Grep tool to search for `: any`
   - Never trust memory - always verify with tools

5. **EVIDENCE-BASED VALIDATION**
   - EVERY check must have supporting evidence (grep result, line range, or reasoning)
   - No checkbox can be marked without proof
   - If you can't verify a check, mark it "⚠️ UNVERIFIED" and explain why

6. **FILE-BY-FILE WORKFLOW**
   - Before checking a file: use Read tool (even if already read)
   - Before checking a file: use `git diff` to see what changed
   - Process one file completely before mentioning the next
   - Output "=== FILE {N} OF {TOTAL} COMPLETE ===" after each file

7. **VERBOSITY OVER BREVITY**
   - User wants transparency, not efficiency
   - Better to be tediously thorough than concisely incomplete
   - Default to MORE detail, not less
   - Show all work, don't skip steps

8. **NO FALSE EFFICIENCY**
   - Don't rely on "build passes, so typing is fine" - still check for `any` types
   - Don't rely on "lint passes, so no console.log" - still grep for console statements
   - Automated checks catch some issues, manual review catches others

9. **INTERFACE/TYPE FILE HANDLING**
   - Interface files still get the full checklist
   - Most checks will be "N/A - No logic in interface file"
   - But still check: naming conventions, no `any` type, no magic numbers in defaults
   - Show all checks, mark non-applicable ones as N/A

10. **HTML/SCSS FILE HANDLING**
    - HTML files: Check control flow syntax, signal usage, event handlers, design system usage
    - SCSS files: Check for duplicate selectors, proper nesting, follows styling guidelines
    - Both get abbreviated checklists, but ALL applicable checks must be shown

**PHASE 4: Summary Report (MANDATORY)**

Compile findings from all phases into final report.

OUTPUT Section 3: Summary Report (use format below)

---

**VALIDATION OUTPUT FORMATS:**

→ Generate validation report with DETAILED CHECKLIST FORMAT:

**CRITICAL**: ALWAYS use this format. User needs to see EVERY check performed on EVERY file.

**Section 1: Automated Checks Summary**
```markdown
## 1. Automated Checks (All Files)

- [x] **Build**: `npm run build` - ✓ PASS / ✗ FAIL (with error details)
- [x] **Lint**: `npm run lint` - ✓ PASS / ✗ FAIL (with error details)
- [x] **Prettier**: Checked X files - ✓ PASS / ✗ N files need formatting
- [x] **JSDoc**: Grepped changed .ts files - ✓ PASS / ✗ N violations found
- [x] **Dead Code**: TypeScript + ESLint - ✓ PASS / ✗ N violations found
```

**Section 2: Per-File Detailed Checklist**

For EACH changed file, create a checklist showing EVERY rule checked:

```markdown
### File: [filename.ts](path/to/file.ts)

**Angular Instructions (angular-instructions.md)**
- [x] Control flow: Uses @if/@for/@let (not *ngIf/*ngFor) - ✓ PASS / ✗ FAIL: [details]
- [x] Signals: Uses input()/output() (not @Input()/@Output()) - ✓ PASS / ✗ FAIL: [details]
- [x] ViewChild: Uses viewChild() (not @ViewChild()) - ✓ PASS / ✗ FAIL: [details]
- [x] Signal access: All references use () for signal values - ✓ PASS / ✗ FAIL: [details]
- [x] Comments: No decorative JSDoc (only "why" comments if complex) - ✓ PASS / ✗ FAIL: [details]
- [x] TypeScript: No any type used - ✓ PASS / ✗ FAIL: [details]
- [x] RxJS: No nested subscribes - ✓ PASS / ✗ FAIL: [details]
- [x] Naming: kebab-case files, PascalCase classes, camelCase variables - ✓ PASS / ✗ FAIL: [details]

**Code Simplicity (code-simplicity.md)**
- [x] Every method tied to a requirement (no speculative code) - ✓ PASS / ✗ FAIL: [details]
- [x] Patterns match existing codebase patterns - ✓ PASS / ✗ FAIL: [details]
- [x] No abstractions used only once - ✓ PASS / ✗ FAIL: [details]
- [x] No // COMPLEXITY: markers remaining - ✓ PASS / ✗ FAIL: [details]
- [x] Mid-level developer could understand without questions - ✓ PASS / ✗ FAIL: [details]

**Style Preferences (angular-style.md)**
- [x] Ternary operator for simple conditionals - ✓ PASS / ✗ FAIL: [details]
- [x] Nullish coalescing (??) for defaults - ✓ PASS / ✗ FAIL: [details]
- [x] readonly for immutable values - ✓ PASS / ✗ FAIL: [details]
- [x] [class]/[style] bindings (not ngClass/ngStyle) - ✓ PASS / ✗ FAIL: [details]
- [x] Event handlers describe action (not handleClick) - ✓ PASS / ✗ FAIL: [details]
- [x] Private fields use # syntax (not private keyword) - ✓ PASS / ✗ FAIL: [details]

**Class Structure (angular-class-structure.md)**
- [x] Dependencies first, then public→protected→private - ✓ PASS / ✗ FAIL: [details]
- [x] Signals properly ordered (ViewChild, Input, Output, computed, variables) - ✓ PASS / ✗ FAIL: [details]
- [x] Constructor (if present) - ✓ PASS / ✗ FAIL: [details]
- [x] Lifecycle hooks - ✓ PASS / ✗ FAIL: [details]
- [x] Getters/setters - ✓ PASS / ✗ FAIL: [details]
- [x] Methods (public→protected→private) - ✓ PASS / ✗ FAIL: [details]

**SonarQube Rules (sonarqube-rules.md)**
- [x] No any type (typescript:S4202) - ✓ PASS / ✗ FAIL: [details]
- [x] No magic numbers (typescript:S109) - ✓ PASS / ✗ FAIL: [details]
- [x] No deep nesting (typescript:S134) - ✓ PASS / ✗ FAIL: [details]
- [x] No duplicate strings (typescript:S1192) - ✓ PASS / ✗ FAIL: [details]
- [x] No console statements (typescript:S106) - ✓ PASS / ✗ FAIL: [details]
- [x] No unused imports (typescript:S1128) - ✓ PASS / ✗ FAIL: [details]

**Dead Code Detection (dead-code-detection.md)**
- [x] No unused local variables - ✓ PASS / ✗ FAIL: [details]
- [x] No unused function parameters - ✓ PASS / ✗ FAIL: [details]
- [x] No dead stores/assignments - ✓ PASS / ✗ FAIL: [details]
- [x] No unused private members - ✓ PASS / ✗ FAIL: [details]
- [x] No unreachable code - ✓ PASS / ✗ FAIL: [details]

**Project Patterns (project-instructions.md)**
- [x] Follows project-specific patterns - ✓ PASS / ✗ FAIL: [details]
- [x] Matches backend API documentation if applicable - ✓ PASS / ✗ FAIL: [details]
- [x] Uses design system components correctly - ✓ PASS / ✗ FAIL: [details]
```

**Section 3: Summary Report**
```markdown
# Code Validation Report

**Date**: {YYYY-MM-DD}
**Branch**: {branch-name}
**Files Changed**: X files
**Baseline**: Commit {hash} (where branch diverged from main)

## Summary
- Build: ✓ PASS / ✗ FAIL
- Lint: ✓ PASS / ✗ FAIL
- Prettier: ✓ PASS / ✗ N files need formatting
- JSDoc: ✓ PASS / ✗ N violations
- Code Review: ✓ PASS / ✗ N violations found

## Files Changed
{output from git diff --stat}

## Critical Issues
{List critical violations that MUST be fixed}

## Warnings
{List warnings that should be addressed}

## Recommendations
{Actionable recommendations}

---

Would you like me to fix the issues? (yes/no)
```

**IMPORTANT NOTES**:
- Show EVERY check for EVERY file - user needs transparency
- Mark [x] for all checks performed, then ✓ PASS or ✗ FAIL with details
- If no violations for a rule, mark ✓ PASS (don't skip showing it)
- If issues found, present findings only (no automatic fixes unless explicitly requested)
- **Prettier auto-fix**: If formatting issues found, ask user if they want to fix them, then run `npx prettier --write [specific files]` on only those files that need formatting

**WHEN user asks to review complexity** (review complexity, check complexity, simplicity check, review the code):
→ Read `$CLINERULES_ROOT/global/code-simplicity.md`
→ Execute the Manual Review Process defined in code-simplicity.md
→ For each file changed:
  - Is every new method/function tied to a specific requirement?
  - Does every pattern used match patterns found elsewhere in the codebase?
  - Are there abstractions used only once? (Inline them)
  - Could a mid-level frontend developer understand this without asking questions?
  - Does the code introduce any patterns not seen elsewhere in the project?
  - Are there any remaining `// COMPLEXITY:` markers? (Must be resolved before PR)
→ Present findings organized by file with specific recommendations
→ Include summary: X issues found across Y files

---

## AUTOMATED BACKEND UPDATE WORKFLOW

**WHEN user asks to update backends** (update backend, update backends, check backend, scan backends, backend status, backend updates):
→ Execute automated backend update workflow for CURRENT project only
→ This is autonomous - Automatically updates all backend markdown files with detected API changes
→ Read `$CLINERULES_ROOT/global/update-backend-api-instructions.md` for documentation format reference

### Trigger Phrases

**Autonomous Update Mode** (scans all backends and updates automatically):
- "update backend" / "update backends" / "update all backends"
- "check backend" / "check backends" / "check all backends"
- "scan backend" / "scan backends"
- "backend status" / "backend updates"
- "which backends need updating"
- "refresh backend docs" / "sync backend docs"

**Manual Single Backend Mode** (updates one specific backend):
- "update [backend-name]" (e.g., "update traffic-sign-backend")
- "backend [backend-name] has updated"
- "[backend-name] needs updating"

### Execution Workflow - Autonomous Mode

**CRITICAL**: Only process backends for the CURRENT project (based on cwd), not all projects globally.

**Step 1: Identify Current Project**
```
IF cwd contains /GRG-Wegkenmerken-verkeersborden:
  → Project = GRG
  → $CLINERULES_ROOT = /Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/.clinerules

ELSE IF cwd contains /NTM-Publicatie-overzicht:
  → Project = NTM
  → $CLINERULES_ROOT = /Users/daniel/Developer/NTM-Publicatie-overzicht/.clinerules

ELSE IF cwd contains /BER-Bereikbaarheidskaart:
  → Project = BER
  → $CLINERULES_ROOT = /Users/daniel/Developer/BER-Bereikbaarheidskaart/.clinerules
```

**Step 2: Extract Backend Registry**

Read `$CLINERULES_ROOT/projects/{PROJECT}/project-instructions.md`

Parse the "Backend Services (Reference Only - Never Edit)" section:
- Extract backend name (e.g., "traffic-sign-backend")
- Extract absolute repo path (e.g., `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-backend/`)
- Calculate doc path: `$CLINERULES_ROOT/projects/{PROJECT}/backend/{backend-name}.md`

Build backend registry array for THIS project only.

**Step 3: For Each Backend in THIS Project**

a. **Read backend markdown file**
   - Path: `$CLINERULES_ROOT/projects/{PROJECT}/backend/{backend-name}.md`
   - Parse COMMIT TRACKING table
   - Extract: Last Verified Commit (short hash like `46ecff61`)
   - Extract: Last Verified Date
   - If COMMIT TRACKING missing/malformed → Use fallback: "never verified", scan recent 20 commits

b. **Pull latest changes from remote**
   ```bash
   cd {backend_repo_path}

   # Validate git repo
   if ! git rev-parse --git-dir >/dev/null 2>&1; then
     echo "ERROR: Not a git repository"
     continue to next backend
   fi

   # Pull latest changes from remote (to sync with origin)
   git pull

   # If pull fails, skip this backend
   if [ $? -ne 0 ]; then
     echo "ERROR: Git pull failed"
     continue to next backend
   fi
   ```

c. **Check for new commits**
   ```bash
   # Get commits since last verification
   git log --oneline {last_verified_commit}..HEAD

   # If commit not found, fallback to recent commits
   if [ $? -ne 0 ]; then
     echo "WARNING: Last verified commit not in history, scanning recent commits"
     git log --oneline -n 20
   fi
   ```

d. **Apply API-Relevance Heuristics**

   For each commit message, classify as HIGH / MEDIUM / LOW:

   **HIGH Confidence** (always process):
   - Contains: `feat`, `feature`, `endpoint`, `api`, `rest`, `controller`, `dto`, `model`, `swagger`, `openapi`
   - Contains: `breaking`, `deprecate`, `remove`, `delete` (flag for special attention)
   - Patterns: `add.*endpoint`, `new.*api`, `change.*dto`, `update.*model`

   **MEDIUM Confidence** (process with caution):
   - Contains API keywords + `update`, `modify`, `change`
   - Contains: `enum` (often affects API contracts)
   - Contains: `request`, `response`, `payload`

   **LOW Confidence** (skip - not API-relevant):
   - Contains: `fix`, `bug`, `typo`, `refactor`, `test`, `doc`, `comment`, `style`, `format`
   - Contains: `internal`, `cleanup`, `optimize`, `performance` (unless has API keywords)
   - Contains: `build`, `ci`, `pipeline`, `docker`, `config`, `dependency`
   - Commit message only changes implementation files, no Controller/DTO/Enum changes

e. **For HIGH/MEDIUM commits: Inspect Code Changes**

   ```bash
   git show {commit_hash}
   ```

   Look for changes in:
   - `*Controller.java` files → New/modified endpoints
   - `*Dto.java`, `*Request.java`, `*Response.java` files → New/modified DTOs
   - `*Enum.java` files → New/modified enum values
   - Swagger/OpenAPI annotations → Documentation hints

   Extract:
   - Endpoint: HTTP method, path, description (from `@GetMapping`, `@PostMapping`, etc.)
   - Parameters: Query params, path params, request body
   - Response: Response structure, status codes
   - DTOs: Field names, types, required/optional
   - Enums: Enum name, values

f. **Automatically Update Backend Markdown File**

   Follow format from `update-backend-api-instructions.md`:

   1. **Update Quick Reference Table** (if new features/endpoints added)
      - Add row for new feature category if needed
      - List main endpoints and HTTP methods

   2. **Update Detailed Endpoints Section**
      - Add new endpoint subsection with:
        - HTTP Method + Path (heading)
        - Authentication requirement
        - Description (basic, extracted from code/commit)
        - Query/path parameters table
        - Request body structure (if POST/PUT/PATCH)
        - Response structure with example JSON
        - Error responses (if documented in code)

   3. **Update DTOs Section**
      - Add new DTO documentation with:
        - DTO name (heading)
        - Purpose (from context)
        - Fields table (field name, type, required, description)
        - Example JSON

   4. **Update Enums Section**
      - Add new enum documentation with:
        - Enum name (heading)
        - Values table (value, description)

   5. **Update COMMIT TRACKING Table**
      ```markdown
      | Item | Value | Date |
      |------|-------|------|
      | Last Verified Commit | {new_commit_hash} | {YYYY-MM-DD} |
      | Commit Message | {commit_message_summary} | |
      | Swagger Version | latest | {YYYY-MM-DD} |

      **Status**: ✓ Up to date as of {YYYY-MM-DD}
      **Next Review**: Check commits after {new_commit_hash}
      ```

   6. **Save changes** to markdown file

g. **Handle Errors Gracefully**

   | Error | Action |
   |-------|--------|
   | Backend path not found | Skip, report: "Backend path invalid, check project-instructions.md" |
   | Not a git repo | Skip, report: "{backend-name} is not a git repository" |
   | Git pull fails | Skip, report: "Git pull failed for {backend-name}, try again later" |
   | Commit not found | Fallback to recent 20 commits, add warning to report |
   | Git command fails | Skip, report: "Could not access {backend-name}, check permissions" |
   | Cannot parse Java files | Log warning, add manual review note, continue |
   | No new commits | Report: "✓ Up to date, no changes since {date}" |

**Step 4: Commit All Changes**

After processing all backends:

```bash
cd $CLINERULES_ROOT

# Stage all modified backend markdown files
git add projects/{PROJECT}/backend/*.md

# Commit with descriptive message
git commit -m "docs(backend): automated update for {PROJECT} backends

Updated {count} of {total} backend API documentation files:
- {backend-name-1}: {change_summary}
- {backend-name-2}: {change_summary}
...

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Step 5: Generate Summary Report**

Present output to user:

```markdown
# Backend Update Report - {PROJECT}

**Date**: {YYYY-MM-DD}
**Backends processed**: {total_count}

---

## Summary

- ✓ Up to date: {count} backends (no changes)
- ✅ Updated: {count} backends (API changes detected and documented)
- ⚠️ Errors: {count} backends (see details below)

---

## Updated Backends

### {backend-name}
**Status**: ✅ Updated with {api_change_count} API changes
**Commits processed**: {commit_count} total, {api_count} API-relevant
**Last verified**: Now at commit `{new_hash}` (was `{old_hash}`)

**Changes made:**
- Added endpoint: `POST /traffic-signs/bulk-import`
- Modified DTO: `TrafficSignSearchCriteria` (added 'category' field)
- Breaking change: Removed deprecated endpoint `/traffic-signs/legacy`
- Updated COMMIT TRACKING table

**Commits:**
- `abc1234` - feat(endpoint): add bulk import endpoint [HIGH]
- `def5678` - breaking: remove legacy endpoint [HIGH]
- `ghi9012` - feat(dto): add search category field [HIGH]

---

{repeat for each updated backend}

---

## Backends Up To Date

{for each backend with no changes}
- ✓ {backend-name} (last verified {date}, still at commit `{hash}`)

---

## Errors / Warnings

{if any backends had errors}
- ⚠️ {backend-name}: {error_message}

---

## Changes Committed

Committed to `.clinerules` repository:
```
docs(backend): automated update for {PROJECT} backends

Updated {count} of {total} backends
```

**Next steps:**
- Review the updated markdown files if needed
- Sync to root CLAUDE.md if you edited .clinerules/claude.md
- All changes are in git, easily reversible if needed
```

### Documentation Quality Notes

**What the automation provides:**
- ✅ Structurally complete documentation (all endpoints, DTOs, enums documented)
- ✅ Accurate technical details (paths, methods, field types extracted from code)
- ✅ Consistent formatting following backend-api-format.md

**What may need manual refinement:**
- ⚠️ Basic descriptions (functional but not detailed with business context)
- ⚠️ Generic JSON examples (structurally correct but with placeholder values)
- ⚠️ Edge cases and special behaviors (not visible in code alone)

**Quality level:** 80-90% complete - Good for reference, may need refinement for complex endpoints

**You can always manually edit the markdown files afterward** to add:
- More detailed business context
- Realistic example values
- Edge case documentation
- Authorization nuances

### Error Handling Summary

All errors are non-fatal - If one backend fails, continue to next backend.

Common scenarios:
- **Backend repo not accessible** → Skip with warning, report to user
- **Commit hash not in history** → Fallback to recent 20 commits with note
- **Cannot parse Java files** → Document what's detectable, flag for manual review
- **No API changes detected** → Report backend is up to date, update COMMIT TRACKING anyway

All changes are committed to git, so mistakes are easily reversible.

---

## FILE TYPE RESTRICTIONS - FRONTEND ONLY

All **frontend projects** use ONLY these file types:
- TypeScript: `.ts` files
- HTML templates: `.html` files
- SCSS styles: `.scss` files

**Glob patterns**: Always use `**/*.{ts,html,scss}` when searching frontend code

**NEVER** search for or work with in frontend:
- `.js`, `.jsx`, `.tsx` (not used in frontend)
- `.css`, `.less` (frontend uses only SCSS)
- `.vue` (Angular projects only)

**Note**: Backend uses Java (`.java`, `.xml`, etc.) but you NEVER edit backend code, so backend file types are irrelevant.

---

## EDITING RESTRICTIONS - CRITICAL

**ONLY edit files in these locations**:
- Frontend source code: `/{frontend-repo}/src/**`
  - Example: `/ntm-frontend/src/**` (all subdirectories)
- Rules/docs: `/.clinerules/**` (any file in .clinerules folder)

**NEVER edit**:
- Backend code: `/*-backend/**` (any backend directory)
- Design system: `/ndw-design/**`, `/design/**`
- Node modules: `/**/node_modules/**`
- Build artifacts: `/**/dist/**`, `/**/build/**`, `/**/.angular/**`

**You CAN read (but not edit) outside `/src/`**:
- Configuration files: `package.json`, `angular.json`, `tsconfig.json`, etc.
- When user explicitly asks to check/read specific files
- When needed for understanding project setup

**Exception for editing**: Only edit config files if user explicitly says "edit", "update", or "change"

**Example**:
- User: "Check if package abc is installed" → ✅ Read `package.json`
- User: "Add package abc" → ✅ Edit `package.json`
- Without explicit instruction → ❌ Don't edit config files

---

## EXECUTION FLOW

1. **Identify project** using working directory path
2. **Define $CLINERULES_ROOT** based on project (see PROJECT IDENTIFICATION section)
3. **Read `project-instructions.md`** at `$CLINERULES_ROOT/projects/{PROJECT}/project-instructions.md`
4. **Based on task**, read additional files:
   - Git operation → Read `$CLINERULES_ROOT/global/git-instructions.md`
   - Code editing → Read `$CLINERULES_ROOT/global/angular-instructions.md` + `$CLINERULES_ROOT/global/code-simplicity.md` + `$CLINERULES_ROOT/validation/angular-*.md`
   - Backend API work → Read appropriate backend `.md` file (path in project-instructions.md)
   - Update backend docs → Read `$CLINERULES_ROOT/global/update-backend-api-instructions.md`
   - PR review comment → Read `$CLINERULES_ROOT/global/pr-review-workflow.md`
5. **Apply all rules** from the files you read to every action

---

## DEBUGGING & BUILD ERRORS

Frontend projects use build commands to identify issues:
- Run: `npm run build` or `npx ng build` (from the frontend directory)
- Build output shows all errors/warnings clearly
- No persistent log files—errors are caught via build command
- Debug by: running build, adding console.log statements, re-running build
- (Chrome DevTools connection via Claude Code is future work, not currently available)

---

## GIT EXECUTION CONTEXT

**Git commands execute from these subdirectories ONLY** (project roots are NOT git repos):

1. **For `.clinerules/**` changes** (rules, docs, API documentation):
   - Execute git from: `{project-root}/.clinerules/` directory
   - Example: `/Users/daniel/Developer/NTM-Publicatie-overzicht/.clinerules`
   - Example: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/.clinerules`

2. **For frontend code changes** (components, services, styles):
   - Execute git from: `{project-root}/{project-prefix}-frontend/` directory
   - Example: `/Users/daniel/Developer/NTM-Publicatie-overzicht/ntm-frontend`
   - Example: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-frontend`

**Critical**: Never attempt git commands from project root directories (e.g., `/NTM-Publicatie-overzicht/` or `/GRG-Wegkenmerken-verkeersborden/`) as they are NOT git repositories.

---

## CRITICAL REMINDERS

- Backend is **reference only** - Never edit backend source code
- Design system is **reference only** - Never edit design system code
- Project root directories are **NOT git repositories** - Git commands will fail there
- Git operations MUST execute from specified subdirectories (see Git Execution Context above)
- When in doubt, refer to the project's `project-instructions.md`
