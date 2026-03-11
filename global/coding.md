# coding.md — Angular/TypeScript Rules

Machine-optimized. Claude-facing only.

---

## Codebase Consistency — HIGHEST PRIORITY

Before implementing any reactive pattern (signals, observables, async pipe, toSignal, etc.): search the existing codebase first.

1. Find 2-3 existing components that consume data from a repository
2. Identify the exact pattern they use
3. Use that exact pattern — not a variation, not an improvement

**What "consistent" means:**
- Existing components use `observable$ | async` in template → new components must too
- Existing repos expose `HttpState<T>` observables → new repos must too
- Existing components pipe through `toResponse()` → new ones must too

**If you find yourself writing something not seen elsewhere in the project — stop and search first.**

Real consequence of skipping: required-publications feature uses `toSignal()` + `computed()`. Without checking, it was replaced with `observable$ | async` + `toResponse()` — requiring multiple rewrites.

---

## Control Flow — Mandatory Syntax

| Use | Never use |
|-----|-----------|
| `@if (condition)` | `*ngIf` |
| `@else` | `*ngIf="!condition"` |
| `@for (item of items; track item.id)` | `*ngFor` |
| `@let variable = expression` | — |

**Loop/iteration variable naming**: Always use the full descriptive name of what the item represents — in templates (`@for`), TypeScript (`forEach`, `map`, `filter`, `reduce`, etc.), and anywhere a variable names a single element from a collection. Never shorten, abbreviate, or use placeholders. The name must communicate what the item is.

```
✅ regulation, organization, skeletonCard, dataItem
❌ _, o, el, item, x, reg, org
```

---

## Signals & Reactivity

**Decorators → signal equivalents (always convert):**

| Old decorator | New signal |
|--------------|-----------|
| `@Input()` | `input()` |
| `@Output()` + `EventEmitter` | `output()` |
| `@ViewChild()` | `viewChild()` |
| `@ViewChildren()` | `viewChildren()` |
| `@ContentChild()` | `contentChild()` |
| `@ContentChildren()` | `contentChildren()` |
| `@HostListener()` / `@HostBinding()` | `host: {}` in `@Component`/`@Directive` |

**After converting decorators — update ALL references:**
- Signal access requires `()`: `this.myChild.method()` → `this.myChild().method()`
- `QueryList<T>` return type → `Signal<readonly T[]>`
- Search entire file for every reference to the converted property

**`toSignal()` in components — check the project first:**
- NTM required-publications: uses `toSignal()` + `computed()` → match this if in that feature
- Other NTM features: use `observable$ | async` + `toResponse()` → match that instead
- Never mix patterns within the same feature area

**Prefer `computed()` over methods for derived values:**
- Method recalculates on every change detection cycle
- `computed()` memoizes — recalculates only when signal dependencies change
- Convert when: method/getter derives from signals, has no side effects

```typescript
// ❌ Method recalculates every cycle
isNew() {
  return this.content()?.createdOn
    ? new Date(this.content()!.createdOn) >= this.#twoMonthsAgo
    : false;
}

// ✅ computed() memoizes
isNew = computed(() => {
  const createdOn = this.content()?.createdOn;
  return createdOn ? new Date(createdOn) >= this.#twoMonthsAgo : false;
});
```

**Self-check before finishing any edit**: scan the file for `@Input`, `@Output`, `@ViewChild`, `@ViewChildren`, `@ContentChild`, `@ContentChildren`, `@HostListener`, `@HostBinding` — replace any found.

---

## Class Structure — Member Ordering

Order within any Angular class:

1. **Injected dependencies** (public → protected → private)
2. **Static fields** (public → protected → private)
3. **Public instance fields:**
   - readonly constants/enums
   - viewChild/contentChild signals
   - input signals
   - model signals
   - output signals
   - httpResource signals
   - toSignal conversions
   - computed signals
   - variables
4. **Protected instance fields** (same subcategories, rare)
5. **Private instance fields** (same subcategories)
6. **Constructor**
7. **Lifecycle hooks** (`ngOnInit`, `ngOnDestroy`, etc.)
8. **Getters/setters** (public → protected → private)
9. **Methods** (public → protected → private)

**Validation scope**: Only flag ordering violations for code added/modified in the current branch. Do not flag pre-existing violations in unchanged lines.

---

## Style Rules

**Ternary for simple conditionals:**
```typescript
// ✅ simple return or assignment
return this.isActive() ? 'Active' : 'Inactive';
const name = user.nickname ? user.nickname : user.fullName;
// ❌ avoid ternary for complex multi-step conditions → use if/else
```

**Nullish coalescing (`??`) for defaults — not `||`:**
```typescript
const count = inputCount ?? 0;    // ✅ preserves 0
const count = inputCount || 0;    // ❌ loses valid 0
// Use || only when empty string SHOULD trigger the fallback
```

**`readonly` for immutable values:**
```typescript
readonly #router = inject(Router);          // ✅
readonly #twoMonthsAgo = subMonths(new Date(), 2);  // ✅
#router = inject(Router);                   // ❌ missing readonly
```

**`#` prefix for private members — not `private` keyword:**
```typescript
readonly #service = inject(Service);  // ✅ true runtime privacy
#calculateTotal() { ... }             // ✅
private readonly service = inject(Service);  // ❌
```

**`[class]`/`[style]` bindings — not `ngClass`/`ngStyle`:**
```html
<div [class.admin]="isAdmin">            <!-- ✅ -->
<div [ngClass]="{admin: isAdmin}">       <!-- ❌ -->
```

**Event handlers — name for action, not event:**
```html
<button (click)="saveUserData()">   <!-- ✅ action-based -->
<button (click)="handleClick()">    <!-- ❌ event-based -->
```
Exception: complex conditional logic in one handler → `handleKeydown(event)` is acceptable.

**`@HostListener` → `host: {}` in decorator:**
```typescript
// ❌
@HostListener('keydown', ['$event'])
handleKeydown(event: KeyboardEvent) { ... }

// ✅
@Component({ host: { '(keydown)': 'handleKeydown($event)' } })
handleKeydown(event: KeyboardEvent) { ... }
```

---

## Simplicity Rules

**Hierarchy:**
1. Simple first — default to the simplest approach that achieves the requirement
2. Reuse before creating — search the codebase for an existing pattern before writing new code
3. Match codebase vocabulary — use the same methods and patterns the team uses
4. Every addition needs a justification — one sentence tied to a specific requirement
5. Don't add what wasn't asked for

**Angular code is written for humans** (colleagues who read/review/maintain it). Not for Claude's optimization preferences. Mid-level developer readable — if it requires tracing multiple abstractions, it's too complex.

**Anti-patterns — do not do these:**
- Adding defensive validation methods not required by any feature
- Creating abstractions or helpers used only once
- Introducing patterns the team doesn't use (even if "technically better")
- Over-typing with complex generics when a simple concrete type works
- Creating utility functions for 2-3 line operations
- Adding type guards/null checks where data flow guarantees the type
- Wrapping simple logic in extra methods just to name it
- Exhaustive error handling for scenarios that can't occur
- Interfaces/types for objects used in only one place
- **Inventing user-visible text from domain knowledge** — translation values, titles, labels must come ONLY from the codebase, story, or user input. Never fill from assumed domain knowledge.
- Chaining maps that could be one: `map(x => x.value).map(v => v.toString())` → `map(x => x.value.toString())`
- Leaving `tap(console.log)` debug calls before a PR
- Private `computed()` + public getter that just returns it → use one public `computed()` instead

**Template anti-patterns:**
- `@if(condition === true)` → `@if(condition)`
- `[attr]="condition ? true : false"` → `[attr]="condition"`
- Wrapping sole `@if` content in `<ng-container>` → `@if` renders nothing when false, no wrapper needed
- Complex inline expressions in templates → move to `computed()` in component

**COMPLEXITY marker** — when sensing complexity during development:
- Add `// COMPLEXITY: reason` at the complex spot (grep: `grep -r "// COMPLEXITY:" src/`)
- Add "Complexity note:" at end of response
- Must ALWAYS be removed before PR submission

Triggers for complexity marker: method >~15 lines, pattern not found elsewhere in project, >2 levels of data transformation, >1 helper method for a single feature.

---

## TypeScript Typing

**Optional properties — always `?`, never `Type | undefined`:**
```typescript
// ❌
export interface IFoo { value: SomeType | undefined; }
// ✅
export interface IFoo { value?: SomeType; }
```

**Never `any`** — use proper interfaces, generics, or `unknown` with type guards.

**Naming conventions:**
- Files: `kebab-case` (`user-profile.component.ts`)
- Classes: `PascalCase` (`UserProfileComponent`)
- Variables/methods: `camelCase` (`getUserData()`)
- Angular suffixes: `.component.ts`, `.service.ts`, `.model.ts`, `.repository.ts`

---

## Comments

**Only add comments when:**
- Marking temp/mocked data: `// TODO: remove mock data`
- Explaining complex "why" not obvious from code
- Non-obvious business rules or edge cases
- Framework limitation workarounds

**Never add:**
- JSDoc that describes what TypeScript types already say
- `@param`/`@returns` JSDoc when the types are self-documenting
- Class-level JSDoc repeating the class name
- Comments for self-explanatory code

**Never remove** existing comments (organizational, explanatory from other devs) unless they become factually incorrect after your changes.

---

## RxJS

**Never nest subscribes.** Use flattening operators:
- `switchMap` — default choice, cancels previous inner observable on new outer value
- `exhaustMap` — ignores new outer while inner is active
- `mergeMap` — parallel execution (only when intentional)

```typescript
// ❌ nested subscribe
this.form.controls.orgId.valueChanges.subscribe(id => {
  this.repo.listUsers(id).subscribe(users => { this.users = users; });
});

// ✅ switchMap
this.form.controls.orgId.valueChanges.pipe(
  switchMap(id => this.repo.listUsers(id)),
  untilDestroyed(this)
).subscribe(users => { this.users = users; });
```

---

## Models & Constants

Avoid hardcoded strings — check for existing models/constants first:
1. Search codebase for existing model or constant
2. Check design system for component models
3. Use model reference instead of hardcoding

---

## Dead Code

After any change that removes or replaces functionality, check and remove:
- Component inputs/outputs no longer bound in any template
- Imports no longer referenced (both `import` statements and `imports: []` array)
- Methods/properties no longer called
- Template bindings referencing removed inputs or methods
- SCSS classes no longer in any template
- Translation keys in `nl.json`/`en.json` no longer referenced

Detection: `validation/dead-code-detection.md` has formal rules and detection commands.

---

## Index Files

Every directory with components, services, repositories, types, or models needs an `index.ts` re-exporting main exports. The `check-index-ts.sh` hook warns when missing — fill in exports manually.

---

## SonarQube Reference

Active rules with fixes: `validation/sonarqube-rules.md`
Key rules: S4202 (no any), S109 (magic numbers), S134 (nesting depth), S1192 (dup strings), S106 (console), S1128 (unused imports), S1066 (merge nested ifs), S121 (braces), S1117 (shadowing), S4666 (dup CSS), S6811 (aria-required), S6853 (form labels), S6840 (autocomplete)

---

## Feedback Log

Real feedback from code reviews. Calibrates what "too complex" means in practice.

### Entry 1: Unnecessary validation methods
Added 3 `validateSomethingCheck()` methods not required by any requirement. Colleagues saw methods with no connection to any user story. Should have been: no validation methods — backend handled validation.

### Entry 2: Invented user-visible text from domain knowledge
Added `"ITS 2023/2661"` as a translation value. Not in the codebase, story, or user input — came from training data about EU ITS regulations. User was asked by colleagues why they wrote that regulation number. Should have been: ask the user, or use a placeholder like `"ITS"`.

### Entry 3: Invented async pattern instead of searching codebase
Needed `loggedInUser` in `ngOnInit` — wrote a new `take(1)` + `filter` pipe from scratch. Project already uses `authService.loggedInUser$.pipe(untilDestroyed(this)).subscribe(...)` in multiple components. Should have been: grep the codebase first, find the pattern, copy it exactly.

---

## Manual Simplicity Review

Triggered by: "review the code", "check complexity", "simplicity check"

For each changed file, check:
1. Every new method tied to a specific requirement?
2. Every pattern matches patterns found elsewhere in the codebase?
3. Any abstractions used only once? (→ should be inlined)
4. Mid-level developer can understand without asking questions?
5. Any patterns not seen elsewhere in the project?
6. Any remaining `// COMPLEXITY:` markers?

Output format:
```
## Simplicity Review

### file-name.component.ts
- Line X: `methodName()` — not tied to any requirement, consider removing
- Line Y: Uses `reduce()` — rest of codebase uses `filter().map()` for this pattern

### file-name.component.html
- (clean)

**Summary**: X issues found across Y files
```
