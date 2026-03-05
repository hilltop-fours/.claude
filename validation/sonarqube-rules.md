# SonarQube Validation Rules

These SonarQube rules are actively enforced in the project. When making changes, avoid triggering them.

## typescript:S4202 — Do not use `any` type

NEVER use `any`. Always define proper interfaces, types, or use generics. If data structure is unknown, use `unknown` and add type guards.

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

## typescript:S109 — Magic numbers should not be used

Do not use numeric literals directly in code when their meaning is unclear. Extract them as named constants to improve readability.

Fix: Define constants with descriptive names at the file or component level.

Exceptions: Common values like 0, 1, -1 are generally acceptable.

**IMPORTANT**: This rule is about NUMBERS, not arrays or named values. Do NOT extract:
- Arrays of enum values used once (e.g., `[StatusEnum.ACTIVE, StatusEnum.PENDING]`)
- Named constants/enums that are already self-explanatory
- Values that are only used in one place and are already readable

The goal is readability. If a value is already self-explanatory (like named enum values), extracting it to a constant just adds indirection.

Example - WRONG (magic numbers):
```typescript
export class MyComponent {
  readonly showMoreAfter = input(3);  // ❌ What does 3 represent?
  readonly maxItems = 10;             // ❌ Magic number

  calculate(value: number) {
    return value * 100;               // ❌ What does 100 represent?
  }
}
```

Example - CORRECT (extracted numbers):
```typescript
const DEFAULT_SHOW_MORE_THRESHOLD = 3;
const MAX_DISPLAY_ITEMS = 10;
const PERCENTAGE_MULTIPLIER = 100;

export class MyComponent {
  readonly showMoreAfter = input(DEFAULT_SHOW_MORE_THRESHOLD);
  readonly maxItems = MAX_DISPLAY_ITEMS;

  calculate(value: number) {
    return value * PERCENTAGE_MULTIPLIER;
  }
}
```

Example - CORRECT (self-explanatory enum values, no extraction needed):
```typescript
// ✅ GOOD - enum values are already named and self-explanatory
[ReviewStatusEnum.IMPORTED, ReviewStatusEnum.PENDING_REVIEW].map((status) => ...)

// ❌ UNNECESSARY - adds indirection for no readability benefit
const ALLOWED_STATUSES = [ReviewStatusEnum.IMPORTED, ReviewStatusEnum.PENDING_REVIEW];
ALLOWED_STATUSES.map((status) => ...)
```

## typescript:S134 — Control flow statements should not be nested too deeply

Do not nest more than 3 levels of `if`/`for`/`while`/`switch`/`try` statements. Deeply nested code is harder to read, test, and maintain.

Fix: Extract nested logic into separate private methods. Each method should handle one level of the logic tree.

Example - WRONG (4 levels of nesting):
```typescript
for (const option of this.options()) {              // Level 1
  if (option.value === value) {                     // Level 2
    return option;
  }
  if (option.children) {                            // Level 2
    for (const child of option.children) {          // Level 3
      if (child.value === value) {                  // Level 4 ❌ TOO DEEP
        return child;
      }
    }
  }
}
```

Example - CORRECT (max 3 levels):
```typescript
for (const option of this.options()) {              // Level 1
  if (option.value === value) {                     // Level 2
    return option;
  }
  const childMatch = this.#findChild(option.children, value);  // Level 2
  if (childMatch) {                                 // Level 2
    return childMatch;
  }
}

// Extract nested logic into separate method
#findChild(children: Item[] | undefined, value: string): Item | null {
  if (!children) {                                  // Level 1
    return null;
  }
  for (const child of children) {                   // Level 1
    if (child.value === value) {                    // Level 2
      return child;
    }
  }
  return null;
}
```

## typescript:S1192 — String literals should not be duplicated

Do not duplicate string literals more than 2 times (i.e., the same literal appearing 3+ times). Duplicated strings make maintenance harder and are error-prone when values need to change.

Fix: Extract the duplicated string into a named constant. If the string represents a type union member or specific value, create both a type and a constant.

Exceptions: Short strings like empty strings `''`, single characters, or common tokens may not need extraction if they serve different semantic purposes.

Example - WRONG (string duplicated 3 times):
```typescript
export class MyComponent {
  columnLayout = input<'theme-date' | 'theme-date-menu' | 'theme-date-pill-owner-menu'>(
    'theme-date-pill-owner-menu'  // Duplication 1
  );

  headerClass = computed(() => {
    const layout = this.columnLayout();
    return {
      'header--theme-date': layout === 'theme-date',
      'header--theme-date-pill-owner-menu': layout === 'theme-date-pill-owner-menu', // Duplication 2
    };
  });

  showOwner = computed(() => {
    return this.columnLayout() === 'theme-date-pill-owner-menu'; // Duplication 3 ❌
  });
}
```

Example - CORRECT (extracted constant):
```typescript
type ColumnLayout = 'theme-date' | 'theme-date-menu' | 'theme-date-pill-owner-menu';

const DEFAULT_COLUMN_LAYOUT: ColumnLayout = 'theme-date-pill-owner-menu';

export class MyComponent {
  columnLayout = input<ColumnLayout>(DEFAULT_COLUMN_LAYOUT);

  headerClass = computed(() => {
    const layout = this.columnLayout();
    return {
      'header--theme-date': layout === 'theme-date',
      'header--theme-date-pill-owner-menu': layout === DEFAULT_COLUMN_LAYOUT, // ✅
    };
  });

  showOwner = computed(() => {
    return this.columnLayout() === DEFAULT_COLUMN_LAYOUT; // ✅
  });
}
```

## css:S4666 — Duplicate CSS selectors

Do not declare the same selector twice in a stylesheet. This happens when layout overrides are split across modifier classes and parent-selector blocks that resolve to the same compiled selector.

Fix: Consolidate all rules for a selector into one place. If a modifier class already targets an element, do not also use a parent-selector (`&`) pattern to target the same element.

## typescript:S106 — Unexpected console statement

Only these console methods are allowed: `assert`, `clear`, `count`, `group`, `groupCollapsed`, `groupEnd`, `info`, `table`, `time`, `timeEnd`, `trace`.

Do NOT use: `log`, `warn`, `error`, `debug`.

Fix: Remove the console statement or replace with an allowed method. For development warnings, use a comment instead. For production logging, use a proper logging service.

Example - WRONG:
```typescript
if (!isValid) {
  console.warn('Validation failed');  // ❌ warn is not allowed
}
```

Example - CORRECT (comment):
```typescript
if (!isValid) {
  // Validation failed - early return
  return;
}
```

Example - CORRECT (allowed method):
```typescript
if (!isValid) {
  console.info('Validation failed');  // ✅ info is allowed
}
```

## typescript:S1128 — Remove unused imports

Remove any import statements that are not used in the code. Unused imports add unnecessary clutter and increase bundle size.

Fix: Delete the unused import statement completely.

Example - WRONG (ElementRef imported but never used):
```typescript
import {
  Component,
  ElementRef,  // ❌ Unused
  inject,
} from '@angular/core';

@Component({...})
export class MyComponent {
  readonly #router = inject(Router);
}
```

Example - CORRECT (only used imports):
```typescript
import {
  Component,
  inject,
} from '@angular/core';

@Component({...})
export class MyComponent {
  readonly #router = inject(Router);
}
```

This is caught automatically by Sonar and ESLint. Always review your imports after refactoring to ensure all are still needed.

## typescript:S1066 — Merge duplicate or unnecessary nested if statements

When an if statement is nested directly inside another if statement with no other code between them, merge the conditions using logical operators (&&, ||) to simplify the code.

Fix: Combine the conditions into a single if statement.

Example - WRONG (unnecessary nesting):
```typescript
if (stepIndex === 2) {
  if (this.selectedRole === RoleEnum.EDITOR) {    // ❌ Unnecessary nesting
    this.resetFields();
  }
}
```

Example - CORRECT (merged conditions):
```typescript
if (stepIndex === 2 && this.selectedRole === RoleEnum.EDITOR) {  // ✅ Combined
  this.resetFields();
}
```

Example - WRONG (multiple nested conditions):
```typescript
if (isValid) {
  if (isUser || isAdmin) {              // ❌ Nested without other logic
    if (hasPermission) {                // ❌ More unnecessary nesting
      processRequest();
    }
  }
}
```

Example - CORRECT (all merged):
```typescript
if (isValid && (isUser || isAdmin) && hasPermission) {  // ✅ Single condition
  processRequest();
}
```

Rationale: Merging nested if statements reduces indentation depth and improves code readability.

## typescript:S121 — Control structures should use curly braces

All control flow statements (`if`, `else`, `for`, `while`, `switch`, `do-while`) MUST be enclosed in curly braces, even if the body contains only a single statement.

Fix: Add curly braces around all single-statement blocks.

Example - WRONG (missing braces):
```typescript
if (condition) return value;          // ❌ Missing braces
if (isValid) doSomething();           // ❌ Missing braces
for (let i = 0; i < 10; i++) total++; // ❌ Missing braces
```

Example - CORRECT (with braces):
```typescript
if (condition) {
  return value;  // ✅ Braces on single statement
}

if (isValid) {
  doSomething();
}

for (let i = 0; i < 10; i++) {
  total++;
}
```

Rationale: This prevents errors when code is later modified and improves code clarity and consistency.

## typescript:S1117 — Variable declared multiple times in same scope

Do not declare a variable with the same name in overlapping scopes. This causes confusion and can lead to bugs where the wrong variable is referenced.

Fix: Rename one of the duplicate variables to have a unique name within its scope.

Example - WRONG (variable declared twice):
```typescript
import { input } from '@angular/core';  // ❌ 'input' imported

#getInputElement() {
  const input = this.inputElement();    // ❌ 'input' redeclared locally
  if (input) {
    return input.nativeElement;
  }
}
```

Example - CORRECT (unique variable names):
```typescript
import { input } from '@angular/core';  // ✅ 'input' imported

#getInputElement() {
  const inputElement = this.inputElement();  // ✅ Different name
  if (inputElement) {
    return inputElement.nativeElement;
  }
}
```

Example - WRONG (same variable in overlapping scopes):
```typescript
control.statusChanges.subscribe(() => {
  const hasUserInteracted = control.touched || !control.pristine;  // ❌ First declaration
  const isInvalid = control.invalid && hasUserInteracted;
});

const hasUserInteracted = control.touched || !control.pristine;    // ❌ Second declaration (conflict!)
const isInvalid = control.invalid && hasUserInteracted;
```

Example - CORRECT (unique names in different scopes):
```typescript
control.statusChanges.subscribe(() => {
  const userInteracted = control.touched || !control.pristine;     // ✅ Renamed
  const invalid = control.invalid && userInteracted;
});

const hasUserInteracted = control.touched || !control.pristine;    // ✅ Different names
const isInvalid = control.invalid && hasUserInteracted;
```

Always ensure variable names are unique within their scope to avoid shadowing and confusion.

## typescript:S2966 — Forbidden non-null assertion

Do not use the non-null assertion operator (`!`) to bypass TypeScript's type safety. Fix the root cause instead.

**Two correct approaches depending on the situation:**

**1. Fix the type at the source** — if the data is always present (e.g. backend always returns it), make the field required in the interface. This eliminates the need for any assertion downstream.

```typescript
// ❌ WRONG — interface too permissive, assertion needed downstream
interface IObligation {
  id?: string;
}
items.map((item) => item.id!) // forced to assert

// ✅ CORRECT — fix the interface, no assertion needed
interface IObligation {
  id: string;
}
items.map((item) => item.id) // clean
```

**2. Narrow with a local variable or `as` cast** — if the field is genuinely optional but you've already filtered/guarded it.

```typescript
// ❌ WRONG — calling signal twice, asserting on second call
if (this.inputRef()?.nativeElement) {
  this.inputRef()!.nativeElement.value = ''; // non-null assertion
}

// ✅ CORRECT — store result once, use optional chaining
const inputRef = this.inputRef();
if (inputRef?.nativeElement) {
  inputRef.nativeElement.value = '';
}

// ❌ WRONG — type predicate verbose and hard to read
.filter((x): x is typeof x & { networkType: DataNetworkEnum } => x.networkType != null)
.map((x) => x.networkType)

// ✅ CORRECT — filter null, cast in map (safe because filter already excluded null)
.filter((x) => x.networkType != null)
.map((x) => x.networkType as DataNetworkEnum)
```

## Web:S6811 — Ensure aria-required is applied to the correct element

The `aria-required` attribute is not supported on certain input types like radio buttons and checkboxes. Instead, place `aria-required="true"` on the parent `fieldset` or a wrapper element that groups the radio/checkbox controls together.

Fix: Move `aria-required` from individual radio/checkbox inputs to their parent `fieldset`.

Example - WRONG (aria-required on individual radio buttons):
```html
<fieldset>
  <legend>Choose an option</legend>
  <input type="radio" name="choice" value="1" aria-required="true" />  <!-- ❌ Wrong -->
  <input type="radio" name="choice" value="2" aria-required="true" />  <!-- ❌ Wrong -->
</fieldset>
```

Example - CORRECT (aria-required on fieldset):
```html
<fieldset aria-required="true">  <!-- ✅ Correct -->
  <legend>Choose an option</legend>
  <input type="radio" name="choice" value="1" />
  <input type="radio" name="choice" value="2" />
</fieldset>
```

Rationale: Radio buttons and checkboxes inherit their role implicitly, so ARIA attributes like `aria-required` should be placed on the grouping element (fieldset) rather than individual inputs.

## Web:MouseEventWithoutKeyboardEquivalentCheck — Mouse events must have keyboard equivalents

Sonar requires that elements with `(click)` also handle `(keydown)`, `(keyup)`, or `(keypress)` for keyboard accessibility.

**This rule produces false positives on design system button components** (`<ntm-button>`, `<ndw-button>`, etc.) because Sonar cannot see through the component abstraction — it doesn't know the component renders a real `<button>` element internally, which already handles keyboard events natively.

**Do NOT add keyboard event handlers to design system button components** — they already handle keyboard interaction correctly.

If Sonar flags this on a native non-interactive element (e.g. `<div (click)="...">`) — that is a real issue. Fix it by using a proper `<button>` element instead.

**Suppress on the Sonar server side** for false positives on design system components, rather than adding unnecessary event handlers.

## typescript:S2871 — Array sort should use a compare function

Do not call `.sort()` on an array of strings without a compare function. The default sort is locale-inconsistent and can produce different results across environments.

Fix: Always pass `(a, b) => a.localeCompare(b)` as the compare function when sorting strings.

Example - WRONG:
```typescript
dates.sort()[0]  // ❌ No compare function
```

Example - CORRECT:
```typescript
dates.sort((a, b) => a.localeCompare(b))[0]  // ✅ Locale-aware compare
```

Note: This applies even when sorting ISO date strings (e.g. `"2025-12-31"`), where plain `.sort()` would technically work — Sonar still flags it.

## Web:S6853 — Form label must be associated with a control

Labels must be associated with their input controls. Use either:
- Explicit: `<label for="myId">` paired with `<input id="myId">`
- Implicit: nest the `<input>` directly inside the `<label>`

Note: This rule can produce false positives in Angular standalone components where Sonar cannot statically resolve `for`/`id` pairs. If the association is correct and Sonar still flags it, suppress on the Sonar server side rather than changing working code.
