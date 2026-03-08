# BACKEND API DOCUMENTATION - UPDATE INSTRUCTIONS

## WHEN TO UPDATE BACKEND API DOCS

User will say: "Backend [name] has updated, could you check if the API needs updating?"

This triggers the update workflow below.

---

## UPDATE WORKFLOW - REGISTRY SYSTEM

### Step 1: Locate the Backend Repository

Read the project-specific `project-instructions.md` to find:
- Backend repository absolute path
- Which backend markdown file to update

**Example**:
- User: "ntm-backend has updated"
- Read: `.claude/projects/NTM-Publicatie-overzicht/project-instructions.md`
- Find: Backend repo at `/Users/daniel/Developer/NTM-Publicatie-overzicht/ntm-backend/`
- Update file: `.claude/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`

### Step 2: Find the Registry File

Each backend markdown file has a **COMMIT TRACKING** section at the top:

```markdown
## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | abc123def456 | 2026-01-30 |
| Commit Message | feat: add new endpoint | |
| Swagger Version | latest | 2026-01-30 |

**Status**: ✓ Up to date as of 2026-01-30
**Next Review**: Check commits after abc123def456
```

The commit hash `abc123def456` is your starting point.

### Step 3: Pull Latest Changes and Check New Commits

Navigate to the backend repository, pull the latest changes from remote, and check commits since the last verified commit:

```bash
cd /path/to/backend-repo

# Pull latest changes from remote to sync with origin
git pull

# Check commits since last verified commit
git log --oneline abc123def456..HEAD
```

Review each commit message to determine if it affects the API.

**Important**: Always pull from remote first to ensure you're checking the latest commits, not just local commits. If pull fails, skip this backend and try again later when the issue is resolved.

### Step 4: Determine What Needs Updating

**Update markdown if commit involves**:
- ✅ New endpoints
- ✅ Modified endpoints (path, parameters, response structure)
- ✅ New/changed DTOs (request/response models)
- ✅ New/changed enum values
- ✅ Authentication/authorization changes
- ✅ Deprecated endpoints

**Skip updating if commit only involves**:
- ❌ Internal implementation details
- ❌ Database schema changes (that don't affect API contract)
- ❌ Bug fixes that don't change API behavior
- ❌ Code refactoring without API changes
- ❌ Test updates

### Step 5: Read the Actual Code Changes

For commits that need updating:

```bash
git show [commit-hash]
```

Look for changes in:
- Controller files (endpoints)
- DTO files (request/response models)
- Enum files
- Swagger/OpenAPI annotations

### Step 6: Update the Markdown File

Read `.claude/global/backend-api-format.md` for format specifications.

Update the affected sections:
- **Quick Reference table** (if new features/endpoints)
- **Detailed Endpoints section** (add/modify endpoint docs)
- **DTOs section** (add/modify data structures)
- **Enums section** (add/modify enum values)
- **Authentication section** (if roles changed)

### Step 7: Update the Commit Tracking Table

After updating, modify the COMMIT TRACKING section with the latest commit:

```markdown
## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | xyz789new123 | 2026-02-02 |
| Commit Message | feat: add bulk import endpoint | |
| Swagger Version | latest | 2026-02-02 |

**Status**: ✓ Up to date as of 2026-02-02
**Next Review**: Check commits after xyz789new123
```

**What to update**:
- Last Verified Commit → Latest commit hash
- Commit Message → Latest commit message summary
- Date fields → Today's date (YYYY-MM-DD)
- Status → Today's date
- Next Review → Latest commit hash

---

## UPDATE CHECKLIST

Before finalizing updates:

- [ ] Read all commit messages since last verified commit
- [ ] Check actual code changes for each relevant commit using `git show`
- [ ] Update Quick Reference table if new features/endpoints added
- [ ] Add/modify affected endpoint documentation
- [ ] Add/modify affected DTO documentation
- [ ] Add/modify affected enum documentation
- [ ] Update authentication/authorization section if roles changed
- [ ] Update COMMIT TRACKING table with latest commit hash and date
- [ ] Verify all JSON examples are valid and accurate
- [ ] Check for broken internal links to DTOs/enums
- [ ] Ensure consistency in terminology throughout document

---

## FORMAT REFERENCE

If unsure about documentation format, read:
`.claude/global/backend-api-format.md`

This reference file contains:
- Detailed endpoint documentation format
- DTO documentation format with examples
- Enum documentation format
- Example structures and templates
- Style guidelines for consistency

Only read this file if you need clarification on formatting. The update workflow above covers the process.

---

## COMMON SCENARIOS

### Scenario 1: Multiple Commits Since Last Update

If there are many commits:
1. List all commits: `git log --oneline abc123..HEAD`
2. Review each commit message
3. For API-relevant commits, check code changes with `git show`
4. Group related changes together in your update
5. Update COMMIT TRACKING to the very latest commit (not intermediate ones)

### Scenario 2: No API Changes Found

If commits don't affect the API contract:
1. Still update COMMIT TRACKING table to latest commit
2. Add note in commit message field: "No API changes"
3. This prevents re-checking the same commits next time

### Scenario 3: Unsure If Change Affects API

When in doubt:
1. Check the actual code with `git show [hash]`
2. Look for changes in controller methods, DTO fields, or annotations
3. If still unsure, include it in the update (better to document than miss it)

### Scenario 4: Breaking Changes

If a commit introduces breaking changes:
1. Mark old endpoints as **DEPRECATED** in documentation
2. Add migration notes explaining what changed
3. Document new endpoint/DTO structure
4. Add a **Breaking Changes** section if needed
