# TypeScript Interface/Model/Type Validation Checklist

**Applies to:** `.interface.ts`, `.model.ts`, `.type.ts`, `.enum.ts`

**Total checks:** 12

This checklist consolidates ALL applicable validation rules from:
- coding.md
- sonarqube-rules.md

---

## TypeScript Typing (4 checks)

- [ ] No any type → ✓/✗ with lines
- [ ] Optional properties use `?` not `| undefined` (e.g. `name?: string` not `name: string | undefined`) → ✓/✗ with lines
- [ ] Proper interfaces/types defined → ✓/✗
- [ ] Naming conventions (PascalCase types, camelCase properties) → ✓/✗

## Type Simplicity (6 checks)

- [ ] Simple first (no complex types without justification) → ✓/✗
- [ ] Reused existing types (not duplicating) → ✓/✗
- [ ] Patterns match codebase vocabulary → ✓/✗
- [ ] Every type has one-sentence justification → ✓/✗
- [ ] No single-use types (unless at boundaries) → ✓/✗
- [ ] Type structure is clear and readable → ✓/✗

## SonarQube Rules (2 checks)

- [ ] No any type (S4202) → ✓/✗ with lines
- [ ] No unused imports (S1128) → ✓/✗

---

## Verification

After completing all checks:

**Total checks completed:** ____/12

✅ All 12 checks performed
✅ No checks skipped
✅ All violations documented with line numbers
