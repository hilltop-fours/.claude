# HTML Template Validation Checklist

**Applies to:** `.html` files

**Total checks:** 10

This checklist consolidates ALL applicable validation rules from:
- coding.md
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

## Accessibility (7 checks)

- [ ] aria-required on fieldset not radio/checkbox (Web:S6811) → ✓/✗ with lines
- [ ] Form labels associated with controls via for/id or nesting (Web:S6853) → ✓/✗ with lines
- [ ] autocomplete uses valid HTML spec tokens (Web:S6840) → ✓/✗ with lines
- [ ] No `role="dialog"` on non-`<dialog>` elements (Web:S6819) — suppress + note follow-up if found → ✓/✗ with lines
- [ ] No `<div (click)="...">` without keyboard handler (Web:MouseEventWithoutKeyboard) — false positive on ndw/ntm design system components → ✓/✗ with lines
- [ ] `<li>` inside list container — false positive OK when using ng-template projection (Web:ItemTagNotWithinContainer) → ✓/✗ with lines
- [ ] alt text not literally "image"/"photo" (Web:S6851) — false positive OK when signal/variable name contains "image" → ✓/✗ with lines

---

## Verification

After completing all checks:

**Total checks completed:** ____/15

✅ All 15 checks performed
✅ No checks skipped
✅ All violations documented with line numbers
