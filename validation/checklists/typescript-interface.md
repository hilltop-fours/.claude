# TypeScript Interface/Model/Type Validation Checklist

**Applies to:** `.interface.ts`, `.model.ts`, `.type.ts`, `.enum.ts`

**Total checks:** 11

This checklist consolidates ALL applicable validation rules from:
- angular-instructions.md
- code-simplicity.md
- sonarqube-rules.md

---

## TypeScript Typing (3 checks)

- [ ] No any type → ✓/✗ with lines
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

**Total checks completed:** ____/11

✅ All 11 checks performed
✅ No checks skipped
✅ All violations documented with line numbers
