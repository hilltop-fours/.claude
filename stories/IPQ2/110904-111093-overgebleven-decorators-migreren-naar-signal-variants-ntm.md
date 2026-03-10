# chore(signals): #110904 NTM [FE] overgebleven @ decorators migreren naar signal variants

**Story:** #110904
**Task:** #111093
**Branch:** `chore/110904/111093/migrate-remaining-decorators-to-signal-variants-ntm`
**Date:** 2026-03-04

---

## SCOPE BOUNDARY — STRICT

**This story is ONLY about replacing decorator syntax with signal equivalents.**

### What is IN scope

| Change | Reason |
|--------|--------|
| `@Input()` → `input()` | Direct decorator replacement |
| `@Output()` → `output()` | Direct decorator replacement |
| `@ViewChild()` → `viewChild()` | Direct decorator replacement |
| `@ViewChildren()` → `viewChildren()` | Direct decorator replacement |
| `@ContentChildren()` → `contentChildren()` | Direct decorator replacement — **but only if `ngAfterViewInit` is not present**. If the component uses `ngAfterViewInit` with `.changes.subscribe()`, keep `@ContentChildren` + `QueryList` + `ngAfterViewInit` as a unit and defer to a later story. |
| `@HostBinding()` → `host: {}` | Direct decorator replacement |
| ~~`@HostListener()` → `host: {}`~~ | **NOT done** — reviewer prefers `@HostListener` on the method. Revert if already migrated. |
| `ngOnChanges` → `effect()` | **Forced** — signal inputs do not trigger `ngOnChanges`, so it breaks after the migration. Must be replaced. |
| `ChangeDetectorRef` removal | **Forced** — only when the migration itself makes it dead code. |

### What is OUT of scope — do NOT touch

| Pattern | Reason deferred |
|---------|----------------|
| `ngOnInit` | Works fine alongside signal inputs. Not forced by the migration. |
| `ngAfterViewInit` | Works fine alongside signal inputs. Not forced by the migration. |
| `ngOnDestroy` / `takeUntilDestroyed` | Unrelated to decorator migration. |
| `@UntilDestroy()` / `untilDestroyed(this)` | Unrelated to decorator migration. |
| `Observable` + `async` pipe → `toSignal()` | Separate architectural decision. |
| `ChangeDetectionStrategy.OnPush` additions | Separate story. |
| Array mutation bugs (`splice`, `push`) | Unrelated bug fix. |
| Any logic inside lifecycle hooks | Not a decorator change. |

**The test:** if a change would not be required to keep the component compiling and working after the decorator swap, it does not belong in this PR.

---

## Per-File Migration Checklist

Apply this checklist to **every file** touched in this story. Go through each item in order.

---

### 1. `@Input()` → `input()`
- Replace `@Input() foo: Type` → `readonly foo = input<Type>()`
- Replace `@Input() foo: Type = default` → `readonly foo = input(default)`
- Replace `@Input({ required: true }) foo!: Type` → `readonly foo = input.required<Type>()`
- Update template: `foo` → `foo()` everywhere the input is read
- Remove `Input` from `@angular/core` import if no longer used

### 2. `@Output()` → `output()`
- Replace `@Output() foo = new EventEmitter<Type>()` → `readonly foo = output<Type>()`
- Replace `@Output() readonly foo: EventEmitter<Type> = new EventEmitter()` → same
- `this.foo.emit(value)` stays the same ✓
- Remove `Output`, `EventEmitter` from `@angular/core` import if no longer used
- **Exception:** keep `EventEmitter` if something subscribes to it with `.pipe()` (e.g. stepper subscribes to step-header's `clickEmitter`)

### 3. `@Input()` + `@Output() xChange` two-way binding → `model()`
- Identify the pattern: `@Input() visible = false` + `@Output() visibleChange = new EventEmitter<boolean>()`
- Replace both with: `readonly visible = model(false)`
- Update internal emits: `this.visibleChange.emit(false)` → `this.visible.set(false)`
- Update template binding in **parent**: `[visible]="x" (visibleChange)="x=$event"` → `[(visible)]="x"`
- Remove `input`, `output` (or `Input`, `Output`, `EventEmitter`) from import if no longer needed, add `model`

### 4. `@ViewChild()` / `@ViewChildren()` / `@ContentChildren()` → signal queries
- Replace `@ViewChild(Foo) foo!: Foo` → `readonly foo = viewChild.required(Foo)` or `viewChild(Foo)`
- Replace `@ViewChildren(Foo) foos!: QueryList<Foo>` → `readonly foos = viewChildren(Foo)`
- Replace `@ContentChildren(Foo) foos!: QueryList<Foo>` → `readonly foos = contentChildren(Foo)`
- Update usages: `this.foos` → `this.foos()`, `this.foos.forEach(...)` → `this.foos().forEach(...)`
- Remove `ViewChild`, `ViewChildren`, `ContentChildren`, `QueryList` from import if no longer used
- **Exception:** signal queries cannot use `#` private prefix — use `private readonly` instead

### 5. `@HostBinding()` → `host: {}` in `@Component`
- Replace `@HostBinding('class.foo') bar = true` → add `host: { '[class.foo]': 'bar' }` to `@Component`
- Replace `@HostBinding('class')` with a static string → `host: { class: 'my-class' }`
- Remove `HostBinding` from import

### 6. `@HostListener()` → `host: {}` in `@Component`
- **DO NOT perform this migration** — reviewer confirmed `@HostListener` is not deprecated and is preferred (PR #111306)
- If `@HostListener` was already migrated to `host: {}` in any file on this branch → **revert it** back to `@HostListener` on the method and restore `HostListener` to the import

### 7. `ngOnChanges` → `effect()`
- Identify which `@Input()` the `ngOnChanges` is watching
- Convert that `@Input()` to `input()` first (step 1 above)
- Replace `ngOnChanges(changes)` with `effect(() => { ... })` in the constructor or as a field
- Read the input signal value inside the effect: `this.foo()`
- Remove `OnChanges`, `SimpleChanges` from import if no longer used

### 8. Getter/setter → `signal()`
- Identify pattern: private backing field + getter + setter that calls `cdr.detectChanges()`
  ```ts
  #foo = false;
  get foo() { return this.#foo; }
  set foo(v: boolean) { this.#foo = v; this.#cdr.detectChanges(); }
  ```
- Replace with: `readonly foo = signal(false)`
- Update all internal reads: `this.foo` → `this.foo()`
- Update template reads: `foo` → `foo()`
- Update external writes: `component.foo = true` → `component.foo.set(true)`
- Proceed to step 9 (cdr) — the setter was probably the only reason cdr existed

### 9. `ChangeDetectorRef` → remove
- Check if `cdr.detectChanges()` calls remain after steps 7 and 8
- If none remain: remove `inject(ChangeDetectorRef)` and `ChangeDetectorRef` from import
- If still needed: leave it and add a comment explaining why

### 10. Plain mutable properties → `signal()` (if used reactively in template)
- Identify properties that are assigned from outside the component (not via input binding)
  and are read in the template or in `computed()`
- Replace with `readonly foo = signal(initialValue)`
- Update reads: `this.foo` → `this.foo()` in template and TS
- Update writes: `this.foo = value` → `this.foo.set(value)`

### 11. Plain getters → `computed()` (if derived from signals)
- Identify getters that compute a value from signal inputs or other signals:
  ```ts
  get canEdit() { return this.authService.hasPermission(this.user()); }
  ```
- Replace with `computed()`:
  ```ts
  readonly canEdit = computed(() => this.authService.hasPermission(this.user()));
  ```
- Update template: `canEdit` → `canEdit()` if not already a function call
- Leave getters that don't depend on signals as-is (no benefit from computed)

### 12. `readonly` audit
- Every `input()`, `output()`, `model()`, `signal()`, `computed()`, `viewChild()`, `viewChildren()` must be `readonly`
- Enum/constant references assigned once: `readonly crudEnum = CRUD`
- FormGroup assigned once at declaration: `readonly form = new FormGroup(...)`
- Injected services: `readonly #service = inject(Service)` (already enforced by `#`)

### 13. Private `#` audit
- All injected services and private fields should use `#` prefix instead of `private` keyword
- Exception: Angular signal queries (`viewChild`, `viewChildren`, `contentChildren`) — use `private readonly` instead of `#` due to compiler limitations

---

## Story — Original Text

### Description

alle `@Input()` `@Output()` `@ViewChild()` `@ViewChildren()` `@HostBinding()` en `@HostListener()` decorators vervangen door de signal varianten `input()` `output()` `viewChild()` `viewChildren()` en `host: {}` en `ngOnChanges` wat een input kreeg is vervangen door `effect()` en andere zijn `computed()` geworden

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
- For two-way binding (`[x]="val" (xChange)="val=$event"` pattern): replace both with `model()` — one signal that handles both directions
  ```typescript
  // BEFORE
  @Input() visible = false;
  @Output() visibleChange = new EventEmitter<boolean>();
  // AFTER
  readonly visible = model(false);
  // In template: [(visible)]="visible" instead of [visible]="..." (visibleChange)="..."
  // Internally: this.visible.set(false) instead of this.visibleChange.emit(false)
  ```

**`signal()` = use for writable internal state or state set imperatively from outside.**
- A plain writable signal — anyone with a reference can call `.set()` on it
- Use when the value is mutated over time, but is NOT an Angular input/output binding
- Example: `readonly selected = signal(false)` — set by another component via `componentRef.selected.set(true)`
- This is the replacement for plain mutable properties that needed `ChangeDetectorRef` with `OnPush`

**Remove `ChangeDetectorRef` wherever possible.**
- `cdr.detectChanges()` is an old Angular workaround for `OnPush` components where Angular couldn't detect external mutations
- Signals are natively reactive — reading a signal in a template auto-subscribes to changes, so `.set()` triggers re-render automatically
- If you see `ChangeDetectorRef` + `detectChanges()` in a component, look for the plain property being mutated from outside and replace it with `signal()` → then remove `cdr` entirely

**Replace getter/setter patterns with `signal()`.**
- Getter/setter was the old way to intercept property writes and call `cdr.detectChanges()` manually
  ```typescript
  // BEFORE: getter/setter + cdr
  #selected = false;
  get selected() { return this.#selected; }
  set selected(value: boolean) { this.#selected = value; this.#cdr.detectChanges(); }
  // AFTER: plain signal, no cdr needed
  readonly selected = signal(false);
  // Caller uses: component.selected.set(true)
  // Template uses: selected()
  ```

**`computed()` = use for derived values from signals.**
- Avoids recalculating on every change detection cycle
- Memoized — only recalculates when its signal dependencies change
- Use whenever a value can be expressed as a pure function of other signals
  ```typescript
  // BEFORE: plain getter (recalculates every change detection cycle)
  get canEdit(): boolean { return this.authService.hasPermission(this.user()); }
  // AFTER: computed (memoized, recalculates only when user() changes)
  readonly canEdit = computed(() => this.authService.hasPermission(this.user()));
  ```

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

## Merge Strategy — One PR Per Commit

**Decision (2026-03-09):** Instead of one large PR for the entire branch, merge in small batches: **one PR per commit group.**

**Rationale:** Easier to review, easier to revert if something breaks, and keeps main history clean with logical atomic units.

**Workflow per commit — "do it again" instructions for Claude:**
1. Find the next `pending` row in the commits table below
2. Note the commit hash and scope
3. Daniel creates a task in Azure DevOps → provides the task ID
4. Create branch: `chore/110904/{task-id}/{kebab-case-scope}` off `main`
5. `git cherry-pick {commit-hash}` onto the new branch
6. Amend the commit message to PR title format: `chore({scope}): #110904 #{task-id} {description}`
   - Write the description yourself from the changed files — ignore the WIP message entirely
   - Format: `type(scope): #story-id #task-id lowercase description`
7. Mark the row in the table as `✅ branch: chore/110904/{task-id}/...`
8. Commit story file update in `.claude` repo
9. Repeat from step 1 for the next row

**Branch naming:** `chore/110904/{task-id}/{kebab-case-description}` — always off `main`.
**Commit message:** PR title format only — `chore({scope}): #110904 #{task-id} description`. No WIP prefix, no body.

**Commits to ship (in order):**

| # | Commit | Scope | Task title (Azure DevOps) | Status |
|---|--------|-------|--------------------------|--------|
| 1 | `1db185d6` — stepper, step-header, step-panel | `shared/stepper` | `[FE] signals: stepper components` | ✅ branch: `chore/110904/111259/signals-stepper-components` |
| 2 | `348c3804` — account-new-form-organization, account-new-form-role | `modules/account` | `[FE] signals: account form components` | ✅ branch: `chore/110904/111299/signals-account-form-components` |
| 3 | `ce54e103` — about, do-more-themes-item, tutorial-section, do-more-banner | `modules/small` | `[FE] signals: small page modules` | ✅ branch: `chore/110904/111301/signals-small-page-modules` |
| 4 | `c39ea9ed` — drawer, popup | `shared/overlays` | `[FE] signals: drawer & popup` | ✅ branch: `chore/110904/111306/signals-drawer-popup` |
| 5 | `4d460689` — list-card components | `shared/list-card` | `[FE] signals: list-card components` | ✅ branch: `chore/110904/111366/signals-list-card-components` |
| 6 | `6e437ac3` — standards components | `modules/standards` | `[FE] signals: standards components` | ✅ branch: `chore/110904/111373/signals-standards-components` |
| 7 | `8f1edd6c` — publications shared components | `modules/publications` | `[FE] signals: publications shared` | ✅ branch: `chore/110904/111376/signals-publications-shared` |
| 8 | `7bd0b9ec` — publications details section components | `modules/publications` | `[FE] signals: publications detail` | pending |
| 9 | `40b015ab` — publications edit components + pages | `modules/publications` | `[FE] signals: publications edit` | pending |
| 10 | `68fe8f89` — publication-filters-aside | `modules/publications` | `[FE] signals: publications filters` | pending |
| 11 | `84d60f08` — users module | `modules/users` | `[FE] signals: users module` | pending |

> Note: commits 1–5 map to commit groups 3–5 in the original plan below (commit groups 1 and 2 appear to already be merged into main).

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

- [x] `core/navigation-small`
- [x] `shared/accordion/accordion-item`
- [x] `shared/accordion/accordion`
- [x] `shared/banner`
- [x] `shared/button`
- [x] `shared/carousel`
- [x] `shared/charts/pie-chart`
- [x] `shared/file-upload`
- [x] `shared/floating-action-button`
- [x] `shared/info-button`
- [x] `shared/multi-select-dropdown`
- [x] `shared/notification`
- [x] `shared/search-input`

### Commit 2 — shared overlays

- [x] `shared/popup`
- [x] `shared/drawer`

### Commit 3 — shared stepper

- [x] `shared/stepper`
- [x] `shared/step-header`
- [x] `shared/step-panel`

### Commit 4 — shared list-card

- [x] `shared/list-card/list-card`
- [x] `shared/list-card/list-card-list-item`
- [x] `shared/list-card/list-card-organization-contact`
- [x] `shared/list-card/list-card-organization-info`
- [x] `shared/list-card/list-card-organization-permissions`

### Commit 5 — small modules (about, account, do-more, tutorial, welcome)

- [x] `modules/about/about`
- [x] `modules/account/account-new-form-organization`
- [x] `modules/account/account-new-form-role`
- [x] `modules/do-more/do-more-themes-item`
- [x] `modules/tutorial/tutorial-section`
- [x] `modules/welcome/do-more-banner`

### Commit 6 — modules/users

- [x] `users-edit-personal-info`
- [x] `users-edit-role`
- [x] `users-edit-role-drawer`
- [x] `users-edit-role-organization-contact-drawer`
- [x] `users-edit-role-organization-drawer`
- [x] `user-delete-popup`
- [x] `users-edit-publicist-role-popup`
- [x] `users-new-drawer`

### Commit 7 — modules/standards

- [x] `standard-edit-header`
- [x] `version-form`
- [x] `standards-filters-aside`
- [x] `standards-edit`

### Commit 8 — modules/publications

- [x] `publications-detail-contact`
- [x] `publications-detail-data-exchanges`
- [x] `publications-detail-image`
- [x] `publications-detail-quality`
- [x] `publications-detail-scope`
- [x] `data-exchange-form`
- [x] `publication-edit-form-contact`
- [x] `publication-edit-form-data-exchange`
- [x] `publication-edit-form-scope`
- [x] `publication-edit-header`
- [x] `publication-filters-aside`
- [x] `favorite-button`
- [x] `linkedin-share-button`
- [x] `publication-share-popup`
- [x] `whatsapp-share-button`
- [x] `publications-edit`

---

## Known non-trivial aspects

**`protected updateStoreData` across repositories:** `UserRepository` mutates `OrganizationRepository`'s arrays via its getters. Since `updateStoreData` is `protected` on `BaseRepository`, `UserRepository` can't call it directly on another repo instance. Solution: add `updateUsers()` and `updateHeadEditors()` as public methods on `OrganizationRepository`.

**PopupComponent `effect()` initial run:** `effect()` in Angular runs immediately on construction with the current signal value. If `visible` starts as `false`, the effect fires `closePopup()` on init — potentially causing issues. Guard: check `if (this.visibleClass() !== 'is-hidden')` inside `closePopup()` before running the close animation.

---

## Reference

- IPQ2 research: `ip-3-ntm-organization-details-signals-smart-dumb.md`, `ip-6-ntm-onpush-immutability-signal-inputs.md`
