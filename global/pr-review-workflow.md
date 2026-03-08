# PR REVIEW COMMENT WORKFLOW

## TRIGGER

User reports a PR review comment. Typical phrases:
- "got a comment on my PR"
- "PR comment on this file"
- "reviewer said..."
- "feedback on this line"
- References a file + a reviewer's comment

## WORKFLOW

1. **Understand the comment** — Read the referenced file and the reviewer's feedback
2. **If unclear** → Ask user for clarification or additional info before changing anything
3. **Fix the issue** in the referenced file
4. **Scan for same pattern** in other files within the scope of changed files on the branch → fix those too
5. **If same issue found outside scope** → Report to user, don't auto-fix (case-by-case judgment)
6. **If reviewer's suggestion would break something**:
   - Try to implement it first
   - If it breaks code or leads to wrong results → defer back to user
   - Discuss together, debug, or draft a reply explaining why it's not feasible
7. **Present output** with three sections (see OUTPUT FORMAT below)

## COMMENT HANDLING CADENCE

- **One comment at a time**: User gives comment → fix → WIP commit → PR response → next comment
- User may explicitly group related comments → handle together, provide response for each
- If user wants a combined response, they'll ask

## OUTPUT FORMAT

After fixing a PR comment, always present:

**What changed:** short summary of the fix

**WIP commit message:** `WIP: english description of what was done`

**PR comment response:**

(plain text fenced code block — no blockquote — so the user can copy-paste directly into GitHub)
````
the dutch response text here
````

## PR COMMENT RESPONSE STYLE

→ See `$CLAUDE_ROOT/global/daniel-voice.md` for full style rules (punctuation, capitalization, tone, output format, examples)
