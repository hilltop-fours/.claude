# chore(ip-sprint): IP-3 Convert OrganizationDetailsComponent to signals and fix component boundary violation

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-3-ntm-organization-details-signals-smart-dumb`
**Project:** NTM (`ntm-frontend`)
**Date:** 2026-03-02
**Difficulty:** Medium
**Estimated days:** 2

---

## Learning Objective

Learn three closely related concepts that work together:

1. **`toSignal()`** — converting an RxJS Observable into a signal. Understand the different options: `{ requireSync: true }` for observables that always emit synchronously, `{ initialValue: X }` for observables that may not emit immediately, and `{ injector }` for use outside injection context. Understand that `toSignal()` must be called in an injection context (constructor or field initializer).

2. **`computed()`** for derived state — replacing manual `.subscribe()` calls that set a signal's value from another signal's value. Understand when `computed()` is the right choice over `toSignal()` (when deriving from other signals, not from Observables).

3. **Smart/dumb component boundary** — understanding what "dumb component" means architecturally and what violations look like. A dumb (presentational) component should only accept `@Input()` data and emit `@Output()` events. It should never inject services, never directly mutate state, and never reach into repositories from other domains. This story fixes a real violation where a shared list card component directly injects two repositories and mutates state on form submit.

This story also builds the foundation for Story IP-6 (OnPush), because removing manual change detection from a component is a prerequisite for safely adding `ChangeDetectionStrategy.OnPush`.

---

## Learning Context

### How OrganizationDetailsComponent currently works

File: `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts`

The component implements `AfterViewInit` (similar to AppComponent from Story IP-1, but more complex). In `ngAfterViewInit()`:

1. It calls `this.#organizationRepository.find(this.id())` and assigns the result to `organization$`
2. It subscribes to `this.#dataPublicationRepository.getAll({ organizationId: this.id() })`, filters for SUCCESS status, and calls `this.numberOfPublications.set(response.data?.page.totalElements ?? 0)` in the subscribe callback
3. It subscribes to `this.#organizationRepository.listUsers(this.id())`, filters for SUCCESS, and calls `this.numberOfPublicists.set(...)`
4. It subscribes to `this.#organizationRepository.listUserJoinRequests(this.id())`, filters for SUCCESS, and calls `this.numberOfPublicistsJoinRequest.set(...)`
5. Calls `this.#cdr.detectChanges()` at the end

So even though `numberOfPublications`, `numberOfPublicists`, and `numberOfPublicistsJoinRequest` are already `signal<number>(0)`, they are being updated imperatively via manual `subscribe()` calls. This defeats the purpose of signals — they should be derived, not pushed.

The `organization$` property is an Observable that the template consumes with `async` pipe.

### The toSignal() conversion pattern

Instead of:
```typescript
// BEFORE — imperative
ngAfterViewInit() {
  this.#dataPublicationRepository
    .getAll({ organizationId: this.id() })
    .pipe(filter(r => r.status === HttpStatus.SUCCESS), takeUntilDestroyed(this.#destroyRef))
    .subscribe(response => {
      this.numberOfPublications.set(response.data?.page.totalElements ?? 0);
    });
}

numberOfPublications = signal<number>(0);
```

Use `toSignal()`:
```typescript
// AFTER — declarative
numberOfPublications = toSignal(
  this.#dataPublicationRepository.getAll({ organizationId: this.id() }).pipe(
    filter(r => r.status === HttpStatus.SUCCESS),
    map(r => r.data?.page.totalElements ?? 0)
  ),
  { initialValue: 0 }
);
```

The `takeUntilDestroyed()` becomes unnecessary because `toSignal()` automatically unsubscribes when the component is destroyed (it uses `DestroyRef` internally).

Note: `this.id()` is a signal input. When calling `toSignal()` in the constructor, `this.id()` is read once at initialization time. If `id` can change during the component's lifetime (e.g. route param changes), the Observable needs to be reactive to that change — use `switchMap` with a signal-derived trigger or convert the signal to an Observable with `toObservable()`:

```typescript
numberOfPublications = toSignal(
  toObservable(this.id).pipe(
    switchMap(id => this.#dataPublicationRepository.getAll({ organizationId: id })),
    filter(r => r.status === HttpStatus.SUCCESS),
    map(r => r.data?.page.totalElements ?? 0)
  ),
  { initialValue: 0 }
);
```

Understanding this `signal → Observable → signal` bridge pattern is a key part of this story's learning.

### The smart/dumb violation in ListCardOrganizationInfoComponent

File: `ntm-frontend/src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts`

This component is in `shared/components/` — meaning it is intended as a reusable presentational component. Yet it:

- Injects `OrganizationRepository` directly
- Injects `UserRepository` directly
- Injects `AuthService` directly
- In its `submit()` method (lines ~147-175):
  - Calls `this.#organizationRepository.update(this.organization.id, ...)`
  - On success, calls `this.#userRepository.fetchLoggedInUser()`
  - On success, calls `this.#userRepository.find(this.organization.id)`
  - Updates the organization's properties by reaching into the form value

This is a fundamental violation. A shared list card component should not know about `OrganizationRepository` or `UserRepository`. If it does, it cannot be reused in any context that doesn't have those exact repositories, and it becomes impossible to test in isolation.

### The correct pattern for dumb components

The component should:
- Accept the organization as `@Input() organization: IOrganization`
- Have a form for editing the organization's display name (or whatever fields it edits)
- On submit, emit an `@Output() organizationUpdated = new EventEmitter<UpdateOrganizationRequest>()` event with the new values
- The **parent smart component** (`OrganizationDetailsComponent`) receives this event and calls the appropriate repository methods

This way:
- `ListCardOrganizationInfoComponent` has zero service dependencies — pure presentation
- `OrganizationDetailsComponent` (the smart container) orchestrates the save + user refresh
- The shared component can be used in any context without side effects

### Why this pattern matters beyond this one component

NTM has multiple other list card components that may have similar violations. The pattern learned here — "dumb components emit, smart components act" — applies everywhere. Every time you find a shared component that injects a repository, it's a candidate for this refactor.

---

## Analysis

### Files to change

| File | Current issue | Fix |
|------|--------------|-----|
| `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts` | `AfterViewInit`, `ChangeDetectorRef`, 4 manual subscriptions, `organization$` Observable + async pipe | Remove lifecycle hook, convert to `toSignal()` and `toObservable()` pipeline |
| `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.html` | Uses `async` pipe for `organization$` | Update to use signal directly (no `async` pipe) |
| `ntm-frontend/src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts` | Injects `OrganizationRepository`, `UserRepository`, `AuthService`; mutates state in `submit()` | Remove repository injections; emit `organizationUpdated` output; move save logic to parent |
| `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts` (also parent) | Needs to handle `organizationUpdated` event | Add handler that calls `organizationRepository.update()` and triggers user refresh |

### Watch out for

- `this.id()` is a route-derived signal input — verify how it changes and whether the `toSignal` pipelines need `toObservable(this.id)` + `switchMap` to react to ID changes
- The `organization$` → template `async` pipe → `@if ((organization$ | async)?.data; as organization)` pattern: once converted to a signal, the template becomes `@if (organization()?.data; as organization)` — verify the template compiles
- The `ListCardOrganizationInfoComponent` may be used in other places besides `OrganizationDetailsComponent` — check all usages before changing its output API

### Acceptance criteria

- `OrganizationDetailsComponent` no longer implements `AfterViewInit`
- `ChangeDetectorRef` no longer injected in `OrganizationDetailsComponent`
- `organization$` replaced by `organization = toSignal(...)` (or `organization = computed(...)`)
- The 3 counter subscriptions (`numberOfPublications`, `numberOfPublicists`, `numberOfPublicistsJoinRequest`) replaced with `toSignal()` derivations — no `.subscribe()` calls remain for data loading
- `ListCardOrganizationInfoComponent.submit()` no longer calls any repository or service method directly
- `ListCardOrganizationInfoComponent` emits an output event on successful form submit
- `OrganizationDetailsComponent` handles the output event and performs the save + user refresh
- `AsyncPipe` removed from both components' imports
- Build passes, organization details page works, inline org edit still functions

---

## Implementation Plan

### Phase 1: Research the data flow

Before touching any code, trace the full data flow:
- How does `organization$` get its value? What does `OrganizationRepository.find()` return?
- How does `id()` signal behave — is it set once on init or can it change?
- What does the `organization-details.component.html` template look like — list all `async` pipe usages
- Find all template locations in `organization-details` that use `organization$`
- Find all usages of `ListCardOrganizationInfoComponent` in templates

No code changes in this phase.

### Phase 2: Convert OrganizationDetailsComponent

- Replace `ngAfterViewInit` with constructor-based `toSignal()` conversions
- Convert `organization$` to a `toSignal()` signal
- Convert the 3 counter subscriptions to `toSignal()` derivations
- Remove `AfterViewInit`, `ChangeDetectorRef`, and `DestroyRef` (if `takeUntilDestroyed` was being used — `toSignal` handles cleanup)
- Update the template: replace `organization$ | async` with `organization()` signal calls

WIP commit after Phase 2.

### Phase 3: Fix ListCardOrganizationInfoComponent boundary

- Remove `OrganizationRepository`, `UserRepository`, `AuthService` injections from `ListCardOrganizationInfoComponent`
- Add `@Output() organizationUpdated = output<UpdateOrganizationRequest>()` (or the appropriate type)
- Update `submit()` to emit the output instead of calling repositories
- Add handler in `OrganizationDetailsComponent` that receives the event, calls the repository, and handles user refresh
- Update the component's template and `inputs` accordingly

WIP commit after Phase 3.

### Phase 4: Cleanup and verify

- Remove `AsyncPipe` from both components' `imports` arrays
- Run `npm run build` from `ntm-frontend`
- Manually test: navigate to an organization details page, verify all stats show, verify inline org name edit still works end-to-end

WIP commit after Phase 4.
