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

- **IP-3** (`ip-3-ntm-organization-details-signals-smart-dumb.md`): Convert `OrganizationDetailsComponent` to `toSignal()`, remove `AfterViewInit` + `ChangeDetectorRef`, and fix the smart/dumb boundary violation in `ListCardOrganizationInfoComponent`.
- **IP-6** (`ip-6-ntm-onpush-immutability-signal-inputs.md`): Fix latent immutability bugs (`Array.splice()` in repositories), convert `@Input()`/`@Output()` to `input()`/`output()`, and add `ChangeDetectionStrategy.OnPush`.

### Why IP-3 must come before IP-6

`OrganizationDetailsComponent` still uses `AfterViewInit` + `cdr.detectChanges()`. OnPush cannot be safely added until those imperative patterns are replaced with signals.

### What exists today (confirmed via full codebase scan)

**Old Input/Output patterns:**
- **55 components** still use `@Input()` / `@Output()` decorator syntax
- **15 components** use `new EventEmitter()`
- **13 components** use `@ViewChild` / `@ViewChildren` / `@ContentChildren`
- **127 / 197 components** (64%) have no `ChangeDetectionStrategy.OnPush`

**Confirmed bugs in repositories (`splice` / `push` — all in-place mutations):**

`ntm-frontend/src/app/core/data-access/user/user.repository.ts`:
- `#updateUserInOrganizationUserList` — `splice(index, 1, user)` (replaces user in-place)
- `#updateUserInHeadEditorsList` — `splice(index, 1)` + `push(user)` (adds/removes head editors in-place)
- `#deleteUserFromOrganizationUserList` — `splice(index, 1)` (deletes user in-place)
- `#deleteUserFromUserList` — `splice(index, 1)` (deletes user in-place)

`ntm-frontend/src/app/core/data-access/organizations/organization.repository.ts`:
- `#deleteOrganizationFromOrganizationList` — `splice(index, 1)` (deletes org in-place)

**The store mechanism (confirmed by reading `base-repository.ts`):**
`BaseRepository.updateStoreData<T>(key, data)` calls `this.store.update(state => ({ ...state, [key]: { status: HttpStatus.SUCCESS, data } }))`. This is the correct way to set a new array reference in the elf store.

**Confirmed state of target components:**

`OrganizationDetailsComponent`:
- Implements `AfterViewInit` — all data loading happens in `ngAfterViewInit()`
- Injects `ChangeDetectorRef`, calls `this.#cdr.detectChanges()` at end of `ngAfterViewInit()`
- Has 4 manual `.subscribe()` calls (all wrapped in `takeUntilDestroyed`)
- `organization$` is an `Observable<HttpState<IOrganization>>`, consumed in template with `async` pipe
- `id` is already `input<string>('')` (signal input — already migrated!)
- `numberOfPublications`, `numberOfPublicists`, `numberOfPublicistsJoinRequest` are `signal<number>(0)` but set imperatively in subscribe callbacks
- No `ChangeDetectionStrategy` set (uses Default)

`ListCardOrganizationInfoComponent`:
- Has `@Input() organization: IOrganization` (old-style decorator)
- Injects `OrganizationRepository`, `UserRepository`, `AuthService` — all three are boundary violations for a shared/ component
- `submit()` directly calls `this.#organizationRepository.update()` and `this.#userRepository.fetchLoggedInUser()`
- Has `ChangeDetectionStrategy.OnPush` already ✓
- Has `cdr.detectChanges()` call in `openDrawer()` — must be removed before OnPush is relied on
- `drawerVisible: boolean` is a plain property (not a signal) — needs to become `signal`

`AppComponent`:
- No `@Input`/`@Output` — nothing to migrate there
- Uses `showDoMoreBanner: boolean` as a plain property + `cdr.detectChanges()` + `setTimeout`
- Has `viewChild(ToastContainerDirective)` (already uses new signal `viewChild` API ✓)
- No `ChangeDetectionStrategy` set
- Pattern to fix: `setTimeout` + plain property + `cdr.detectChanges()` → `signal<boolean>` + `afterNextRender()`

`PopupComponent`:
- Has `ChangeDetectionStrategy.OnPush` already ✓
- Has `@Input()` for title/description/labels/visible/fullscreen → migrate to `input()`
- Has `@Output() closeEmitter` and `@Output() visibleChange` → migrate to `output()`
- Has `@ViewChild('popup')` → leave as-is (DOM access needed for click-outside detection)
- Uses `cdr.detectChanges()` in several places + `setTimeout` for CSS transitions
- The `setTimeout` + `cdr.detectChanges()` pattern for the CSS `is-visible/is-hidden` class toggle is a known pattern; converting `visibleClass` to a `signal` removes the need for `cdr.detectChanges()` entirely
- `ngOnChanges` watches `visible` input changes — once `visible = input<boolean>(false)` is a signal, use `effect()` instead of `ngOnChanges`

`NotificationsRepository` (inconsistency found):
- Exposes BOTH `notificationCount$: Observable<number>` AND `notificationCountSignal: Signal<number>` — violates the repo purity rule
- `notificationCountSignal` is used by `navigation.component.ts`
- `notificationCount$` is used by `admin-dashboard.component.ts` with `| async`
- Fix: remove `notificationCountSignal` from repo, let `navigation` do `toSignal()` itself

### Signal philosophy for this project (agreed convention)

**Repositories = pure Observables. No `toSignal()` ever in repo files.**
- If a `toSignal` is found in a repo file → add `// TODO: verify before removing` comment and leave it for now
- Repo files expose `Observable` streams from the elf store — that's their only job

**Components consuming observables = keep `| async` as-is.**
- Don't convert a working `observable$ | async` to a signal just for the sake of it
- Only convert if there's a concrete reason (see below)

**`toSignal()` in components = only when it genuinely helps.**
- Main use case: component has a signal `input()` and needs to react to it with an Observable chain:
  ```typescript
  organization = toSignal(
    toObservable(this.id).pipe(switchMap((id) => this.#repo.find(id)))
  );
  ```
- `toSignal()` auto-cleans up when the injection context (component) is destroyed — no `takeUntilDestroyed` needed
- `toSignal()` runs in injection context → must be a class field initializer, not inside a lifecycle hook

**New component API (`@Input`/`@Output`) = always use `input()`/`output()`.**
- `input()` and `output()` are the modern Angular API — use them for all new and migrated component boundaries

**`computed()` = use for derived values from signals.**
- Avoids recalculating on every change detection cycle
- Memoized — only recalculates when its signal dependencies change

**`effect()` = use for side effects triggered by signal changes.**
- Replaces `ngOnChanges` when watching an `input()` signal for changes

**`computed()` vs `toSignal()` — when to use which:**
- `toSignal(observable$)` — bridges RxJS into the signal world. Use when data source is an Observable.
- `computed(() => expr)` — derives a value purely from other signals, no RxJS.

Example — `canEdit()` in `OrganizationDetailsComponent`:
```typescript
// BEFORE: recalculates on every change detection cycle
canEdit(): boolean {
  return this.#authService.hasPermissionToEditOrganization(this.id());
}

// AFTER: memoized, recalculates only when id() changes
canEdit = computed(() => this.#authService.hasPermissionToEditOrganization(this.id()));
```

**Note on `updateStoreData` being `protected`:**
Cross-repository updates (like `UserRepository` updating `OrganizationRepository`'s arrays) need a dedicated public method on the target repository.

**Memory leak found (out of scope, noted for follow-up):**
`publication-edit-form-scope.component.ts` — `combineLatest([...]).subscribe(...)` with no `takeUntilDestroyed`.

### Scope decision

Per user confirmation: holistic cleanup included — fix missing `takeUntilDestroyed` in components touched, apply OnPush to IP-sprint-touched components.

---

## Implementation Plan

### Execution rule: stop after every phase

After each phase: run `npm run build`, present what was changed as a checklist, then stop and wait for user approval before moving to the next phase.

---

### Phase 1: Fix immutability bugs in repositories

**Files:**
- `ntm-frontend/src/app/core/data-access/organizations/organization.repository.ts`
- `ntm-frontend/src/app/core/data-access/user/user.repository.ts`

**Problem:** `splice()` and `push()` mutate arrays in-place on the store — OnPush components won't detect the change because the array reference doesn't change.

**Fix in `organization.repository.ts`:**

Add two public methods (since `updateStoreData` is `protected`, `UserRepository` can't call it directly on another repo instance):
```typescript
updateUsers(users: IUser[]): void {
  this.updateStoreData<OrganizationProps>('users', users);
}
updateHeadEditors(headEditors: IUser[]): void {
  this.updateStoreData<OrganizationProps>('headEditors', headEditors);
}
```

Fix `#deleteOrganizationFromOrganizationList`:
```typescript
// BEFORE: this.organizations?.splice(index, 1)
const updated = (this.organizations ?? []).filter((o) => o.id !== id);
this.updateStoreData<OrganizationProps>('organizations', updated);
```

**Fix in `user.repository.ts`** (4 methods):

`#updateUserInOrganizationUserList`:
```typescript
// BEFORE: this.#organizationRepository.users?.splice(userIndex, 1, user)
const updated = (this.#organizationRepository.users ?? []).map((u) => (u.id === user.id ? user : u));
this.#organizationRepository.updateUsers(updated);
```

`#updateUserInHeadEditorsList`:
```typescript
// BEFORE: splice + push
const current = this.#organizationRepository.headEditors ?? [];
let updated: IUser[];
if (userIndex !== -1 && user.role !== RoleEnum.HEAD_EDITOR) {
  updated = current.filter((u) => u.id !== user.id);
} else if (userIndex === -1 && user.role === RoleEnum.HEAD_EDITOR) {
  updated = [...current, user];
} else {
  return;
}
this.#organizationRepository.updateHeadEditors(updated);
```

`#deleteUserFromOrganizationUserList`:
```typescript
// BEFORE: this.#organizationRepository.users?.splice(userIndex, 1)
const updated = (this.#organizationRepository.users ?? []).filter((u) => u.id !== id);
this.#organizationRepository.updateUsers(updated);
```

`#deleteUserFromUserList`:
```typescript
// BEFORE: this.users?.splice(userIndex, 1)
const updated = (this.users ?? []).filter((u) => u.id !== id);
this.updateStoreData<UserProps>('users', updated);
```

**Verify:** `npm run build`. No TS errors. Manual test: edit/delete user in org, delete org — verify lists update correctly.

---

### Phase 2: OrganizationDetailsComponent → remove AfterViewInit + cdr, use toSignal

**Files:**
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts`
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.html`

**Why `toSignal` is appropriate here:** `id` is a signal input. To react to it with an Observable chain we need `toObservable(this.id).pipe(switchMap(...))`. Wrapping with `toSignal()` gives a clean signal in the template — no async pipe, no manual subscribe, auto-cleanup.

**Changes to .ts:**
- Remove `AfterViewInit` implementation and `ngAfterViewInit()` lifecycle hook
- Remove `ChangeDetectorRef` injection
- Remove `DestroyRef` injection (toSignal handles cleanup)
- Remove `organization$: Observable<HttpState<IOrganization>>` field
- Remove `AsyncPipe` from imports
- Convert all 4 data loads to `toSignal()` class field initializers:

```typescript
organization = toSignal(
  toObservable(this.id).pipe(switchMap((id) => this.#organizationRepository.find(id)))
);

numberOfPublications = toSignal(
  toObservable(this.id).pipe(
    switchMap((id) => this.#dataPublicationRepository.getAll({ organizationId: id })),
    filter((r) => r.status === HttpStatus.SUCCESS),
    map((r) => r.data?.page.totalElements ?? 0)
  ),
  { initialValue: 0 }
);

numberOfPublicists = toSignal(
  toObservable(this.id).pipe(
    switchMap((id) => this.#organizationRepository.listUsers(id)),
    filter((r) => r.success),
    map((r) => r.data?.length ?? 0)
  ),
  { initialValue: 0 }
);

numberOfPublicistsJoinRequest = toSignal(
  toObservable(this.id).pipe(
    switchMap((id) => this.#organizationRepository.listUserJoinRequests(id)),
    filter((r) => r.status === HttpStatus.SUCCESS),
    map((r) => r.data?.length ?? 0)
  ),
  { initialValue: 0 }
);
```

- Convert `canEdit()` method → `computed()`:
```typescript
canEdit = computed(() => this.#authService.hasPermissionToEditOrganization(this.id()));
```

**Changes to .html:**
- Replace `@if ((organization$ | async)?.data; as organization)` with `@if (organization()?.data; as organization)`

**Imports needed:** `toSignal`, `toObservable` from `@angular/core/rxjs-interop`; `switchMap`, `map`, `filter` from `rxjs`; `computed` from `@angular/core`

**Verify:** Navigate to org details — org name visible, all 3 counters load.

---

### Phase 3: Fix ListCardOrganizationInfoComponent smart/dumb boundary

**Files:**
- `ntm-frontend/src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts`
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts` (parent)
- `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.html` (parent template)

**Problem:** A `shared/` component directly injects `OrganizationRepository`, `UserRepository`, `AuthService` — breaking the smart/dumb boundary.

**Changes to shared component:**
- Remove `OrganizationRepository`, `UserRepository`, `AuthService` injections
- Add `organizationUpdate = output<IOrganization>()` — emit payload up, parent handles HTTP
- Add `canEdit = input<boolean>(false)` — parent passes it down (removes need for `AuthService`)
- `submit()` becomes: validate form → emit `organizationUpdate` → `closeDrawer()`
- Convert `drawerVisible: boolean` → `drawerVisible = signal(false)`; `openDrawer()` calls `.set(true)`, template reads `drawerVisible()`
- Remove `ChangeDetectorRef` (no longer needed with signal)
- Remove `UntilDestroy` / `untilDestroyed` if no subscriptions remain

```typescript
// submit() after change
submit() {
  FormUtils.triggerValidation(this.form);
  if (!this.form.valid) return;

  const updateOrganization = { ...this.organization(), ...this.form.value } as IOrganization;
  if (!updateOrganization.poBox?.hasPoBox) delete updateOrganization.poBox;

  this.organizationUpdate.emit(updateOrganization);
  this.closeDrawer();
}
```

**Changes to parent (`OrganizationDetailsComponent`):**
- Add `handleOrganizationUpdate(org: IOrganization)` method:
```typescript
handleOrganizationUpdate(organization: IOrganization) {
  this.#organizationRepository
    .update(organization)
    .pipe(
      filter((r) => r.success),
      take(1),
      takeUntilDestroyed(this.#destroyRef)
    )
    .subscribe(() => {
      this.#userRepository.fetchLoggedInUser();
      if (this.#userRepository.findUser) {
        this.#userRepository.find(this.#userRepository.findUser.id);
      }
    });
}
```
- Re-add `DestroyRef` injection (for `takeUntilDestroyed`)
- Template: bind `(organizationUpdate)="handleOrganizationUpdate($event)"` and `[canEdit]="canEdit()"`

**Verify:** Edit org name end-to-end — drawer opens, save works, new name appears, no console errors.

---

### Phase 4: PopupComponent → input()/output() + signal for local state

**File:** `ntm-frontend/src/app/shared/components/popup/popup.component.ts`

**Changes:**
- All `@Input()` → `input()` signals: `title`, `description`, `confirmLabel`, `cancelLabel`, `closeLabel`, `visible`, `fullscreen`
- Both `@Output()` → `output()`: `closeEmitter`, `visibleChange`
- `visibleClass` plain string → `visibleClass = signal<'is-visible' | 'is-hidden'>('is-hidden')`
- Replace `ngOnChanges` watching `visible` with `effect()` in constructor:
  ```typescript
  constructor() {
    effect(() => {
      if (this.visible()) {
        this.openPopup();
      } else {
        this.closePopup();
      }
    });
  }
  ```
  Guard in `closePopup()`: check `if (this.visibleClass() !== 'is-hidden')` before animating — `effect()` fires once on init with `visible = false`, avoid running close animation on construction.
- Remove `ChangeDetectorRef` injection + all `cdr.detectChanges()` calls (`visibleClass` is now a signal)
- Remove `OnChanges` implementation + `ngOnChanges()`
- Keep `@ViewChild('popup')` — needed for click-outside DOM subscription
- Internal reads of `this.title`, `this.visible`, etc. → `this.title()`, `this.visible()`, etc.

**Verify:** Open a popup — it opens/closes with animation. Escape key closes it. Click outside closes it.

---

### Phase 5: AppComponent → signal + afterNextRender

**File:** `ntm-frontend/src/app/app.component.ts`

**Changes:**
- `showDoMoreBanner = false` → `showDoMoreBanner = signal(false)`
- Move `ngAfterViewInit` body to constructor using `afterNextRender()`:
  ```typescript
  afterNextRender(() => {
    this.#toastr.overlayContainer = this.toastContainer();
    setTimeout(() => {
      this.showDoMoreBanner.set(this.#visitService.showDoMoreMessage());
    }, 4000);
  });
  ```
- Remove `ChangeDetectorRef` injection
- Remove `AfterViewInit` implementation
- `closeDoMoreBanner()`: `this.showDoMoreBanner.set(false)` instead of property assignment
- Add `changeDetection: ChangeDetectionStrategy.OnPush`
- Template: `showDoMoreBanner` → `showDoMoreBanner()`

**Verify:** App loads, do-more banner appears after 4s delay, closing it works.

---

### Phase 6: Add OnPush to OrganizationDetailsComponent

**File:** `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts`

By Phase 6: all data fields are signals, no `cdr.detectChanges()` calls remain, `id` is already `input()`.

Add `changeDetection: ChangeDetectionStrategy.OnPush`.

**Verify:** Full org page test — stats load, edit works, delete user works, delete org works.

---

### Phase 7: Clean up notifications repo inconsistency

**Current state:** `notifications.repository.ts` exposes both `notificationCount$: Observable<number>` AND `notificationCountSignal: Signal<number>` — violates the "repos are pure observables" rule.

**Fix in `notifications.repository.ts`:**
- Remove `notificationCountSignal` field entirely (repo = pure observables)
- Keep `notificationCount$` as the Observable field

**Fix in consumers:**
- `navigation.component.ts`: currently uses `notificationCountSignal` directly → replace with `toSignal(this.#notificationsRepository.notificationCount$)` as a component field initializer
- `admin-dashboard.component.ts`: uses `notificationCount$` with `| async` → leave as-is (fine)
- `notifications-overview.component.ts`: uses `getAll() | async` → leave as-is (fine)

**Verify:** Notification count shows in nav and on admin dashboard.

---

## Known non-trivial aspects

**`protected updateStoreData` across repositories:** `UserRepository` mutates `OrganizationRepository`'s arrays via its getters. Since `updateStoreData` is `protected` on `BaseRepository`, `UserRepository` can't call it directly on another repo instance. Solution: add `updateUsers()` and `updateHeadEditors()` as public methods on `OrganizationRepository`.

**PopupComponent `effect()` initial run:** `effect()` in Angular runs immediately on construction with the current signal value. If `visible` starts as `false`, the effect fires `closePopup()` on init — potentially causing issues. Guard: check `if (this.visibleClass() !== 'is-hidden')` inside `closePopup()` before running the close animation.

---

## Reference

- IPQ2 research: `ip-3-ntm-organization-details-signals-smart-dumb.md`, `ip-6-ntm-onpush-immutability-signal-inputs.md`
