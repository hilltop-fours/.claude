# NTM Form Accessibility Pattern

## Overview

This document defines how to implement WCAG 3.3.1 compliant accessible forms in the NTM project. The pattern ensures forms are usable by all users including those using screen readers, keyboard navigation, and other assistive technologies.

**Story/Task Reference**: 108710 / 109367

---

## Core Components & Files

### Shared Components (Affects ALL forms)

**Error Display Component:**
- `ntm-frontend/src/app/shared/components/form-control-validation/form-control-validation.component.ts`
- `ntm-frontend/src/app/shared/components/form-control-validation/form-control-validation.component.html`
- `ntm-frontend/src/app/shared/components/form-control-validation/form-control-validation.component.scss`

**Form Validation Directive:**
- `ntm-frontend/src/app/shared/directives/form-validation.directive.ts`

**Global Form Styles:**
- `ntm-frontend/src/assets/styles/layout/_form.scss`

**Translations (Error Messages):**
- `ntm-frontend/src/i18n/nl.json`

---

## Implementation Requirements

### 1. Error Message Format (WCAG 3.3.1)

#### Requirement
Error messages must communicate THREE things:
1. **THAT** an error occurred (explicit error statement, not instruction)
2. **WHAT** is wrong (which field, what validation failed)
3. **WHERE** the error is (field location/context)

#### Pattern
```
✅ CORRECT: "Het verplichte veld voornaam is niet ingevuld."
❌ WRONG: "Vul alsjeblieft je voornaam in." (Instruction, not error)
```

#### Implementation
In `nl.json`, all error messages must follow explicit error format:
```json
{
  "FORMS": {
    "FIRSTNAME": {
      "ERRORS": {
        "REQUIRED": "Het verplichte veld voornaam is niet ingevuld."
      }
    },
    "EMAIL": {
      "ERRORS": {
        "REQUIRED": "Het verplichte veld e-mailadres is niet ingevuld.",
        "VALID": "Het veld e-mailadres is ongeldig."
      }
    }
  }
}
```

### 2. ARIA Live Regions (Screen Reader Announcements)

#### Component Template
Error containers must:
- **Always exist in DOM** (pre-existing, not dynamically created)
- Use `aria-live="polite"` for non-interrupting announcements
- NOT use `aria-atomic="true"` (allows independent error announcements)

```html
<!-- Container ALWAYS exists in DOM for screen reader "priming" -->
<div class="form-error-container"
     [id]="errorId()"
     aria-live="polite">
  @if (error()) {
    <div class="form-error">
      <span class="form-error__message" role="alert">
        <i class="bx bx-error-circle form-error__icon" aria-hidden="true"></i>
        {{ errorMessage() }}
      </span>
    </div>
  }
</div>
```

#### Why Pre-existing Containers?
Screen readers need the container to exist BEFORE content is added. Dynamic creation prevents proper announcement detection in some screen readers (especially VoiceOver).

#### Why Remove aria-atomic?
`aria-atomic="true"` causes screen readers to queue announcements. When multiple errors appear simultaneously, only the first one gets announced. Removing it allows each error to be announced independently.

### 3. aria-invalid & aria-describedby (Form Validation State)

#### Directive Implementation
Use `FormValidationDirective` to:
- Set `aria-invalid="true"` ONLY when control is invalid AND dirty (user has interacted)
- Set `aria-describedby` to link input to error message container

```typescript
@Directive({
  selector: '[ntmFormValidation]',
  standalone: true
})
export class FormValidationDirective implements OnInit, OnDestroy {
  @Input('ntmFormValidation') control!: AbstractControl;

  readonly #elementRef = inject(ElementRef);
  readonly #renderer = inject(Renderer2);
  readonly #destroy$ = new Subject<void>();

  ngOnInit() {
    const inputId = this.#elementRef.nativeElement.id;
    const errorId = `${inputId}-error`;

    // Link input to error message
    this.#renderer.setAttribute(inputElement, 'aria-describedby', errorId);

    // Monitor validity changes
    this.control.statusChanges
      .pipe(takeUntil(this.#destroy$))
      .subscribe(() => this.#updateAriaInvalid(inputElement));

    this.#updateAriaInvalid(inputElement);
  }

  #updateAriaInvalid(inputElement: HTMLElement) {
    const isInvalid = this.control.invalid && !this.control.pristine;
    if (isInvalid) {
      this.#renderer.setAttribute(inputElement, 'aria-invalid', 'true');
    } else {
      this.#renderer.removeAttribute(inputElement, 'aria-invalid');
    }
  }

  ngOnDestroy() {
    this.#destroy$.next();
    this.#destroy$.complete();
  }
}
```

#### HTML Usage
```html
<input
  type="text"
  class="form-control"
  id="firstName"
  formControlName="firstName"
  [ntmFormValidation]="form.get('user.firstName')!"
  aria-required="true"
/>
<ntm-form-control-validation
  [inputId]="'firstName'"
  [control]="form.get('user.firstName')"
  [errorMessages]="{ required: 'FORMS.FIRSTNAME.ERRORS.REQUIRED' | translate }"
/>
```

### 4. Required Field Indicators (Visual + Programmatic)

**1. Visual Indicator (Asterisk)**
```html
<label for="firstName" class="form-label">
  {{ 'FORMS.FIRSTNAME.LABEL' | translate }}
  <span class="required-indicator" aria-hidden="true">*</span>
</label>
```

**2. Programmatic Attribute**
```html
<input aria-required="true" />
```

#### Styling
```scss
.required-indicator {
  color: $accent-red;
  margin-left: 0.25rem;
  font-weight: bold;
  font-size: 1.1em;
}

```

### 5. Visual Differentiation (Non-Color Based)

#### WCAG Requirement
Invalid fields must have visual indicators BEYOND just red color (for colorblind users).

#### Implementation
```scss
input.ng-invalid:not(.ng-pristine),
textarea.ng-invalid:not(.ng-pristine),
select.ng-invalid:not(.ng-pristine) {
  // Color indicator
  border-color: $accent-red !important;
  border-width: 2px !important;
  border-style: solid !important;

  // Non-color indicator: Dashed outline
  outline: 2px dashed rgba($accent-red, 0.3);
  outline-offset: 1px;

  &:focus {
    box-shadow: 0 0 0 0.25rem rgba($accent-red, 0.25);
  }
}
```

#### Visual Indicators Provided
- ✅ Red border (color)
- ✅ Thicker border (2px instead of default)
- ✅ Dashed outline (non-color visual cue)
- ✅ Red error icon in message (visual + semantic)

### 6. Focus Management (Keyboard Users & Screen Readers)

#### Why Important
When form submission fails, focus should move to the first invalid field so:
- Keyboard users don't have to manually navigate
- Screen reader users have context for the error
- Visual users see which field needs attention

#### Implementation Pattern
Find first invalid field in **DOM order** (visual order on page), not FormGroup definition order:

```typescript
#focusFirstInvalidField(formGroup: FormGroup) {
  // Query inputs in DOM order (visual order)
  const inputs = this.#elementRef.nativeElement.querySelectorAll(
    'input[formControlName], textarea[formControlName], select[formControlName]'
  ) as HTMLElement[];

  // Find first invalid element in visual order
  const firstInvalidElement = Array.from(inputs).find((element) => {
    const controlName = element.getAttribute('formControlName');
    return controlName && formGroup.get(controlName)?.invalid;
  });

  if (firstInvalidElement) {
    // Use setTimeout to ensure DOM has been updated
    setTimeout(() => {
      firstInvalidElement.focus();
    }, 0);
  }
}
```

#### Critical: DOM Order vs FormGroup Order
- ❌ DON'T iterate `Object.keys(formGroup.controls)` - uses definition order
- ✅ DO use `querySelectorAll` - uses visual DOM order

**Example:**
```typescript
// FormGroup definition order (WRONG):
form = new FormGroup({
  email: new FormControl(...),     // 1st in definition
  firstName: new FormControl(...), // 3rd in definition
});

// DOM/Visual order (CORRECT):
// <input id="firstName" .../>  <!-- 1st on page -->
// <input id="email" .../>      <!-- 2nd on page -->
```

#### Component Integration
Call focus method on form submission failure:

```typescript
submit() {
  if (this.form.valid) {
    // Submit logic
  } else {
    FormUtils.triggerValidation(this.form);
    this.#focusFirstInvalidField(this.form); // <-- Add this
  }
}
```

---

## Error Message Component Implementation

### TypeScript
```typescript
@Component({
  selector: 'ntm-form-control-validation',
  // ...
})
export class FormControlValidationComponent implements AfterViewInit {
  readonly #translate = inject(TranslateService);

  control = input.required<FormControl | AbstractControl | null>();
  errorMessages = input<Record<string, string>>();
  inputId = input<string>(); // NEW: For aria-describedby linking

  combinedErrorMessages = computed(() => ({ ...this.#defaultErrorMessages, ...this.errorMessages() }));
  error = signal<FormControlError | undefined>(undefined);
  errorMessage = computed(() => this.combinedErrorMessages()[this.error()?.name ?? '']);

  // NEW: Generate unique error container ID based on input ID
  errorId = computed(() =>
    this.inputId() ? `${this.inputId()}-error` : `error-${crypto.randomUUID()}`
  );

  #defaultErrorMessages: Record<string, string> = {
    required: 'Het verplichte veld is niet ingevuld',
    emailIsInvalid: this.#translate.instant('FORMS.EMAIL.ERRORS.VALID'),
    urlIsInvalid: 'Het veld URL is ongeldig',
    postalCodeIsInvalid: 'Het veld postcode is ongeldig',
    emailsMismatch: 'De e-mailadressen komen niet overeen',
    unique: 'Het veld is niet uniek',
  };

  ngAfterViewInit() {
    this.control()
      ?.statusChanges.pipe(untilDestroyed(this))
      .subscribe(() => {
        this.error.set(undefined);

        const { errors, pristine } = this.control()!;
        if (errors !== null && !pristine) {
          const [validationError] = Object.keys(errors);
          this.error.set({
            name: validationError,
            data: errors[validationError],
          });
        }
      });
  }
}
```

### HTML
```html
<div class="form-error-container"
     [id]="errorId()"
     aria-live="polite">
  @if (error()) {
    <div class="form-error">
      <span class="form-error__message" role="alert">
        <i class="bx bx-error-circle form-error__icon" aria-hidden="true"></i>
        {{ errorMessage() }}
      </span>
    </div>
  }
</div>
```

### SCSS
```scss
@keyframes fxRollDownFormError {
  from {
    max-height: 0;
    opacity: 0;
  }
}

.form-error-container {
  min-height: 0;
}

.form-error {
  &__icon {
    color: $accent-red;
    font-size: 1rem;
    margin-right: 0.25rem;
    vertical-align: middle;
    flex-shrink: 0;
  }

  &__message {
    display: flex;
    align-items: flex-start;
    margin: 0.25rem 0 0 0;
    padding: 0;
    color: $accent-red;
    font-size: $font-size-text-xs;
    font-weight: $font-weight-medium;
    line-height: 1.2;
    text-align: left;
    max-height: 3rem;
    animation-delay: 0.1s;
    animation-duration: 0.6s;
    animation-fill-mode: backwards;
    animation-name: fxRollDownFormError;
    animation-timing-function: $ease-out-quad;
    opacity: 1;
  }
}
```

---

## Form Template Checklist

When creating a new form or updating an existing one, ensure:

### 1. Form Structure
- [ ] Form has proper `<form>` or `<section>` wrapper
- [ ] All form controls have `formControlName` attribute

### 2. Each Required Field
- [ ] Label with `for` attribute matching input `id`
- [ ] Asterisk (*) in label with `aria-hidden="true"`
- [ ] Input with `id` attribute (required for focus management)
- [ ] Input with `formControlName` attribute
- [ ] Input with `[ntmFormValidation]` directive
- [ ] Input with `aria-required="true"`
- [ ] `ntm-form-control-validation` component below input with `[inputId]`

### 3. Optional Fields
- [ ] Label with `for` attribute
- [ ] Input with `id` and `formControlName`
- [ ] Input with `[ntmFormValidation]` directive
- [ ] `ntm-form-control-validation` component (no aria-required)

### 4. Component Logic
- [ ] Call `FormUtils.triggerValidation()` on form submission failure
- [ ] Call `#focusFirstInvalidField()` after validation trigger
- [ ] Implement `#focusFirstInvalidField()` using DOM order logic

### 5. Styling
- [ ] Invalid inputs show red border + dashed outline
- [ ] Error messages display with red icon
- [ ] Required indicators are visible (red asterisk)
- [ ] Form info text explains required field marking

---

## Example: Contact Form

### Template
```html
<form [formGroup]="form">
  <!-- Required field -->
  <div class="mb-3">
    <label for="firstName" class="form-label">
      {{ 'FORMS.FIRSTNAME.LABEL' | translate }}
      <span class="required-indicator" aria-hidden="true">*</span>
    </label>
    <input
      type="text"
      class="form-control"
      id="firstName"
      formControlName="firstName"
      [ntmFormValidation]="form.get('firstName')!"
      aria-required="true"
    />
    <ntm-form-control-validation
      [inputId]="'firstName'"
      [control]="form.get('firstName')"
      [errorMessages]="{ required: 'FORMS.FIRSTNAME.ERRORS.REQUIRED' | translate }"
    />
  </div>

  <!-- Optional field -->
  <div class="mb-3">
    <label for="organization" class="form-label">
      {{ 'FORMS.COMPANY_NAME.LABEL' | translate }}
    </label>
    <input
      type="text"
      class="form-control"
      id="organization"
      formControlName="organization"
      [ntmFormValidation]="form.get('organization')!"
    />
    <ntm-form-control-validation
      [inputId]="'organization'"
      [control]="form.get('organization')"
    />
  </div>

  <button (click)="submit()">{{ 'SUBMIT' | translate }}</button>
</form>
```

### Component
```typescript
submit() {
  if (this.form.valid) {
    // Handle submission
  } else {
    FormUtils.triggerValidation(this.form);
    this.#focusFirstInvalidField();
  }
}

#focusFirstInvalidField() {
  const inputs = this.#elementRef.nativeElement.querySelectorAll(
    'input[formControlName], textarea[formControlName], select[formControlName]'
  ) as HTMLElement[];

  const firstInvalidElement = Array.from(inputs).find((element) => {
    const controlName = element.getAttribute('formControlName');
    return controlName && this.form.get(controlName)?.invalid;
  });

  if (firstInvalidElement) {
    setTimeout(() => {
      firstInvalidElement.focus();
    }, 0);
  }
}
```

---

## Testing Checklist

### Visual Testing
- [ ] Submit empty form
- [ ] Verify focus moves to first field on page (not FormGroup order)
- [ ] Verify red border appears on invalid inputs
- [ ] Verify dashed outline appears (non-color indicator)
- [ ] Verify required asterisks (*) are visible
- [ ] Verify error messages appear with red icon
- [ ] Verify form info text appears at top

### Keyboard Testing
- [ ] Tab through form fields
- [ ] Leave required field empty, tab away
- [ ] Verify error appears immediately
- [ ] Verify focus can be moved with Tab/Shift+Tab

### Screen Reader Testing (macOS VoiceOver)
- [ ] Open form with VoiceOver enabled
- [ ] Tab to required field
- [ ] Verify "required" is announced
- [ ] Leave field empty, tab away
- [ ] Verify error message is announced
- [ ] Verify field is announced as "invalid"
- [ ] Submit form with all fields empty
- [ ] Verify focus moves to first field
- [ ] Tab through remaining fields
- [ ] Verify each field's error is announced

### DevTools Testing
1. Open browser DevTools
2. Submit empty form
3. Inspect input element when invalid
   - [ ] `aria-invalid="true"` present
   - [ ] `aria-describedby="fieldId-error"` present
   - [ ] `aria-required="true"` present
4. Inspect error container
   - [ ] `aria-live="polite"` present
   - [ ] `id="fieldId-error"` matches aria-describedby
   - [ ] No `aria-atomic` attribute
   - [ ] Container exists in DOM on page load (pre-existing)

---

## Known Issues & Solutions

### Issue: Focus goes to wrong field
**Cause**: Using FormGroup definition order instead of DOM order
**Solution**: Always use `querySelectorAll` which respects DOM/visual order

### Issue: Errors not announced by screen reader
**Cause**: aria-live container created dynamically
**Solution**: Ensure container exists in DOM on page load (pre-existing)

### Issue: Only first error announced, others queued
**Cause**: Using `aria-atomic="true"`
**Solution**: Remove `aria-atomic` to allow independent announcements

### Issue: aria-invalid set before user interaction
**Cause**: Setting aria-invalid immediately on form init
**Solution**: Only set when control is both `invalid && !pristine`

---

## Related Documentation
- [WCAG 3.3.1 Error Identification](https://www.w3.org/WAI/WCAG21/Understanding/error-identification.html)
- [ARIA Live Regions](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Guides/Live_regions)
- [ARIA alert Role](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/alert_role)
- [Using aria-invalid](https://www.w3.org/WAI/WCAG21/Techniques/aria/ARIA21)
