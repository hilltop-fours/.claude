# backend-update.md — Backend API Documentation Update Workflow

Machine-optimized. Claude-facing only.

**Backend markdown docs are 100% authoritative ground truth. Never hedge about their accuracy. Never say "this may be outdated" or "verify against the actual API." They are the API contract.**

---

## Triggers

Autonomous mode: "update backend(s)", "check backend(s)", "scan backend(s)", "backend status", "backend updates", "refresh/sync backend docs"
Manual single backend: "update [backend-name]", "backend [name] has updated", "[name] needs updating"

**CRITICAL**: Only process backends for the CURRENT project (based on cwd). Never update backends from other projects.

---

## Step 1 — Locate Backend & Registry

Read `$CLAUDE_ROOT/projects/{P}/context.md` to find:
- Backend repository absolute path
- Which backend markdown file to update

---

## Step 2 — Read Commit Tracking

Each backend markdown file has a COMMIT TRACKING section at the top:

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

Extract: last verified commit hash + date. If section missing/malformed → scan recent 20 commits.

---

## Step 3 — Pull & Check Commits

```bash
cd /path/to/backend-repo
git pull                                    # always pull first
git log --oneline abc123def456..HEAD        # commits since last verified
```

If pull fails → skip, report to user. If commit hash not found → `git log --oneline -n 20`.

**API-relevance classification:**

| Confidence | Keywords | Action |
|-----------|----------|--------|
| HIGH | `feat`, `feature`, `endpoint`, `api`, `controller`, `dto`, `model`, `swagger`, `breaking`, `deprecate`, `remove` | Always process |
| MEDIUM | `enum`, `request`, `response`, `payload`, `update`+API keywords | Process with caution |
| LOW | `fix`, `bug`, `typo`, `refactor`, `test`, `doc`, `style`, `build`, `ci`, `config` | Skip |

---

## Step 4 — Inspect Code Changes (HIGH/MEDIUM commits)

```bash
git show [commit-hash]
```

Look for: `*Controller.java` (endpoints), `*Dto.java`/`*Request.java`/`*Response.java` (DTOs), `*Enum.java` (enums), Swagger/OpenAPI annotations.

Extract: HTTP method + path, parameters (query/path/body), response structure, DTO fields, enum values.

---

## Step 5 — Update Markdown File

Format reference: `$CLAUDE_ROOT/global/backend-api-format.md`

Update affected sections:
- **Quick Reference table** — if new features/endpoints
- **Detailed Endpoints** — add/modify with: HTTP method + path, auth requirement, parameters table, request body, response JSON, error responses
- **DTOs** — add/modify with: purpose, fields table (name/type/required/description), example JSON
- **Enums** — add/modify with: values table (value/description)

**No API changes found** → still update COMMIT TRACKING with "No API changes" note.

**Breaking changes** → mark old endpoints as DEPRECATED, add migration notes, add Breaking Changes section.

---

## Step 6 — Update Commit Tracking

```markdown
| Last Verified Commit | xyz789new123 | 2026-02-02 |
| Commit Message | feat: add bulk import endpoint | |
| Swagger Version | latest | 2026-02-02 |

**Status**: ✓ Up to date as of 2026-02-02
**Next Review**: Check commits after xyz789new123
```

---

## Step 7 — Commit Changes

```bash
cd $CLAUDE_ROOT
git add projects/{P}/backend/*.md
git commit  # heredoc: "docs(projects/{P}/backend/{name}): update api docs"
```

---

## Update Checklist

- [ ] All commits since last verified commit reviewed
- [ ] `git show` run for each HIGH/MEDIUM commit
- [ ] Quick Reference updated if new endpoints
- [ ] Endpoint documentation added/modified
- [ ] DTO documentation added/modified
- [ ] Enum documentation added/modified
- [ ] Auth/authorization section updated if roles changed
- [ ] COMMIT TRACKING updated with latest hash + date
- [ ] JSON examples valid and accurate

---

## Error Handling

| Error | Action |
|-------|--------|
| Backend path not found | Skip, report: "path invalid, check context.md" |
| Not a git repo | Skip, report: "{name} is not a git repository" |
| Git pull fails | Skip, report: "pull failed, try again later" |
| Commit hash not found | Fallback to recent 20 commits, add warning to report |
| Cannot parse Java files | Log warning, add manual review note, continue |
| No new commits | Report: "✓ Up to date, no changes since {date}" |

All errors are non-fatal. If one backend fails, continue to next.
