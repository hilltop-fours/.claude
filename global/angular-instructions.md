# ANGULAR CODING RULES

## CODEBASE CONSISTENCY - HIGHEST PRIORITY RULE

**Before implementing any reactive pattern (signals, observables, async pipe, toSignal, toResponse, etc.), search the existing codebase to find how the same pattern is already handled.**

This is the single most important rule in this file. All other rules are defaults — the codebase is the override.

**Mandatory check before writing any data access pattern:**
1. Find 2-3 existing components that consume data from a repository
2. Identify the exact pattern they use (async pipe + toResponse? signal from repo? computed()?)
3. Use that exact pattern — not a variation, not an improvement, not what the rules below suggest in the abstract

**What "consistent" means in practice:**
- If existing components use `observable$ | async` in the template → new components must too
- If existing repos expose `HttpState<T>` observables without signals → new repos must too
- If existing components pipe through `toResponse()` themselves → new components must too

**The rule below about `toSignal()` is a general Angular guideline. The actual project pattern takes precedence.** Check the project before applying the rule.

**Real example of what happens when this is skipped:**
A `toSignal()` rule said "services must expose signals." Without checking the project first, signals were added to a repository and `computed()` wrappers in components — introducing a pattern inconsistent with every other repository in the codebase, which uses `Observable$ | async` + `toResponse()`. Three rewrites were required to get back to consistency.

---

## CONTROL FLOW - MANDATORY SYNTAX

ALWAYS use new control flow syntax:
- `@if (condition)` - NOT `*ngIf="condition"`
- `@else` - NOT `*ngIf="!condition"`
- `@for (item of items; track item.id)` - NOT `*ngFor="let item of items"`
- `@let variable = expression` - for template variables

NEVER use old syntax: `*ngIf`, `*ngFor`, `*ngSwitch`

## SIGNALS - USAGE RULES

PREFER signals for reactive state:
- Use `input()` for component inputs - NOT `@Input()` decorator
- Use `output()` for component outputs - NOT `@Output()` decorator
- Use signals for component state that needs reactivity
- Use `computed()` for derived values

DO NOT force signals when not needed:
- Traditional approaches are acceptable if signals complicate the code
- If signal refactoring is complex, note as potential future task instead of implementing

**NEVER use `toSignal()` in components — unless the project already does so:**
- Check the project first (see CODEBASE CONSISTENCY rule at top of this file)
- If the project uses `Observable$ | async` throughout, keep using that — do not introduce `toSignal()`
- If the project already exposes signals from repositories, match that pattern
- Only add `toSignal()` to a repo/service if explicitly requested or if the project already uses it
- Components should NEVER call `toSignal()` themselves regardless

**Why this rule exists (human readability)**:
- Round-trip conversions (signal → observable → signal) are confusing to read
- Not immediately clear why the conversions are happening
- Requires mental tracing through multiple reactive layers
- Prefer explicit patterns like `effect()` even if they require subscription management
- Tradeoff: A few lines of cleanup code is better than confusing conversions

**PREFER `computed()` over methods for derived values:**
When a method or getter derives its value from signals and has no side effects, consider converting it to `computed()`.

Benefits:
- Memoization: recalculates only when dependencies change
- Performance: avoids recalculation on every change detection cycle
- Consistency: aligns with signal-based reactivity

Example - WRONG (method recalculates every change detection):
```typescript
content = input<Publication>();
readonly twoMonthsAgo = subMonths(new Date(), 2);

isNew() {
  const content = this.content();
  if (!content?.createdOn) {
    return false;
  }
  return new Date(content.createdOn) >= this.twoMonthsAgo;
}
```

Example - CORRECT (computed with memoization):
```typescript
content = input<Publication>();
readonly #twoMonthsAgo = subMonths(new Date(), 2);

isNew = computed(() => {
  const createdOn = this.content()?.createdOn;
  return createdOn ? new Date(createdOn) >= this.#twoMonthsAgo : false;
});
```

Example - Also CORRECT (computed for derived display values):
```typescript
// Instead of a method that formats every call
getFullName = computed(() => `${this.firstName()} ${this.lastName()}`);

// Instead of getter that checks permissions every call
canEdit = computed(() => this.authService.hasPermission(this.content()));
```

SELF-CHECK — BEFORE finalising any added or edited code, verify that no legacy decorators slipped in:
- `@Input()` → should be `input()`
- `@Output()` with `new EventEmitter()` → should be `output()`
- `@ViewChild()` → should be `viewChild()` (Angular 19+)
- `@ViewChildren()` → should be `viewChildren()` (Angular 19+)
- `@ContentChild()` → should be `contentChild()` (Angular 19+)
- `@ContentChildren()` → should be `contentChildren()` (Angular 19+)
- `@HostListener()` / `@HostBinding()` → should use `host: {}` object in `@Component`/`@Directive` decorator instead

This check is needed because training data is dominated by the older decorator syntax. When in doubt, scan the file you just touched for any of these decorators and replace with the signal equivalent before finishing.

Example - WRONG:
```typescript
@HostListener('keydown', ['$event'])
handleKeydown(event: KeyboardEvent) { ... }
```

Example - CORRECT:
```typescript
@Component({
  host: {
    '(keydown)': 'handleKeydown($event)'
  }
})
handleKeydown(event: KeyboardEvent) { ... }
```

CRITICAL — WHEN converting decorators to signals, UPDATE ALL REFERENCES:

Converting decorators to signals changes how values are accessed. You MUST search for and update all usages:

**@ViewChild / @ViewChildren / @ContentChild / @ContentChildren conversions:**
- Old (decorator): `this.myChild.someMethod()` or `this.children.forEach(...)`
- New (signal): `this.myChild().someMethod()` or `this.children().forEach(...)`
- Return type changes: `QueryList<T>` → `Signal<readonly T[]>` for children queries

**@Input conversions:**
- Old (decorator): `this.myInput` (direct property access)
- New (signal): `this.myInput()` (function call)
- Type changes: `T` → `InputSignal<T>`

**Steps when converting:**
1. Change the decorator to signal syntax
2. Search the entire file for ALL references to that property name
3. Update each reference to use `()` for signal access
4. Update any type annotations (e.g., `QueryList<T>` → use signal return type)
5. Test that the functionality still works

Example - WRONG (forgot to update usage):
```typescript
// Converted declaration but forgot to update usage
filterComponents = viewChildren(BaseFilterDirective);

clearFilters() {
  // ❌ WRONG: Missing () for signal access
  this.filterComponents.forEach((filter) => filter.deselectAll());
}
```

Example - CORRECT (updated both declaration and usage):
```typescript
// Converted to signal
filterComponents = viewChildren(BaseFilterDirective);

clearFilters() {
  // ✅ CORRECT: Added () for signal access
  this.filterComponents().forEach((filter) => filter.deselectAll());
}
```

## INDEX FILES - MANDATORY

Every directory containing components, services, repositories, types, or models must have an `index.ts` that re-exports the main exports.

A hook (`check-index-ts.sh`) detects missing `index.ts` after file writes and will auto-create it. Exports must still be filled in manually.

PURPOSE: Enable imports like `import { MyComponent } from './components/my-component'` instead of `import { MyComponent } from './components/my-component/my-component.component'`

## COMMENTS - RULES

ONLY add comments when:
- Marking temporary/mocked data: Use `// TODO: remove mock data` or `// Temporary for testing`
- Explaining complex logic: Explain "why" not "what"
- Complex business rules that aren't obvious from code alone

DO NOT add comments for:
- Obvious code that is self-explanatory
- Describing what code does (use clear naming instead)
- **JSDoc on simple methods** — method names, parameter names, and TypeScript types already communicate intent
- **JSDoc describing parameters/returns** — TypeScript types are self-documenting
- **Class-level JSDoc** that just repeats the class name

**SPECIFICALLY PROHIBITED - Decorative JSDoc:**

❌ WRONG (describes "what", duplicates type info):
```typescript
/**
 * Service for managing traffic sign ownership
 */
@Injectable({ providedIn: 'root' })
export class TrafficSignOwnerService {
  /**
   * Changes the owner of a traffic sign
   * @param trafficSignId - The ID of the traffic sign
   * @param request - The ownership change request
   * @returns Observable of the change response
   */
  changeOwner(trafficSignId: string, request: OwnerChangeRequest): Observable<OwnerChangeResponse> {
    return this.#http.put<OwnerChangeResponse>(...);
  }
}
```

✅ CORRECT (no JSDoc, types are self-documenting):
```typescript
@Injectable({ providedIn: 'root' })
export class TrafficSignOwnerService {
  changeOwner(trafficSignId: string, request: OwnerChangeRequest): Observable<OwnerChangeResponse> {
    return this.#http.put<OwnerChangeResponse>(...);
  }
}
```

✅ ACCEPTABLE (explains "why" for non-obvious logic):
```typescript
canChangeOwner(trafficSign: TrafficSign, permissions: UserOwnershipPermissions): boolean {
  // Signs without owners can always be claimed by anyone
  if (!trafficSign.ownerRoadAuthorityCode) {
    return true;
  }

  // Only admins and global users can override existing ownership
  return permissions.isAdmin || permissions.hasGlobalMutationPermissions;
}
```

**When JSDoc IS appropriate:**
- Complex algorithms where the "why" isn't obvious
- Non-obvious business rules or edge cases
- Workarounds for framework limitations or bugs
- Public APIs in shared libraries (not typical app code)

NEVER remove existing comments:
- Preserve ALL comments that were already in the code
- This includes organizational comments (e.g., `// Tab state`, `// Filters section`)
- This includes explanatory comments from other developers
- Only remove comments if they become factually incorrect after your changes

## TYPESCRIPT TYPING - STRICT RULES

NEVER use `Type | undefined` for optional interface/model properties:
- Always use `?` (optional property) instead: `prop?: Type` not `prop: Type | undefined`
- This applies to ALL interfaces and model types across all projects — no exceptions
- `prop?: Type` is the correct TypeScript pattern for optional properties

Example - WRONG:
```typescript
export interface IFoo {
  name: string;
  value: SomeType | undefined;
}
```

Example - CORRECT:
```typescript
export interface IFoo {
  name: string;
  value?: SomeType;
}
```

NEVER use `any` type:
- Always define proper interfaces, types, or use generics
- If data structure is unknown, use `unknown` and add type guards
- Create interface/type definitions for complex objects
- SonarQube will flag `any` usage as an error

Example - WRONG:
```typescript
getCategoryDisplay(categories: any[]): string {
  return categories.map(c => c.name).join(', ');
}
```

Example - CORRECT:
```typescript
interface Category {
  id: string;
  name: string;
}

getCategoryDisplay(categories: Category[]): string {
  return categories.map(c => c.name).join(', ');
}
```

## NAMING CONVENTIONS - ENFORCE

File names: kebab-case
- `user-profile.component.ts`
- `auth.service.ts`

Class names: PascalCase
- `UserProfileComponent`
- `AuthService`

Variables and methods: camelCase
- `userName`
- `getUserData()`

Follow Angular file naming patterns:
- Components: `*.component.ts`
- Services: `*.service.ts`
- Models: `*.model.ts`
- Repositories: `*.repository.ts`

## CODE STYLE & VALIDATION RULES

See `validation/angular-style.md` for detailed code style preferences:
- Ternary operators for simple conditionals
- Nullish coalescing for default values
- Readonly for immutable values
- Class and style bindings over ngClass/ngStyle
- Event handler naming conventions
- Private field syntax (#)

See `validation/angular-class-structure.md` for class organization guidelines:
- Class member ordering (dependencies → static → public → protected → private)
- Constructor and lifecycle hook placement

## RXJS - NESTED SUBSCRIBES

NEVER nest subscribes inside subscribes. This causes memory leaks, makes unsubscription unreliable, and complicates error handling.

When the inner observable depends on a value from the outer observable, use a flattening operator instead:
- `switchMap` — preferred default. Cancels the previous inner observable when a new outer value arrives. Use when only the latest result matters (e.g. fetching data based on a changing selection).
- `exhaustMap` — ignores new outer values while the inner observable is still active.
- `mergeMap` — does not cancel; runs all inner observables concurrently. Only use when you intentionally want parallel execution.

Example - WRONG:
```typescript
this.form.controls.organizationId.valueChanges
  .pipe(untilDestroyed(this))
  .subscribe((organizationId) => {
    this.repository.listUsers(organizationId)
      .pipe(untilDestroyed(this))
      .subscribe((users) => {
        this.userList = users;
      });
  });
```

Example - CORRECT:
```typescript
this.form.controls.organizationId.valueChanges.pipe(
  switchMap((organizationId) => this.repository.listUsers(organizationId)),
  untilDestroyed(this)
).subscribe((users) => {
  this.userList = users;
});
```

## STATE MANAGEMENT

State management: NgRx (ngrx)
Async operations: RxJS Observables
Follow existing patterns in codebase

## MODELS AND CONSTANTS - AVOID HARDCODED STRINGS

AVOID hardcoding strings - check for models first

Use models extensively for single source of truth:
- Status values
- Constants
- Enum-like data

Before hardcoding string values:
1. Search codebase for existing models or constants
2. Check design system for component models
3. Use model reference instead of hardcoding

Example: Instead of hardcoding `'DEFINITIVE'`, find publication status model

Purpose: Prevent duplication, centralize updates

## DEAD CODE CLEANUP - MANDATORY

**For formal validation rules and detection methods, see:**
→ `$CLINERULES_ROOT/validation/dead-code-detection.md` - Custom dead code validation rules
→ Automated checks are part of the validation workflow in CLAUDE.md

AFTER any change that removes or replaces functionality, actively check for and remove code that is no longer used. Claude Code does not have IDE greying-out indicators, so this check must be done manually.

ALWAYS check and remove when applicable:
- **Inputs/outputs** on components or base classes that are no longer bound in any template
- **Imports** in `.ts` files that are no longer referenced (both `import` statements and `imports: []` array entries)
- **Methods and properties** on components/services that are no longer called
- **Template bindings** (`[input]`, `(event)`) that reference removed inputs or methods
- **SCSS classes** that are no longer used in any template
- **Translation keys** in `nl.json` / `en.json` that are no longer referenced in templates or code

HOW to check:
1. After making changes, search the codebase for any remaining references to what was removed
2. Pay special attention to base classes — removing an input from a child does not remove it from the parent
3. Use barrel exports (`index.ts`) as a signal: if something is exported but never imported anywhere, it may be dead

PURPOSE: Prevents accumulation of unreferenced code that is invisible without IDE feedback

**Real-world example:**
The Observable method `canEditTrafficSign()` was defined in `road-section-auth.service.ts` but never called anywhere in the codebase. A Signal-based equivalent `canEditTrafficSignSignal()` was actually being used. This unused method (22 lines) was missed during validation because dead code checks were not part of the formal validation workflow. Fixed in commit ac2f2e34. This case motivated the creation of formal dead code detection rules in `validation/dead-code-detection.md`.

## SONARQUBE RULES - KNOWN ISSUES

These SonarQube rules are actively enforced. See `validation/sonarqube-rules.md` for detailed guidance on:
- typescript:S4202 — Do not use `any` type
- typescript:S109 — Magic numbers
- typescript:S134 — Control flow nesting depth
- typescript:S1192 — Duplicated string literals
- css:S4666 — Duplicate CSS selectors
- typescript:S106 — Console statements
- typescript:S1128 — Unused imports
- typescript:S1066 — Merge nested if statements
- typescript:S121 — Control structures with braces
- typescript:S1117 — Variable declaration duplicates
- Web:S6811 — aria-required placement
- Web:S6853 — Form label associations
