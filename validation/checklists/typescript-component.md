# TypeScript Component Validation Checklist

**Applies to:** `.component.ts`, `.service.ts`, `.repository.ts`, `.directive.ts`, `.pipe.ts`

**Total checks:** 48

This checklist consolidates ALL applicable validation rules from:
- angular-instructions.md
- code-simplicity.md
- angular-style.md
- angular-class-structure.md
- dead-code-detection.md
- sonarqube-rules.md

---

## Angular Instructions (15 checks)

- [ ] Uses input()/output() not @Input/@Output decorators → ✓/✗ with lines
- [ ] Uses viewChild() not @ViewChild() → ✓/✗ with lines
- [ ] Signal references use () → ✓/✗ with lines
- [ ] No decorative JSDoc → ✓/✗ with lines
- [ ] No any type → ✓/✗ with lines
- [ ] No nested subscribes → ✓/✗ with lines
- [ ] No toSignal() in components → ✓/✗ with lines
- [ ] Prefer computed() over methods for derived values → ✓/✗ with method names
- [ ] All decorator→signal conversions updated references → ✓/✗ with lines
- [ ] Index.ts files exist for new directories → ✓/✗ with paths
- [ ] Naming conventions (PascalCase classes, camelCase vars) → ✓/✗
- [ ] No hardcoded strings (use models/constants) → ✓/✗ with lines
- [ ] Proper TypeScript typing (no any, proper interfaces) → ✓/✗
- [ ] RxJS: No nested subscribes, use switchMap → ✓/✗ with lines
- [ ] Dead code removed after changes → ✓/✗

## Code Simplicity (8 checks)

- [ ] Every method tied to a specific requirement → ✓/✗ with method names
- [ ] Patterns match existing codebase patterns → ✓/✗ with details
- [ ] No abstractions used only once → ✓/✗ with names
- [ ] No // COMPLEXITY: markers remaining → ✓/✗ with lines
- [ ] Mid-level developer readable → ✓/✗
- [ ] Simple first (no premature optimization) → ✓/✗
- [ ] Reused existing utilities/patterns → ✓/✗
- [ ] No unnecessary defensive code → ✓/✗

## Style Preferences (5 checks)

- [ ] Ternary for simple conditionals → ✓/✗ with lines
- [ ] Nullish coalescing (??) for defaults → ✓/✗ with lines
- [ ] readonly for immutable values → ✓/✗ with lines
- [ ] Event handlers describe action → ✓/✗
- [ ] Private fields use # syntax → ✓/✗ with lines

## Class Structure (6 checks)

- [ ] Dependencies first → ✓/✗
- [ ] Public→protected→private ordering → ✓/✗
- [ ] Signals properly ordered (ViewChild, Input, Output, computed, vars) → ✓/✗
- [ ] Constructor position correct → ✓/✗
- [ ] Lifecycle hooks positioned correctly → ✓/✗
- [ ] Methods last (public→protected→private) → ✓/✗

## Dead Code Detection (5 checks)

- [ ] No unused local variables → ✓/✗ with lines
- [ ] No unused function parameters → ✓/✗ with lines
- [ ] No dead stores/assignments → ✓/✗ with lines
- [ ] No unused private methods/properties → ✓/✗ with names
- [ ] No unreachable code → ✓/✗ with lines

## SonarQube Rules (9 checks)

- [ ] No any type (S4202) → ✓/✗ with lines
- [ ] No magic numbers (S109) → ✓/✗ with lines
- [ ] Max nesting depth 3 (S134) → ✓/✗ with lines
- [ ] No duplicate strings (S1192) → ✓/✗ with lines
- [ ] No console.log/warn/error (S106) → ✓/✗ with lines
- [ ] No unused imports (S1128) → ✓/✗
- [ ] Merge nested if statements (S1066) → ✓/✗ with lines
- [ ] Control structures use braces (S121) → ✓/✗ with lines
- [ ] No variable shadowing (S1117) → ✓/✗ with lines

---

## Verification

After completing all checks:

**Total checks completed:** ____/48

✅ All 48 checks performed
✅ No checks skipped
✅ All violations documented with line numbers
