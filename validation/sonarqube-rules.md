# SonarQube Rules

Active rules in this project. Match rule ID from Sonar error → find entry → apply fix.

---

## typescript:S4202
No `any`. Use proper types, generics, or `unknown` + type guards.
```typescript
❌ fn(items: any[])
✅ fn(items: Category[])
```

---

## typescript:S109
Extract magic numbers as named constants. Exception: 0, 1, -1 are fine.
**IMPORTANT**: This is about bare numbers only — not enum arrays. `[StatusEnum.ACTIVE, StatusEnum.PENDING]` is already named, do NOT extract it.
```typescript
❌ readonly showMoreAfter = input(3);
✅ const DEFAULT_SHOW_MORE_THRESHOLD = 3; ... readonly showMoreAfter = input(DEFAULT_SHOW_MORE_THRESHOLD);
```

---

## typescript:S134
Max 3 levels of nested control flow (`if`/`for`/`while`/`switch`/`try`).
Fix: extract inner logic into a private method.

---

## typescript:S1192
Same string literal used 3+ times → extract as named constant.
Exception: short strings (`''`, single chars) that serve different semantic purposes.
```typescript
❌ 'theme-date-pill-owner-menu' used 3× inline
✅ const DEFAULT_COLUMN_LAYOUT: ColumnLayout = 'theme-date-pill-owner-menu';
```

---

## css:S4666
No duplicate selectors in SCSS. Consolidate all rules for a selector into one block.
Happens when modifier class + parent-selector `&` resolve to the same compiled selector.

---

## typescript:S106
Allowed console methods: `assert`, `clear`, `count`, `group`, `groupCollapsed`, `groupEnd`, `info`, `table`, `time`, `timeEnd`, `trace`.
Forbidden: `log`, `warn`, `error`, `debug`.

---

## typescript:S1128
Remove unused imports. Check after every refactor.

---

## typescript:S1066
Merge nested `if` with no other code between them using `&&` / `||`.
```typescript
❌ if (a) { if (b) { fn(); } }
✅ if (a && b) { fn(); }
```

---

## typescript:S121
All control flow bodies need curly braces, even single-statement.
```typescript
❌ if (x) return y;
✅ if (x) { return y; }
```

---

## typescript:S1117
No variable with the same name in overlapping scopes (shadowing).
Common case: importing `input` from Angular then using `const input = ...` locally → rename local to `inputElement`.

---

## typescript:S2966
No non-null assertion (`!`). Two approaches:
1. Fix the interface — make the field required if it's always present
2. Store signal result in a variable first, then use optional chaining

```typescript
❌ this.inputRef()!.nativeElement.value = ''
✅ const ref = this.inputRef(); if (ref) { ref.nativeElement.value = ''; }

❌ .filter((x): x is typeof x & { networkType: DataNetworkEnum } => x.networkType != null)
✅ .filter((x) => x.networkType != null).map((x) => x.networkType as DataNetworkEnum)
```

---

## typescript:S4157
Omit redundant default type parameters.
```typescript
❌ readonly closeEmitter = output<void>();
✅ readonly closeEmitter = output();
```

---

## typescript:S4798
Replace `param?: Type` with `param = defaultValue` for optional parameters.
```typescript
❌ closePopup(confirm?: boolean): void { this.closeEmitter.emit(confirm ?? false); }
✅ closePopup(confirm = false): void { this.closeEmitter.emit(confirm); }
```

---

## typescript:S2871
Always pass compare function to `.sort()` on strings.
```typescript
❌ dates.sort()[0]
✅ dates.sort((a, b) => a.localeCompare(b))[0]
```

---

## Web:S6811
`aria-required` not valid on individual radio/checkbox inputs. Move to parent `<fieldset>`.
```html
❌ <input type="radio" aria-required="true" />
✅ <fieldset aria-required="true"> ... <input type="radio" /> ... </fieldset>
```

---

## Web:MouseEventWithoutKeyboardEquivalentCheck
**FALSE POSITIVE** on `<ntm-button>`, `<ndw-button>` — they render a real `<button>` internally.
Do NOT add keyboard handlers to design system components.
Real violation: `<div (click)="...">` with no keyboard handler → replace with `<button>`.
Suppress false positives server-side.

---

## Web:ItemTagNotWithinContainerTagCheck
**FALSE POSITIVE** with Angular `ng-template` + `ngTemplateOutlet` — Sonar can't see the `<li>` is projected into an `<ol>` at runtime.
Do NOT wrap `<li>` in a redundant container. Suppress server-side.
Real violations (bare `<li>` genuinely outside a list) still need fixing.

---

## Web:S6851
**FALSE POSITIVE** when signal/variable name contains "image" (e.g. `image().alt`) — Sonar flags the binding expression, not the rendered value.
Do NOT add `@let` workarounds to rename the variable.
Suppress server-side for `[alt]="image().alt | translate"` patterns.
Real violations (alt text literally says "image"/"photo") still need fixing.

---

## Web:S6853
Labels must be associated with controls: explicit `for`/`id` pair or implicit nesting.
**Can produce false positives** in Angular when Sonar can't statically resolve `for`/`id` pairs. If the association is correct, suppress server-side.

---

## Web:S6840
`autocomplete` must use valid HTML spec tokens. Invalid values are silently ignored by browsers.

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `organization-name` | `organization` |
| `country-name` | `country` |

Other valid tokens: `name`, `given-name`, `family-name`, `email`, `tel`, `url`, `postal-code`, `street-address`, `address-line1`, `address-line2`, `address-level1`, `address-level2`

---

## Web:S6819
`role="dialog"` on non-`<dialog>` elements → Sonar recommends native `<dialog>`.
**Do NOT fix during signal migration PRs** — migrating `<aside role="dialog">` to `<dialog>` requires CSS, `open` attribute, and JS changes (`showModal()`/`close()`). Belongs in a dedicated accessibility story.
Suppress server-side, track as follow-up.
