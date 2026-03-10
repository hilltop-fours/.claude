# pr-review.md — PR Review Comment Workflow

Machine-optimized. Claude-facing only.

---

## Triggers

User reports a PR review comment: "got a comment on my PR", "reviewer said...", "feedback on this line", references a file + reviewer's comment.

---

## Workflow

1. Read the referenced file and the reviewer's feedback
2. If unclear → ask user before changing anything
3. Fix the issue in the referenced file
4. Scan for same pattern in other changed files on the branch → fix those too
5. Same issue found outside branch scope → report to user, don't auto-fix
6. If reviewer's suggestion would break something:
   - Try to implement it first
   - If it breaks or produces wrong results → defer to user, discuss, or draft a reply explaining why not feasible

---

## Cadence

One comment at a time: user gives comment → fix → WIP commit → PR response → next comment.
User may explicitly group related comments → handle together, provide response for each.

---

## Output Format

After fixing, always present:

**What changed:** short summary of the fix

**WIP commit message:** `WIP: english description of what was done`

**PR comment response:**

(plain text fenced code block — no blockquote — so user can copy-paste into GitHub)
````
the dutch response text here
````

---

## Response Style

See `$CLAUDE_ROOT/global/voice.md` for full style rules (punctuation, capitalization, tone, voice modes, examples).
