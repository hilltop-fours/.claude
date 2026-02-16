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
  - `pr-response-style.md` - Detailed style guide for PR review responses
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

**BEFORE editing ANY code** (components, services, templates, styles):
→ Read `$CLINERULES_ROOT/global/angular-instructions.md`
→ Reference `$CLINERULES_ROOT/validation/angular-*.md` files for detailed style and validation rules

**WHEN user asks to update backend API docs**:
→ Read `$CLINERULES_ROOT/global/update-backend-api-instructions.md`

**WHEN implementing features or need project context**:
→ Read project-specific `project-instructions.md` (found via project identification above)

**WHEN implementing features that use backend APIs**:
→ Project's `project-instructions.md` has backend mapping with `$CLINERULES_ROOT` paths

**IF confused about backend API documentation format**:
→ Read `$CLINERULES_ROOT/global/backend-api-format.md` (reference only)

**WHEN user asks to validate code** (validate, review, check code quality):
→ Read consolidated validation checklists (file-type-specific):
  - For .component.ts/.service.ts files: `$CLINERULES_ROOT/validation/checklists/typescript-component.md` (50 checks)
  - For .html files: `$CLINERULES_ROOT/validation/checklists/html-template.md` (16 checks)
  - For .scss files: `$CLINERULES_ROOT/validation/checklists/scss-style.md` (5 checks)
  - For .interface.ts/.model.ts/.type.ts files: `$CLINERULES_ROOT/validation/checklists/typescript-interface.md` (12 checks)
  - `$CLINERULES_ROOT/projects/{PROJECT}/project-instructions.md` - Project-specific patterns
  - `$CLINERULES_ROOT/validation/dead-code-detection.md` - For reference on detection methods
→ Execute validation checks:
  - Run `npm run build` from frontend directory (check compilation errors)
  - Run `npm run lint` (check ESLint violations)
  - **Prettier check on changed files only**:
    1. Get changed files: `git diff main...HEAD --name-only --diff-filter=ACMR '*.ts' '*.html' '*.scss'`
    2. Run `prettier --check [changed files]` to identify which need formatting
    3. Do NOT use `npm run format` or `npm run format:check` (they affect all files in project)
→ Review all changes against appropriate file-type checklist:
  - Determine file type (.component.ts, .html, .scss, .interface.ts)
  - Load and execute ALL checks from the corresponding checklist
  - Add verification: "Total checks completed: X/X" for each file
  - Project patterns and requirements from `project-instructions.md`
→ Generate validation report with:
  - Build & lint status (pass/fail)
  - **Prettier status**: List files needing formatting (only from changed files)
  - Files changed with summary
  - Code quality findings organized by category
  - Violations with severity levels
  - Actionable recommendations for fixes
  - **Note**: If issues found, present findings only (no automatic fixes unless explicitly requested)
  - **Prettier auto-fix**: If formatting issues found, ask user if they want to fix them, then run `prettier --write [specific files]` on only those files that need formatting

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
   - Code editing → Read `$CLINERULES_ROOT/global/angular-instructions.md` + `$CLINERULES_ROOT/validation/angular-*.md`
   - PR review comment → Read `$CLINERULES_ROOT/global/pr-review-workflow.md` + `$CLINERULES_ROOT/global/pr-response-style.md`
   - Backend API work → Read appropriate backend `.md` file (path in project-instructions.md)
   - Update backend docs → Read `$CLINERULES_ROOT/global/update-backend-api-instructions.md`
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
