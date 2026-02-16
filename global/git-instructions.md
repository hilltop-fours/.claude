# GIT INSTRUCTIONS

## COMMIT CONTEXTS - FRONTEND REPOSITORIES

Two distinct contexts for frontend commit message formatting. For .clinerules commits, see SPECIAL CASE section below.

### During Frontend Development (Branch Commits)

Format: `WIP: descriptive message of what was done`

Rules:
- Always descriptive — useful as breadcrumbs during PR review
- No type/scope/story-task IDs needed
- Can be as many as needed, no squashing required
- Squash merge on PR handles the final commit on main
- This applies to frontend project repositories only

### For PR Titles (When Asked)

Format: `type(scope): #[story-id] #[task-id] description`

Rules:
- Single line only. NO body.
- This is what ends up on main via squash merge
- Claude generates this when user asks for a PR title
- Uses the same type/scope/language rules defined below

## LANGUAGE

ALL commit messages and PR titles: English
Description: lowercase only
Description: concise action (what was done)

## COMMIT TYPES

Use these types:
- `feat` - New feature
- `bug` - Bug fix
- `chore` - Maintenance (refactoring, dependencies, config)
- `docs` - Documentation
- `test` - Tests

Project config may override available types. Check project-specific config file.

## SCOPE

Scope = main component/feature affected
Examples: `auth`, `api`, `ui`, `map-controls`, `user-profile`
Check project-specific config for scope conventions.

## EXAMPLES

Frontend WIP commits (during development):
- `WIP: add zoom controls template`
- `WIP: implement service logic for zoom`
- `WIP: fix template binding errors`
- `WIP: add unit tests for zoom service`

Frontend PR titles (when asked):
- `feat(map): #12345 #67890 add map zoom controls`
- `bug(api): #12345 #67890 fix user data not loading`
- `chore(deps): #12345 #67890 update angular to v17`

## SPECIAL CASE - .CLINERULES REPO

When committing to the .clinerules repository itself:

Format: `type(scope): description`

Rules:
- Single line only (no body, no line breaks)
- NO story/task IDs (not tracked in Azure DevOps)
- Description: lowercase, can be longer than work commits
- English language

Scope naming:
- Single file edits: Use `folder/filename` pattern
  - Examples: `global/git-instructions`, `global/angular-instructions`, `validation/angular-style`, `global/backend-api-format`
  - For project files: `projects/PROJECT-NAME/filename`
  - For backend docs: `projects/PROJECT-NAME/backend/BACKEND-NAME`

- Multiple file edits: Use parent folder as scope
  - Examples: `global`, `projects/NTM-Publicatie-overzicht`, `projects/GRG-Wegkenmerken-verkeersborden`

- Root level files: Use filename only
  - Examples: `claude`, `readme`

Commit types (only these 3 for .clinerules repo):
- `docs` - Documentation updates (most common for .clinerules)
- `feat` - New instruction sets or major additions
- `chore` - Restructuring, file moves, cleanup

Examples:
- `docs(global/git-instructions): rewrite for squash merge workflow`
- `docs(projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend): update external-organizations endpoints`
- `docs(global): update git workflow and main instructions`
- `chore(projects): reorganize backend documentation structure`
- `docs(claude): add execution flow section for on-demand rule reading`

**Multiple commits strategy:**

When changes span multiple folders in `.clinerules`:
- Create SEPARATE commits for each folder/scope
- Commit order: Root files first, then alphabetical by scope
- Each commit focuses on one logical change area

Example with multiple changes:
```
Changes:
- claude.md (root)
- global/git-instructions.md
- projects/NTM/backend/ntm-tracker-backend.md

Commit order:
1. docs(claude): [changes to claude.md]
2. docs(global/git-instructions): [changes to git-instructions]
3. docs(projects/NTM/backend/ntm-tracker-backend): [changes to backend docs]
```

This keeps git history clean and changes logically separated.

## BRANCH NAMING

Format: `type/[story-id]/[task-id]/[description]`

Types:
- `bug` - Bug fixes
- `feature` - New features

Rules:
- Always create branches from `main`
- Description: kebab-case
- Story ID and Task ID: Obtained from project workflow (see WORKFLOW section)

**CRITICAL: Never commit work onto an existing feature branch that belongs to a different story/task.**
Each story/task gets its own branch. If you are currently on `feature/A/B/some-feature` and the user starts work on story C / task D, you MUST:
1. Checkout `main`
2. Create a new branch: `feature/C/D/description`
3. Do all work there

Committing onto the wrong branch requires force-pushing to undo, which disrupts remote history. Always verify the current branch's story/task IDs match the work being done before committing.

Example: `bug/106187/108922/fix-verkeersbesluit-id-uppercase-validation`

## WORKFLOW - AZURE DEVOPS INTEGRATION

User starts tasks by providing Azure DevOps screenshots containing:
- Story ID and Task ID
- Task description and acceptance criteria
- Comments (if any)

Screenshots provide context for:
- Branch naming (story-id, task-id, description)
- PR title type (bug, feat, chore)
- Implementation details

Development process:
- Work done incrementally
- WIP commits used throughout development (see WIP COMMIT SUGGESTIONS)

## WIP COMMIT SUGGESTIONS - FRONTEND ONLY

**Applies to frontend repositories only.** .clinerules uses proper `type(scope): description` commit format (see SPECIAL CASE section).

Claude proactively suggests WIP commits at logical moments during frontend development. Always ASK the user before committing — never auto-commit.

**When to suggest a WIP commit:**
- After completing a logical chunk of work (e.g., template done, moving to service logic)
- Before making a risky or experimental change (safety checkpoint to roll back to)
- When a significant number of files have changed without a commit
- After a refactoring step, before the next one
- When switching focus within the same task

**How to suggest:**
- Always phrase as a question: *"Should I make a WIP commit for the template changes before we move on to the service?"*
- Can suggest splitting changes: commit template changes separately from service changes for cleaner branch history
- User can say yes, no, or later — respect their preference

**WIP commit message quality:**
- Must be descriptive of what was done
- Keep it brief but meaningful
- Good: `WIP: implement map zoom controls in template`
- Good: `WIP: add search service with filter logic`
- Bad: `WIP` or `WIP: changes` or `WIP: stuff`

## PR TITLE FORMAT

When user asks for a PR title (to use as squash merge commit message on main):

Format: `type(scope): #[story-id] #[task-id] description`

Rules:
- Same type/scope/language rules as defined in COMMIT TYPES and SCOPE sections
- Description should summarize all work in the PR
- Single line, concise but complete

Examples:
- `feat(map): #12345 #67890 add map zoom controls with keyboard shortcuts`
- `bug(import): #12345 #67890 fix csv import failing on special characters`
- `chore(bootstrap-removal): #12345 #67890 replace bootstrap multi-select with design system component`

## PRE-PUSH VALIDATION - FRONTEND WORK ONLY

**These rules apply ONLY to frontend project repositories (not .clinerules repo)**

**BEFORE executing ANY `git push` command in a frontend repository:**

1. **Check branch name matches work being pushed:**
   - Extract story-id and task-id from the current branch name (format: `type/[story-id]/[task-id]/description`)
   - Verify the branch corresponds to the work being done
   - If the branch does not match the current task, WARN the user before pushing
   - This prevents accidentally pushing work for story A onto story B's branch

```
# EXAMPLE - Branch mismatch warning
$ git branch --show-current
feature/106687/108464/moderator-datasets

If the user has been working on story #108710 / task #109367:
→ Warn: "Current branch is feature/106687/108464/moderator-datasets but the work is for story #108710 task #109367. Should I create a new branch from main?"
```

2. **Only push if validation passes:**
   - Branch matches the work
   - Then execute `git push`

**Note:** These validation rules do NOT apply to .clinerules repository pushes.

## GIT OPERATIONS - CRITICAL RULES

NEVER stage files unless user explicitly requests it OR approves a WIP commit suggestion
NEVER create commits unless user explicitly requests it OR approves a WIP commit suggestion
NEVER push commits unless user explicitly requests it

**CRITICAL: Each operation must be separate**
- NEVER combine `git add` and `git commit` in a single command (e.g., `git add . && git commit`)
- NEVER combine `git commit` and `git push` in a single command (e.g., `git commit && git push`)
- Each operation (add, commit, push) must be executed in SEPARATE tool calls
- This ensures user permission prompts work correctly for each operation

**CRITICAL: Each request is ONE-TIME ONLY**
- If user says "stage these files", run ONLY `git add` then STOP
- If user says "commit this", run ONLY `git commit` then STOP
- If user says "push", run ONLY `git push` then STOP (but ONLY after pre-push validation passes for frontend repos)
- DO NOT continue staging/committing/pushing in subsequent operations unless explicitly asked again
- Each git operation requires fresh explicit permission
- "Always allow" in settings does NOT mean "do this automatically forever"
- You must be explicitly instructed for EACH separate git operation

Exception: WIP commits in frontend repos when user approves a suggestion during development (add + commit in sequence is OK after approval)

User manages git operations manually. Only execute git commands when specifically instructed or when user approves a WIP commit suggestion.
