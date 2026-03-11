# chore(ip-sprint): IP-10 Next wave of Angular modernisation — takeUntilDestroyed, linkedSignal, @defer, NgOptimizedImage, model(), httpResource, signal forms

**Sprint:** IP Q2 2026
**Branch:** (per sub-task, see below)
**Project:** All (NTM, GRG, BER)
**Date:** 2026-03-11
**Difficulty:** Low–Medium per item
**Estimated days:** 3–5 total across all items

---

## Overview

This document collects the next wave of Angular modernisation opportunities identified after completing:
- IP-1 through IP-9 (signal inputs, OnPush, BehaviorSubject → signal, decorator migration, ngClass cleanup)
- Angular upgrade to v21 (NTM, BER, GRG)

Each section below is a self-contained modernisation topic. They are ordered from most impactful / most ready to least ready. Each can be its own story/task, or grouped by project.

---

## 1. `@UntilDestroy` + `untilDestroyed(this)` → `takeUntilDestroyed` (stable, v16+)

### What it is

`@ngneat/until-destroy` is a third-party library that was the de-facto solution before Angular had a native destroy hook API. Angular v16 introduced `takeUntilDestroyed()` from `@angular/core/rxjs-interop` and `DestroyRef` from `@angular/core` — a first-party, zero-dependency replacement.

### Why migrate

- Removes the `@ngneat/until-destroy` third-party dependency entirely
- No class decorator (`@UntilDestroy()`) needed — decorators on classes are legacy Angular style
- `DestroyRef` fires at the correct point in the Angular destruction lifecycle
- `takeUntilDestroyed()` without arguments works inside injection context (constructor, field initializer) — even simpler
- Explicit `destroyRef` argument needed only when called from lifecycle methods or callbacks outside injection context

### Pattern

```typescript
// BEFORE
import { UntilDestroy, untilDestroyed } from '@ngneat/until-destroy';

@UntilDestroy()
export class MyComponent implements OnInit {
  ngOnInit() {
    someObservable$.pipe(untilDestroyed(this)).subscribe(...);
  }
}

// AFTER — called from injection context (constructor / field init)
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

export class MyComponent {
  constructor() {
    someObservable$.pipe(takeUntilDestroyed()).subscribe(...);
  }
}

// AFTER — called from lifecycle method (needs explicit destroyRef)
import { DestroyRef, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

export class MyComponent implements OnInit {
  readonly #destroyRef = inject(DestroyRef);

  ngOnInit() {
    someObservable$.pipe(takeUntilDestroyed(this.#destroyRef)).subscribe(...);
  }
}
```

### Notes

- After migrating all usages, `@ngneat/until-destroy` can be removed from `package.json` — fewer deps, smaller bundle
- Services that use `untilDestroyed(this)` also qualify — `DestroyRef` works in services too
- Guards that use `untilDestroyed(this)` — same approach

---

## 2. `linkedSignal` — writable derived state (stable, v20+)

### What it is

`linkedSignal` is a `WritableSignal` whose value is automatically reset by a reactive computation whenever its source signal changes. It fills the gap between `computed()` (read-only derived value) and `signal()` (fully independent writable value).

### Why it exists

A common pattern: you have a list signal and a "selected item" signal. When the list changes (e.g. filter applied), the selected item should reset. With plain signals this requires an `effect()`:

```typescript
// OLD — effect to sync dependent state
items = signal<Item[]>([]);
selectedItem = signal<Item | null>(null);

constructor() {
  effect(() => {
    this.items(); // track
    this.selectedItem.set(null); // reset on every list change
  });
}
```

This is brittle — `effect()` runs asynchronously and can cause timing issues. `linkedSignal` makes this declarative:

```typescript
// MODERN
items = signal<Item[]>([]);
selectedItem = linkedSignal(() => this.items()[0] ?? null); // resets when items changes, but can also be set manually
```

### Pattern

```typescript
import { linkedSignal } from '@angular/core';

// Simple form: computation resets the value when dependencies change
selectedIndex = linkedSignal(() => 0); // resets to 0 when any dependency changes

// Advanced form: access previous value to preserve partial state
selectedItem = linkedSignal({
  source: this.items,
  computation: (newItems, previous) => {
    // Try to keep the previously selected item if it still exists in the new list
    return newItems.find(i => i.id === previous?.value?.id) ?? newItems[0] ?? null;
  }
});
```

### When to use

- Dropdown selection that should reset when the list of options changes
- Pagination page number that resets when filters change
- Form step that resets when the parent data changes
- Any `effect(() => someSignal.set(...))` pattern — that's a code smell for `linkedSignal`

---

## 3. `@defer` blocks — lazy rendering (stable, v17+)

### What it is

`@defer` is a template block that defers the loading and rendering of part of a template until a trigger condition is met. The deferred content is code-split automatically — Angular only loads the JS for that component when it's needed.

### Why it matters

Heavy components (rich text editors, maps, charts, complex tables) loaded eagerly at startup increase initial bundle size and slow down LCP. With `@defer`, they only load when the user scrolls them into view, clicks a tab, or triggers another condition.

### Pattern

```html
<!-- Defer until visible in viewport (most common) -->
@defer (on viewport) {
  <ntm-map [publication]="publication()" />
} @placeholder {
  <div class="map-placeholder skeleton"></div>
} @loading (minimum 300ms) {
  <ntm-skeleton-map />
} @error {
  <p>Map could not be loaded.</p>
}

<!-- Defer until user interaction -->
@defer (on interaction) {
  <ntm-quill-editor [formControl]="descriptionControl" />
}

<!-- Defer until idle (browser has spare time) -->
@defer (on idle) {
  <ntm-standards-graph [standardId]="standardId()" />
}
```

### Candidates in the codebase

- **Map component** (`administrative-division-visual`) — heavy maplibre-gl, loaded eagerly on publication detail
- **Quill editor** (`ngx-quill`) — rich text editor, only needed on edit pages
- **Sigma graph** (`standards-details-graph`) — graphology + sigma, heavy, only on standards detail
- Any tab panel content that is not the default visible tab

### Notes

- `@placeholder` renders synchronously (before the deferred block loads) — use a skeleton or simple div
- `@loading` renders while the deferred chunk is being downloaded
- The deferred component's imports do NOT need to be in the parent component's `imports` array — they are automatically tree-shaken into their own lazy chunk

---

## 4. `NgOptimizedImage` — image optimisation directive (stable, v15+)

### What it is

`NgOptimizedImage` is Angular's built-in image directive that replaces `<img src="...">` with `<img ngSrc="...">`. It automatically:
- Adds `loading="lazy"` for below-the-fold images
- Adds `fetchpriority="high"` for LCP images (`priority` attribute)
- Enforces explicit `width` and `height` to prevent layout shift (CLS)
- Warns at runtime if an oversized image is loaded
- Supports image CDN loaders (imgix, Cloudinary, etc.) for automatic `srcset` generation

### Pattern

```typescript
// In component imports
import { NgOptimizedImage } from '@angular/common';

@Component({
  imports: [NgOptimizedImage],
  ...
})
```

```html
<!-- BEFORE -->
<img src="/assets/images/logo.png" alt="Logo" />

<!-- AFTER -->
<img ngSrc="/assets/images/logo.png" alt="Logo" width="120" height="40" />

<!-- For above-the-fold / LCP images, add priority -->
<img ngSrc="/assets/images/hero.png" alt="Hero" width="800" height="400" priority />
```

### Notes

- Works only for static images (not inline base64)
- `width` and `height` are required — they set the intrinsic dimensions, not the rendered size (CSS controls that)
- Not applicable for dynamically sized images where dimensions are unknown — use regular `<img>` for those
- First step: scan for `<img src=` in templates and identify which are static assets

---

## 5. `model()` — two-way signal binding (stable, v17.2+)

### What it is

`model()` is a signal input that also emits an output when changed — the signal equivalent of the `[(ngModel)]` / `@Input() value` + `@Output() valueChange` pattern used for custom two-way binding.

### Why migrate

The old pattern requires two declarations, a manual `.emit()` call, and the consumer uses `[(value)]` or `[value]="x" (valueChange)="x = $event"`. `model()` collapses this to a single declaration.

### Pattern

```typescript
// BEFORE — manual two-way binding pair
@Component({ ... })
export class ToggleComponent {
  @Input() checked = false;
  @Output() checkedChange = new EventEmitter<boolean>();

  toggle() {
    this.checked = !this.checked;
    this.checkedChange.emit(this.checked);
  }
}

// AFTER — model() signal
@Component({ ... })
export class ToggleComponent {
  checked = model(false); // WritableSignal + auto-emits on .set()/.update()

  toggle() {
    this.checked.update(v => !v); // automatically emits checkedChange
  }
}
```

```html
<!-- Consumer — identical syntax, but now fully reactive -->
<ntm-toggle [(checked)]="isActive" />
```

### When to use

- Custom form controls that expose a two-way bindable value
- Toggle, switch, checkbox-like components
- Any component that has a matching `@Input() foo` + `@Output() fooChange` pair

### Notes

- `model()` returns a `WritableSignal` — read it with `this.checked()`, write with `this.checked.set(val)`
- `model.required()` exists for required two-way bindings
- The emitted output name is automatically `${inputName}Change` — no manual `EventEmitter` needed

---

## 6. `httpResource` — reactive HTTP fetching (experimental, v21+)

### What it is

`httpResource` is a reactive wrapper around `HttpClient` that exposes request state and response as signals. It is the Angular-native alternative to manually managing loading/error/data state in a repository with `BehaviorSubject` + `switchMap` + `catchError`.

### Status

**Experimental** as of v21 — the API may change before stabilisation. Not recommended for production use until stable. Worth tracking and piloting in a low-risk area.

### Pattern

```typescript
import { httpResource } from '@angular/core';

export class PublicationDetailComponent {
  publicationId = input.required<string>();

  // Reactive: re-fetches automatically when publicationId() changes
  publication = httpResource(() => `/api/publications/${this.publicationId()}`);
}
```

```html
@if (publication.hasValue()) {
  <ntm-publication-detail [publication]="publication.value()" />
} @else if (publication.isLoading()) {
  <ntm-skeleton-detail />
} @else if (publication.error()) {
  <ntm-error-state />
}
```

### What this replaces

In the current architecture, each repository manually implements:
1. A loading signal/BehaviorSubject
2. An error signal/BehaviorSubject
3. A data signal/BehaviorSubject
4. A `switchMap` or `combineLatest` pipeline to fetch on ID change
5. `catchError` to populate the error state

`httpResource` replaces all five with one declaration.

### Notes

- Avoid for mutations (POST, PUT, DELETE) — use `HttpClient` directly for those, per Angular docs
- Supports response type variants: `httpResource.text()`, `httpResource.blob()`, `httpResource.arrayBuffer()`
- Supports a `parse` option for schema validation (e.g. Zod)
- Built on `HttpClient` — all interceptors work automatically
- **Do not adopt in production until marked stable** — wait for v22 or an official stable announcement

---

## 7. Signal-based forms (experimental, v21+)

### What it is

Angular is building a signal-native forms API as an alternative to the current `ReactiveFormsModule` (`FormControl`, `FormGroup`, `FormArray`). Signal forms expose form values and validation state as signals instead of Observables, enabling direct use with `computed()`, `effect()`, and template signal reads.

### Status

**Experimental / in development** as of v21. The API is not yet finalised. Do not adopt in production.

### What it will look like (based on current RFCs and experimental API)

```typescript
import { FormBuilder } from '@angular/forms'; // signal-aware builder (future API)

export class PublicationEditComponent {
  readonly #fb = inject(FormBuilder);

  form = this.#fb.group({
    title: this.#fb.control(''),
    description: this.#fb.control(''),
  });

  // Read value as signal — no .valueChanges.subscribe() needed
  titleValue = this.form.controls.title.value; // signal<string>
  isValid = this.form.valid; // signal<boolean>

  // Derived state with computed()
  submitLabel = computed(() => this.form.valid() ? 'Opslaan' : 'Vul alle velden in');
}
```

### Why it matters

The current `ReactiveFormsModule` API is Observable-based — to react to value changes you subscribe to `.valueChanges`, which requires `untilDestroyed` / `takeUntilDestroyed` and manual subscription management. Signal forms eliminate this entirely.

### Notes

- This is a **future item** — monitor Angular blog and changelogs for stable release
- When stable, will be a significant quality-of-life improvement for all form-heavy components (publications edit, standards edit, user management)
- The existing `ReactiveFormsModule` will not be deprecated — signal forms are an additive API

---

## Branch naming (when implementing)

| Item | Suggested branch |
|---|---|
| takeUntilDestroyed — NTM | `chore/ip-sprint/ip-10-ntm-take-until-destroyed` |
| takeUntilDestroyed — GRG | `chore/ip-sprint/ip-10-grg-take-until-destroyed` |
| takeUntilDestroyed — BER | `chore/ip-sprint/ip-10-ber-take-until-destroyed` |
| @defer — NTM | `chore/ip-sprint/ip-10-ntm-defer-heavy-components` |
| linkedSignal — NTM | `chore/ip-sprint/ip-10-ntm-linked-signal` |
| NgOptimizedImage | `chore/ip-sprint/ip-10-ntm-ng-optimized-image` |
| model() | `chore/ip-sprint/ip-10-ntm-model-signal` |
