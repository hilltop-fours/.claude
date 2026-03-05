# chore(signals): #110904 NTM [FE] overgebleven @ decorators migreren naar signal variants

**Story:** #110904
**Task:** #111093
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

## Implementation Checklist

All changes are stashed. Unstash group by group, verify build, commit.

**Commit groups:**
1. `core/components` + `shared` simple components — button, banner, search-input, info-button, notification, floating-action-button, carousel, file-upload, multi-select-dropdown, pie-chart, accordion
2. `shared` overlays — popup + drawer
3. `shared` stepper — stepper + step-header + step-panel
4. `shared` list-card — list-card, list-card-list-item, list-card-organization-contact, list-card-organization-info, list-card-organization-permissions
5. `about` + `account` + `do-more` + `tutorial` + `welcome` — small modules
6. `users` — one commit
7. `standards` — one commit
8. `publications` — one commit

---

### Commit 1 — core/components + shared simple components

- [ ] `core/navigation-small` — `@Input()`/`@Output()` → `input()`/`output()`, template `theme()`/`icon()`
- [ ] `shared/accordion/accordion-item` — `@Input() expanded` kept as `@Input()` intentionally (mutable local state)
- [ ] `shared/accordion/accordion` — `@Output()` → `output()`
- [ ] `shared/banner` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/button` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/carousel` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/charts/pie-chart` — `@Input()`/`OnChanges` → `input()`/`effect()`
- [ ] `shared/file-upload` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/floating-action-button` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/info-button` — `@Output()` → `output()`
- [ ] `shared/multi-select-dropdown` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/notification` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/search-input` — `@Input()`/`@Output()` → `input()`/`output()`

### Commit 2 — shared overlays

- [ ] `shared/popup` — `@Input()`/`@Output()`/`OnChanges` → `input()`/`output()`/`effect()`, `visibleClass` → `signal()`
- [ ] `shared/drawer` — `@Input()`/`@Output()` → `input()`/`output()`

### Commit 3 — shared stepper

- [ ] `shared/stepper` — `@ViewChild` → `viewChild()`
- [ ] `shared/step-header` — kept `EventEmitter` (stepper subscribes with `.pipe()`)
- [ ] `shared/step-panel` — kept `EventEmitter` (stepper subscribes with `.pipe()`)

### Commit 4 — shared list-card

- [ ] `shared/list-card/list-card` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `shared/list-card/list-card-list-item` — `@Input()` → `input()`, template `key()`/`value()`
- [ ] `shared/list-card/list-card-organization-contact` — `@Input()` → `input.required()`, `drawerVisible` → `signal()`, `canEdit` → `computed()`
- [ ] `shared/list-card/list-card-organization-info` — `@Input()` → `input.required()`, `drawerVisible` → `signal()`, `canEdit` → `computed()`, removed `ChangeDetectorRef`
- [ ] `shared/list-card/list-card-organization-permissions` — `@Input()` → `input.required()`, `drawerVisible` → `signal()`, `canEdit` → `computed()`

### Commit 5 — small modules (about, account, do-more, tutorial, welcome)

- [ ] `modules/about/about` — `@Input()` → `input()`
- [ ] `modules/account/account-new-form-organization` — `@Input()`/`OnChanges` → `input()`/`effect()`
- [ ] `modules/account/account-new-form-role` — `@Input()`/`OnChanges` → `input()`/`effect()`
- [ ] `modules/do-more/do-more-themes-item` — `@Input()` → `input()`
- [ ] `modules/tutorial/tutorial-section` — `@Input()`/`@HostBinding` → `input()` + `host: { '[class.right]': 'textPosition()' }`
- [ ] `modules/welcome/do-more-banner` — `@Input()`/`@Output()` → `input()`/`output()`

### Commit 6 — modules/users

- [ ] `users-edit-personal-info` — `@Input()` → `input.required()`, `drawerVisible` → `signal()`, `canEdit` → `computed()`
- [ ] `users-edit-role` — `@Input()` → `input.required()`, drawer booleans → `signal()`, `canEdit` → `computed()`
- [ ] `users-edit-role-drawer` — `@Input()` → `input.required()`, `visible` → `input(false)`, getters use `form().get()`
- [ ] `users-edit-role-organization-contact-drawer` — `@Input()` → `input.required()`, `visible` → `input(false)`
- [ ] `users-edit-role-organization-drawer` — `@Input()` → `input.required()`, `visible` → `input(false)`, button props → `computed()`
- [ ] `user-delete-popup` — `@Input()`/`@Output()` → `input()`/`output()`, setter → `effect()` + `signal()`
- [ ] `users-edit-publicist-role-popup` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `users-new-drawer` — `@Input() visible` → `input(false)`, `closeDrawer` emits false directly

### Commit 7 — modules/standards

- [ ] `standard-edit-header` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `version-form` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `standards-filters-aside` — `@ViewChildren` → `viewChildren()`
- [ ] `standards-edit` — `@HostBinding('class')` → `host: { class: 'ntm-container' }`

### Commit 8 — modules/publications

- [ ] `publications-detail-contact` — `@Input()` → `input()`, getters → `computed()`
- [ ] `publications-detail-data-exchanges` — `@Input()` → `input()`
- [ ] `publications-detail-image` — `@Input()`/`OnChanges` → `input()`/`effect()`
- [ ] `publications-detail-quality` — `@Input()` → `input()`
- [ ] `publications-detail-scope` — `@Input()` → `input()`, `isPreview` → `input(false)`
- [ ] `data-exchange-form` — `@Input()` → `input.required()`, getters use `form().get()`
- [ ] `publication-edit-form-contact` — `@Input()` → `input.required()`
- [ ] `publication-edit-form-data-exchange` — `@Input()` → `input.required()`, getter uses `form().get()`
- [ ] `publication-edit-form-scope` — `@Input()`/`OnChanges` → `input()`/`effect()`
- [ ] `publication-edit-header` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `publication-filters-aside` — `@ViewChildren` → `viewChildren()`, `forEach` uses `()`
- [ ] `favorite-button` — `@Input()` → `input.required()`, accesses `publication().id`/`.favorite`
- [ ] `linkedin-share-button` — `@Input()` → `input()`
- [ ] `publication-share-popup` — `@Input()`/`@Output()` → `input()`/`output()`
- [ ] `whatsapp-share-button` — `@Input()` → `input()`
- [ ] `publications-edit` — `@HostBinding('class')` → `host: { class: 'ntm-container' }`

---

## Known non-trivial aspects

**`protected updateStoreData` across repositories:** `UserRepository` mutates `OrganizationRepository`'s arrays via its getters. Since `updateStoreData` is `protected` on `BaseRepository`, `UserRepository` can't call it directly on another repo instance. Solution: add `updateUsers()` and `updateHeadEditors()` as public methods on `OrganizationRepository`.

**PopupComponent `effect()` initial run:** `effect()` in Angular runs immediately on construction with the current signal value. If `visible` starts as `false`, the effect fires `closePopup()` on init — potentially causing issues. Guard: check `if (this.visibleClass() !== 'is-hidden')` inside `closePopup()` before running the close animation.

---

## Reference

- IPQ2 research: `ip-3-ntm-organization-details-signals-smart-dumb.md`, `ip-6-ntm-onpush-immutability-signal-inputs.md`
