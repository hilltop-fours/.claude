# HTML Template Validation Checklist

**Applies to:** `.html` files

**Total checks:** 16

This checklist consolidates ALL applicable validation rules from:
- angular-instructions.md
- code-simplicity.md
- angular-style.md
- sonarqube-rules.md

---

## Control Flow Syntax (2 checks)

- [ ] Uses @if/@for/@let not *ngIf/*ngFor → ✓/✗ with lines
- [ ] Signal access uses () → ✓/✗ with lines

## Template Simplicity (3 checks)

- [ ] Template logic is simple (no complex expressions) → ✓/✗ with lines
- [ ] Patterns match existing templates → ✓/✗
- [ ] No unnecessary defensive templates → ✓/✗

## Bindings and Events (3 checks)

- [ ] Uses [class]/[style] not ngClass/ngStyle → ✓/✗ with lines
- [ ] Event handlers describe action not event → ✓/✗ with lines
- [ ] No complex event handler expressions → ✓/✗

## Accessibility (2 checks)

- [ ] aria-required on fieldset not radio/checkbox (Web:S6811) → ✓/✗ with lines
- [ ] Form labels associated with controls (Web:S6853) → ✓/✗ with lines

---

## Verification

After completing all checks:

**Total checks completed:** ____/16

✅ All 16 checks performed
✅ No checks skipped
✅ All violations documented with line numbers
