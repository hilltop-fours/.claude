# chore(signals): #110904 migrate remaining inputs and outputs to signal variants (NTM)

**Story:** #110904
**Branch:** `chore/110904/migrate-remaining-inputs-outputs-to-signal-variants-ntm`
**Date:** 2026-03-04

---

## Story — Original Text

### Description

NTM [FE] overgebleven inputs en outputs migreren naar signal variants

### Acceptance Criteria

(Not provided in Azure DevOps — derived from IPQ2 research files IP-3 and IP-6)

### Discussion

None

---

## Task — Original Text

### Description

See story

### Discussion

None

---

## Analysis

This story modernizes the NTM frontend by replacing old Angular decorator patterns with signal-based equivalents. It combines the scope of two IPQ2 research stories:

- **IP-3** (`ip-3-ntm-organization-details-signals-smart-dumb.md`): Convert `OrganizationDetailsComponent` to `toSignal()` / `computed()`, remove `AfterViewInit` + `ChangeDetectorRef`, and fix the smart/dumb boundary violation in `ListCardOrganizationInfoComponent`.
- **IP-6** (`ip-6-ntm-onpush-immutability-signal-inputs.md`): Fix latent immutability bugs (`Array.splice()` in `UserRepository` and `OrganizationRepository`), convert `@Input()`/`@Output()` to `input()`/`output()` across IP-sprint-touched components, and add `ChangeDetectionStrategy.OnPush`.

### Why IP-3 must come before IP-6

OnPush is not safe to add to a component that still uses imperative change detection (`cdr.detectChanges()`) or manually subscribes and pushes into signals. IP-3 removes those patterns from `OrganizationDetailsComponent` first, making it safe to add OnPush in IP-6.

### What exists today (confirmed via codebase scan)

- **55 components** still use `@Input()` / `@Output()` decorator syntax
- **24 components** have both `@Input` and `@Output`
- **15 components** use `new EventEmitter()`
- **12 components** use `@ViewChild` / `@ViewChildren`
- **127 / 197 components** (64%) have no `ChangeDetectionStrategy` set (using default zone-based CD)
- `OrganizationDetailsComponent` uses `AfterViewInit`, `ChangeDetectorRef`, and 4 manual `.subscribe()` calls for loading stats
- `ListCardOrganizationInfoComponent` (in `shared/components/`) directly injects `OrganizationRepository`, `UserRepository`, and `AuthService` — a smart/dumb boundary violation
- `UserRepository` uses `Array.splice()` in `#updateUserInOrganizationUserList` and `#deleteUserFromOrganizationUserList`
- `OrganizationRepository` uses `Array.splice()` in `#deleteOrganizationFromOrganizationList`

### Key technical concepts for this story

**`input()` / `output()` signal API:**
```typescript
// Before
@Input() title: string = '';
@Input({ required: true }) id!: string;
@Output() selected = new EventEmitter<string>();

// After
title = input<string>('');
id = input.required<string>();
selected = output<string>();
```
- `input()` returns `Signal<T>` — read as `this.title()` inside class, `[title]="x"` in template (unchanged)
- `output()` returns `OutputEmitterRef` — call `.emit(value)` same as before, but NOT subscribable as Observable

**`toSignal()` for reactive data loading:**
```typescript
// Replaces: ngAfterViewInit subscribe → signal.set()
numberOfPublications = toSignal(
  toObservable(this.id).pipe(
    switchMap(id => this.#dataPublicationRepository.getAll({ organizationId: id })),
    filter(r => r.status === HttpStatus.SUCCESS),
    map(r => r.data?.page.totalElements ?? 0)
  ),
  { initialValue: 0 }
);
```

**Immutable array operations (required for OnPush):**
```typescript
// Before (mutates in place — dangerous under OnPush)
users.splice(index, 1, user);

// After (new reference — safe under OnPush)
// Using elf store update mechanism
store.update(setEntities([...state.users.map(u => u.id === user.id ? user : u)]));
```

### Scope decision

Holistic cleanup included — also fix missing `takeUntilDestroyed` in components touched by this story, and apply OnPush to all IP-sprint-touched components.

---

## Implementation Plan

### Phase 1: Fix immutability bugs in repositories

**Files:**
- `ntm-frontend/src/app/core/data-access/user/user.repository.ts`
  - Fix `#updateUserInOrganizationUserList` — replace `splice(index, 1, user)` with immutable `map()`
  - Fix `#deleteUserFromOrganizationUserList` — replace `splice(index, 1)` with immutable `filter()`
- `ntm-frontend/src/app/core/data-access/organizations/organization.repository.ts`
  - Fix `#deleteOrganizationFromOrganizationList` — replace `splice(index, 1)` with immutable `filter()`

Read each file to understand the elf store update mechanism before changing. Use `store.update(...)` with elf operators to set the new array so change notifications fire correctly.

**Verify:** `npm run build`. Manual test: edit a user in an org, delete a user — verify list updates correctly.

WIP commit after Phase 1.

### Phase 2: Convert OrganizationDetailsComponent to signals

**Files:**
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts`
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.html`

**Changes:**
- Remove `AfterViewInit` implementation and `ngAfterViewInit()` lifecycle hook
- Remove `ChangeDetectorRef` injection and all `this.#cdr.detectChanges()` calls
- Remove `DestroyRef` / `takeUntilDestroyed` (not needed after converting to `toSignal`)
- Convert `organization$` Observable to `organization = toSignal(...)` signal
- Convert 3 counter subscriptions to `toSignal()` derivations using `toObservable(this.id).pipe(switchMap(...))`
- Update template: replace `organization$ | async` with `organization()`, remove `AsyncPipe` from imports

**Watch out for:** `this.id()` is a route-derived signal input — use `toObservable(this.id) + switchMap` pattern so pipelines react to id changes, not just read id once at init.

**Verify:** Navigate to an org details page — all stats load correctly.

WIP commit after Phase 2.

### Phase 3: Fix ListCardOrganizationInfoComponent boundary (smart/dumb)

**Files:**
- `ntm-frontend/src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts`
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts` (parent)

**Changes to `ListCardOrganizationInfoComponent`:**
- Remove `OrganizationRepository`, `UserRepository`, `AuthService` injections
- Add `output<UpdateOrganizationRequest>()` (or equivalent type) to emit on form submit
- Change `submit()` to emit the output event instead of calling repositories

**Changes to `OrganizationDetailsComponent`:**
- Add `(organizationUpdated)="handleOrganizationUpdated($event)"` in template
- Add `handleOrganizationUpdated()` method that calls `organizationRepository.update()` and triggers user refresh

**Before changing:** Search all templates for usages of `ListCardOrganizationInfoComponent` — confirm `organization-details` is the only parent.

**Verify:** Inline org name edit still works end-to-end.

WIP commit after Phase 3.

### Phase 4: Convert @Input/@Output to input()/output() in IP-touched components

**Target components:**
- `ntm-frontend/src/app/app.component.ts`
- `ntm-frontend/src/app/shared/components/popup/popup.component.ts`
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts`
- `ntm-frontend/src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts`

**For each component:**
1. `@Input() property: Type = default` → `property = input<Type>(default)`
2. `@Input({ required: true }) property!: Type` → `property = input.required<Type>()`
3. `@Output() event = new EventEmitter<Type>()` → `event = output<Type>()`
4. Update all internal reads: `this.property` → `this.property()` (inside class only)
5. `import { input, output } from '@angular/core'` — remove `Input`, `Output`, `EventEmitter`

**Critical check before converting `@Output`:** Verify no external code subscribes to the EventEmitter as an Observable. If found, `output()` breaks that — needs different approach.

**Verify:** `npm run build` after each component.

WIP commit after Phase 4.

### Phase 5: Add ChangeDetectionStrategy.OnPush

**Target:** All 4 IP-touched components (same as Phase 4)

- Add `changeDetection: ChangeDetectionStrategy.OnPush` to each `@Component` decorator
- `PopupComponent`: verify OnPush not already present before adding
- If any component breaks: root cause is mutable state update, remaining manual CD call, or plain class property used for rendering

**Verify:** Full manual test after adding OnPush to all 4:
- AppComponent: welcome popup and do-more banner appear correctly
- PopupComponent: opens and closes with correct animation
- OrganizationDetailsComponent: all stats load, inline edit works
- ListCardOrganizationInfoComponent: org name edit works end-to-end

WIP commit after Phase 5.

### Phase 6: Holistic cleanup — takeUntilDestroyed survey

Scan the 4 touched components for remaining `.subscribe()` calls missing `takeUntilDestroyed()`. Fix any gaps.

**Verify:** `npm run build` — 0 errors.

WIP commit after Phase 6.

---

## Reference

- IPQ2 research: `ip-3-ntm-organization-details-signals-smart-dumb.md`, `ip-6-ntm-onpush-immutability-signal-inputs.md`
