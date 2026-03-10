# stories.md — Story Workflow

Machine-optimized. Claude-facing only.

---

## Triggers

Activate when user says: "new story", "start story", "here's the story", "new task", "new bug" — or posts Azure DevOps screenshots of a story/task/bug.

---

## Story File — Two-Section Rule

Story files have exactly two kinds of content:

1. **Original Azure DevOps text** — preserved verbatim, no compression, no paraphrasing, original language (Dutch/English)
2. **Claude-added content** — dense, machine-optimized, Claude-facing format (Analysis, Implementation Plan, etc.)

Never compress or rewrite the original text sections. Compaction must not touch them.

---

## Step 1 — Extract & Save Original Text (IMMEDIATELY)

**Do this first, before anything else. No code changes in this step.**

Save to: `$CLAUDE_ROOT/stories/[storyId-taskId-description].md`

**Filename rules:**
- Format: `storyId-taskId-description.md` (no type/scope prefix)
- Strip `#` and `:`, spaces → `-`, all lowercase
- Description in English (translate Dutch titles; keep Dutch proper nouns/product terms)
- Example: `12345-67890-add-map-zoom-controls.md`
- English requirement applies to: filename description, branch name description, PR title description

**One file per task/bug.** Multiple children of the same story → each gets its own file with story context repeated.

**File structure:**

```markdown
# [PR Title]

**Story:** #[id] / **Task:** #[id]
**Branch:** `type/[story-id]/[task-id]/description`
**Date:** YYYY-MM-DD

---

## Story — Original Text

### Description
[Exact text from screenshot — preserve original language and formatting]

### Acceptance Criteria
[Exact text from screenshot — preserve original language and formatting]

### Discussion
[Exact text from screenshot, or "None"]

---

## Task — Original Text

### Description
[Exact text from screenshot, or "See story"]

### Discussion
[Exact text from screenshot, or "None"]

---

## Analysis

[Filled in during Step 2]

---

## Implementation Plan

[Filled in during Step 3]
```

---

## Step 2 — Analyze & Discuss (parallel with Step 1)

Explore relevant codebase while Step 1 runs. Rules:
- Conversational only — no code examples, no implementation details
- No code changes
- Explain what the story asks, what already exists, what needs building
- Confirm understanding before planning

**Use `AskUserQuestion` for gaps/ambiguities:**
- Vague story text or multiple valid interpretations
- Multiple valid approaches (UX, technical, architectural)
- Unclear dependency (is backend merged? what's the data source?)
- Existing code that partially matches but isn't certain fit
- Business logic edge cases not covered by the story

Group related questions (up to 4 per call). Frame around what you found in the code.

After discussion → update the Analysis section in the story file with agreed decisions.

---

## Step 3 — Create Phased Plan

Break work into phases, each independently verifiable and committable.

- Each phase: small enough to check works, produces visible/testable result where possible
- Suggest WIP commits between phases
- Update Implementation Plan section in story file

```markdown
### Phase 1: [Name]
[Deliverables, not implementation details]

### Phase 2: [Name]
...
```

---

## Backend Assumption

**Default: backend does NOT exist.** Always mock on the frontend unless user explicitly says "backend is merged" or "backend is ready." Never check the backend repo or ask — wait for user to say.

---

## Step 4 — Dev Tools (almost always needed)

Backend not merged → dev tools needed to mock service responses.
Also needed: testing with different account types/roles, simulating data states.

**Phase ordering — dev tools come EARLY:**
1. Phase 1: Models, interfaces, component shells, wiring
2. Phase 2: Dev tools + mock data + mock services ← here, not at the end
3. Phase 3+: Actual feature work (testable with mock data from day one)

Keep mocks simple — just enough to unblock development. User decides when to clean up.

---

## Step 5 — Execute Phases

**First step where code changes are allowed.** Steps 1–4 produce only markdown.

Only start when user explicitly says to implement. Work one phase at a time:
- Follow `global/coding.md` for all Angular code
- Do NOT run validation during development
- Suggest WIP commits at natural breakpoints
- Wait for user confirmation before next phase

---

## Step 6 — Validate (when asked)

Only when user explicitly asks. Follow the validate trigger in CLAUDE.md.
