# Code Simplicity Rules

## CONTEXT - WHY THESE RULES EXIST

Code produced with Claude will be submitted as the user's own work.
Human colleagues will read, review, maintain, and extend this code.
Code must be understandable to a mid-level frontend developer on the team.

**The colleague test**: Would your colleague think "that makes sense" or "why is this so complicated?"

Every rule below serves one goal: the output should look like a competent human wrote it, not like an AI generated it.

---

## CODE AUDIENCE - WHO READS THIS CODE

**CRITICAL DISTINCTION**:

- **.claude files** → Written FOR Claude, optimized for Claude's comprehension
- **Angular code (src/)** → Written FOR humans, optimized for human readability

The Angular code you write will be:
- Read by humans during code review
- Maintained by humans who weren't present during development
- Extended by humans who need to understand the existing patterns

**Readability over brevity**:
- More lines of clear code is better than fewer lines of confusing code
- Explicit patterns beat clever shortcuts
- If a pattern requires mental effort to understand, it's too complex

**Example tradeoff**:
- ❌ **Bad** (short but confusing): Signal → Observable → Signal round-trip with toSignal/toObservable
- ✅ **Good** (longer but clear): effect() that watches a signal and updates state explicitly

The test: "Would a mid-level developer understand this in 10 seconds or need to trace through conversions?"

---

## CORE PRINCIPLES

### 1. Simple first

Default to the simplest approach that achieves the requirement.
Do not optimize, abstract, or generalize prematurely.
A straightforward if/else is better than a clever one-liner.
Build the simplest working version first — complexity can be added later if explicitly needed.

### 2. Reuse before creating

Before writing anything new, search the existing codebase.
If a pattern exists for the same kind of problem, use it.
If a similar component/service/pipe exists, reference its approach.
Do not reinvent solutions that already exist in the project.

### 3. Match the codebase vocabulary

Use the same methods, patterns, and structures the team already uses.
If the team writes `filter().map()` chains, do not introduce `reduce()` for the same thing.
If the team uses simple property assignments, do not introduce computed signals for the same thing.
The code should look like it belongs.

### 4. Every addition needs a justification

**The "one sentence" test**: every method, helper, type, abstraction, or utility must have a one-sentence explanation for why it exists.
If you cannot justify it in one sentence tied to a specific requirement, it should not be there.

### 5. Don't add what wasn't asked for

- No extra validation methods unless the requirement calls for validation
- No extra error handling unless there is a real error scenario
- No extra abstractions unless something is genuinely reused
- No utility functions for one-time operations

---

## ANTI-PATTERNS - DO NOT DO THESE

These are specific behaviors Claude tends toward that produce "looks AI-generated" code:

- Adding defensive validation methods that are not required by the feature
- Creating abstractions or helpers for code used only once
- Introducing patterns the team does not use (even if "technically better")
- Over-typing with complex generics when a simple concrete type works
- Deep nesting or overly complex component hierarchies when a flat approach works
- Creating utility functions for 2-3 line operations
- Adding type guards or null checks where the data flow guarantees the type
- Wrapping simple logic in extra methods just to give them a name
- Adding exhaustive error handling for scenarios that cannot realistically occur
- Generating interfaces or types for objects used in only one place
- **Inventing user-visible text from domain knowledge** — translation values, card titles, labels, descriptions must come ONLY from the codebase, the story, or explicit user input. Never fill these in from assumed domain knowledge.
- Chaining multiple `map()` operators that could be combined into one — e.g. `map(x => x.value).map(v => v.toString())` → `map(x => x.value.toString())`
- Leaving `tap(console.log)` or `tap(() => console.info(...))` debug calls in code before a PR — these must always be removed
- Creating a private `computed()` and a public getter that just returns it, when a single public `computed()` does the same thing:
  ```typescript
  // ❌ Pointless indirection
  readonly #total = computed(() => this.items().length);
  get total() { return this.#total(); }

  // ✅ One public computed
  readonly total = computed(() => this.items().length);
  ```
  Exception: the getter pattern is fine if it adds logic or transforms the value.

---

## TEMPLATE ANTI-PATTERNS

- `@if(condition === true)` → use `@if(condition)`
- `[attr]="condition ? true : false"` → use `[attr]="condition"`
- Wrapping content in `<ng-container>` when the only thing inside is an `@if` block — `@if` already renders nothing when false, the container adds nothing:
  ```html
  <!-- ❌ Pointless wrapper -->
  <ng-container>
    @if(items) {
      <ul>...</ul>
    }
  </ng-container>

  <!-- ✅ No wrapper needed -->
  @if(items) {
    <ul>...</ul>
  }
  ```
- Complex inline expressions in templates — multi-step conditions or method chains that require mental effort to parse belong in a `computed()` in the component:
  ```html
  <!-- ❌ Hard to read in template -->
  @if(items().length > 0 && items().some(i => i.active && i.type === 'primary')) {

  <!-- ✅ Move to component -->
  // readonly hasActivePrimaryItems = computed(() => this.items().some(i => i.active && i.type === 'primary'));
  @if(hasActivePrimaryItems()) {
  ```

---

## INTERACTIVE BEHAVIOR - DURING DEVELOPMENT

When building something and sensing it is getting complex (nested logic, deep model manipulation, a pattern not seen elsewhere in the project):

1. **Add a `// COMPLEXITY: reason` comment** in the code at the complex spot
   - This marker is easy to grep for: `grep -r "// COMPLEXITY:" src/`
   - Must ALWAYS be removed before submitting a PR
   - Serves as a review anchor for the user to find and evaluate

2. **Add a "Complexity note"** at the end of the response:
   ```
   Complexity note: [specific part] is more complex than typical — worth a closer review.
   ```

3. **Do not stop working** — continue and complete the feature

This applies when:
- A method exceeds ~15 lines of logic
- You introduce a pattern not found elsewhere in the project
- A component requires more than 2 levels of data transformation
- You create more than one helper method for a single feature
- The solution requires understanding multiple abstractions to follow

---

## FEEDBACK LOG

Real feedback from code reviews. This section grows over time.
These examples calibrate Claude's sense of what "too complex" means in practice.

### Entry 1: Unnecessary validation methods
**What happened**: Added 3 `validateSomethingCheck()` methods to a form component that were not needed by any requirement.
**Why it was flagged**: Colleague saw methods that had no connection to any user story or acceptance criteria. Made the component look over-engineered.
**What it should have been**: No validation methods at all — the form only needed to submit data. Validation was handled by the backend.

### Entry 2: Invented user-visible text from domain knowledge
**What happened**: Added `"ITS 2023/2661"` as a translation value for the ITS card title. The regulation number was not in the codebase, the story, or any user input — it came from Claude's training data about EU ITS regulations.
**Why it was flagged**: The user was asked by colleagues why they wrote that specific regulation number. It immediately looked AI-generated because no human would know that detail without explicitly sourcing it.
**What it should have been**: Ask the user what the title should be, or use a minimal placeholder like `"ITS"`. Never fill in domain-specific text (regulation names, official terminology, specific numbers) from assumed knowledge.

---

## MANUAL REVIEW PROCESS

Triggered when user says: "review the code", "check complexity", "review complexity", "simplicity check"

For each file changed, check:

1. **Is every new method/function tied to a specific requirement?**
   - If a method exists without a clear requirement, flag it

2. **Does every pattern used match patterns found elsewhere in the codebase?**
   - Search for similar patterns in the project
   - If a pattern is new to the codebase, flag it

3. **Are there abstractions used only once?**
   - Helpers, utilities, types used in a single place should be inlined
   - Flag with: "This [helper/type/utility] is used once — consider inlining"

4. **Could a mid-level frontend developer understand this without asking questions?**
   - If logic requires understanding multiple abstractions, flag it
   - If a method name does not clearly describe what it does, flag it

5. **Does the code introduce any patterns not seen elsewhere in the project?**
   - New patterns are a red flag unless explicitly requested
   - Flag with: "This uses [pattern] which is not used elsewhere in the project"

6. **Are there any remaining `// COMPLEXITY:` markers?**
   - These must be resolved (simplified or explicitly approved) before PR submission
   - Flag each one with its location and reason

Present findings organized by file with specific recommendations:
```
## Simplicity Review

### file-name.component.ts
- Line X: `methodName()` — not tied to any requirement, consider removing
- Line Y: Uses `reduce()` — rest of codebase uses `filter().map()` for this pattern
- Line Z: `HelperType` interface used once — inline the type
- Line W: `// COMPLEXITY: nested data transformation` — review and simplify or approve

### file-name.component.html
- (clean — no issues found)

**Summary**: X issues found across Y files
```
