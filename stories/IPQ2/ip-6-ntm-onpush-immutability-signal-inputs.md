# chore(ip-sprint): IP-6 Apply OnPush + fix immutability bugs + migrate to input()/output() signals

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-6-ntm-onpush-immutability-signal-inputs`
**Project:** NTM (`ntm-frontend`)
**Date:** 2026-03-02
**Difficulty:** Medium
**Estimated days:** 2
**Depends on:** Story IP-3 (OrganizationDetailsComponent signals migration) should be done first

---

## Learning Objective

Learn three things that belong together — because you cannot safely apply one without understanding the other two:

1. **`ChangeDetectionStrategy.OnPush` — and what it actually requires** — Understanding that OnPush is not just a decorator you add to get performance. It changes Angular's rendering contract: a component with OnPush will only re-render when its signal or observable inputs change (by reference), when an `async` pipe emits, or when `markForCheck()` is called. Any component that relies on **mutable data** — arrays or objects mutated in place — will silently stop updating under OnPush. This story surfaces a real mutation bug that exists in the codebase today and fixes it as a prerequisite to adding OnPush.

2. **Immutable data patterns** — Learning to replace `Array.splice()`, `Array.push()`, and object property mutation with immutable equivalents: `Array.filter()`, `Array.map()`, spread operators, and `Object.assign()`. Understanding that Angular's change detection is reference-based: if the same array reference is passed in, Angular (under OnPush) sees no change, even if the array's contents changed.

3. **`input()` and `output()` — Angular 17's signal-based replacements for `@Input()` and `@Output()`** — Understanding how `input<T>()`, `input.required<T>()`, and `output<T>()` differ from the decorator-based equivalents. The key benefit: `input()` signals are reactive — they can be used inside `computed()` and `effect()` without any extra bridge. `output()` is simpler: it replaces `EventEmitter` with a typed emitter that doesn't need `new EventEmitter()` boilerplate.

This story is the **completion layer** of the NTM work started in Stories IP-1 and IP-3. Those stories removed the imperative change detection patterns. This story adds the declarative change detection strategy that makes everything run optimally.

---

## Learning Context

### Why OnPush is currently missing in NTM

NTM has approximately 196 components. Roughly 50% use `ChangeDetectionStrategy.OnPush`. The other half use Angular's default strategy (zone-based, checks everything on every event). This is not malicious — it's the natural result of:
- Components being created before the codebase adopted signals and OnPush as the standard
- No enforced lint rule requiring OnPush
- Developers being unsure whether adding OnPush would break existing behavior

The reason it's safe to add OnPush to a component *after* Stories IP-1 and IP-3 is that those stories removed the last imperative change detection patterns from the affected components. Once a component uses signals for all its state, OnPush is safe: signals are change-detection aware by design.

### The Array.splice() time bomb

This is the most important discovery in NTM's codebase for this story. There are at least two confirmed instances of in-place array mutation in the data layer:

**In `UserRepository`** (`ntm-frontend/src/app/core/data-access/user/user.repository.ts`, around lines 236-280):

```typescript
// CURRENT — mutates in place (dangerous under OnPush)
#updateUserInOrganizationUserList(user: IUser): void {
  const users = this.#organizationRepository.users; // gets the current users array
  const index = users.findIndex(u => u.id === user.id);
  if (index !== -1) {
    users.splice(index, 1, user); // SPLICE — mutates the array in place
  }
}

#deleteUserFromOrganizationUserList(userId: string): void {
  const users = this.#organizationRepository.users;
  const index = users.findIndex(u => u.id === userId);
  if (index !== -1) {
    users.splice(index, 1); // SPLICE — mutates the array in place
  }
}
```

**In `OrganizationRepository`** (`ntm-frontend/src/app/core/data-access/organizations/organization.repository.ts`):

```typescript
// CURRENT — mutates in place
#deleteOrganizationFromOrganizationList(organizationId: string): void {
  const organizations = this.organizations; // gets the current array
  const index = organizations.findIndex(o => o.id === organizationId);
  if (index !== -1) {
    organizations.splice(index, 1); // SPLICE — mutates the array in place
  }
}
```

**Why this hasn't caused visible bugs yet:** Both repositories use elf stores internally, which have their own change notification mechanism. The components that consume these stores are currently on default change detection — Angular's zone-based CD fires on every event and picks up any state change regardless of whether the reference changed. The bug is latent: it will only manifest once you add OnPush to a component that displays these lists.

**The fix is straightforward:**

```typescript
// FIXED — immutable replacement (safe under OnPush)
#updateUserInOrganizationUserList(user: IUser): void {
  patchState(store, (state) => ({
    users: state.users.map(u => u.id === user.id ? user : u)
  }));
}

#deleteUserFromOrganizationUserList(userId: string): void {
  patchState(store, (state) => ({
    users: state.users.filter(u => u.id !== userId)
  }));
}

#deleteOrganizationFromOrganizationList(organizationId: string): void {
  patchState(store, (state) => ({
    organizations: state.organizations.filter(o => o.id !== organizationId)
  }));
}
```

The exact fix depends on how the elf store is structured in these repositories — read them carefully before assuming `patchState` is available. The repositories may use `store.update(...)` with elf's operators instead. The principle is the same: replace the splice with an immutable filter/map, and use the store's update mechanism to set the new array (new reference).

### input() and output() — the new way

Since Angular 17, the `@Input()` decorator and `@Output()` + `EventEmitter` pattern have functional alternatives:

**Before (decorator-based):**
```typescript
@Component({ ... })
export class MyComponent {
  @Input() title: string = '';
  @Input({ required: true }) id!: string;
  @Output() selected = new EventEmitter<string>();
}
```

**After (signal-based):**
```typescript
@Component({ ... })
export class MyComponent {
  title = input<string>('');           // optional with default
  id = input.required<string>();       // required — TypeScript error if not passed
  selected = output<string>();         // no EventEmitter needed
}
```

Key behavioral differences:
- `input()` returns a `Signal<T>` — you read it as `this.title()` (function call), not `this.title`
- `input.required()` — no need for the `!` non-null assertion hack
- `input()` signals can be used directly in `computed()` and `effect()` — no need for `toSignal()` bridge
- `output()` does NOT return an EventEmitter — it returns an `OutputEmitterRef`. You call `.emit(value)` on it the same way, but it cannot be subscribed to from outside the component (which is by design — it's not an Observable)
- Templates using the component don't change: `[title]="myTitle"` and `(selected)="handleSelected($event)"` still work the same

This story applies `input()`/`output()` to all components touched by Stories IP-1, IP-3, and IP-6 itself.

### Which components get OnPush in this story

The scope is bounded to components already touched in this IP sprint:
- `AppComponent` (Story IP-1) — signals already converted
- `PopupComponent` (Story IP-1) — already has OnPush (verify)
- `OrganizationDetailsComponent` (Story IP-3) — signals already converted
- `ListCardOrganizationInfoComponent` (Story IP-3) — boundary already fixed

Any component that still calls `cdr.detectChanges()` anywhere is NOT ready for OnPush — fix the manual CD first.

---

## Analysis

### Files to change

| File | Action |
|------|--------|
| `ntm-frontend/src/app/core/data-access/user/user.repository.ts` | Fix `splice()` in `#updateUserInOrganizationUserList` and `#deleteUserFromOrganizationUserList` |
| `ntm-frontend/src/app/core/data-access/organizations/organization.repository.ts` | Fix `splice()` in `#deleteOrganizationFromOrganizationList` |
| `ntm-frontend/src/app/app.component.ts` | Add `changeDetection: ChangeDetectionStrategy.OnPush`; convert any remaining `@Input`/`@Output` to `input()`/`output()` |
| `ntm-frontend/src/app/shared/components/popup/popup.component.ts` | Verify OnPush already present; convert `@Input`/`@Output` to `input()`/`output()` |
| `ntm-frontend/src/app/modules/organization/pages/organization-details/organization-details.component.ts` | Add `changeDetection: ChangeDetectionStrategy.OnPush`; convert `@Input`/`@Output` |
| `ntm-frontend/src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts` | Add `changeDetection: ChangeDetectionStrategy.OnPush`; convert `@Input`/`@Output` |

### Watch out for

- `input()` requires importing from `@angular/core`: `import { input, output } from '@angular/core'`
- Anywhere in a template that binds to an `input()` signal property uses the same `[property]="value"` syntax — no template changes needed
- But anywhere the component CLASS reads its own input, it must change from `this.title` to `this.title()` — search all uses of the input property within the component class itself
- `output()` does not extend `Observable` — if any code outside the component subscribes to the EventEmitter as an Observable (e.g. `component.selected.subscribe(...)`), that breaks. Check for this pattern before converting.
- `PopupComponent` may already have `OnPush` — verify before adding it again

### Acceptance criteria

- `Array.splice()` calls removed from `UserRepository` (2 methods) and `OrganizationRepository` (1 method); replaced with immutable equivalents using the store's update mechanism
- All 4 IP-sprint-touched components have `changeDetection: ChangeDetectionStrategy.OnPush`
- No `cdr.detectChanges()` calls remain in any of the 4 components
- `@Input()` decorators replaced with `input()` / `input.required()` in all 4 components
- `@Output()` + `EventEmitter` replaced with `output()` in all 4 components
- All internal reads of input properties updated from `this.property` to `this.property()`
- Build passes under strict mode, no TypeScript errors
- Org CRUD flow tested end-to-end: create org, edit org name, delete user from org, delete org — all work correctly

---

## Implementation Plan

### Phase 1: Fix the immutability bugs first

This MUST come before OnPush. Read `user.repository.ts` and `organization.repository.ts` carefully. Find all `splice()` calls (and any `push()` calls while you're there). Replace each with an immutable equivalent using `Array.filter()` and `Array.map()`. The store's state update mechanism (elf's `store.update(...)` or `patchState`) must be used to set the new array so the store's change notifications fire.

Run `npm run build`. Run a manual test: edit a user in an organization, delete a user — verify state updates correctly in the browser.

WIP commit after Phase 1.

### Phase 2: Convert @Input/@Output to input()/output()

Go through the 4 target components. For each one:
- Replace `@Input() property: Type` with `property = input<Type>()`
- Replace `@Input({ required: true }) property!: Type` with `property = input.required<Type>()`
- Replace `@Output() event = new EventEmitter<Type>()` with `event = output<Type>()`
- Update all internal reads: `this.property` → `this.property()` (only inside the component class, not in templates)
- Verify templates still compile (they should — the binding syntax doesn't change)

Run `npm run build` after each component to catch issues early.

WIP commit after Phase 2.

### Phase 3: Add OnPush

Add `changeDetection: ChangeDetectionStrategy.OnPush` to all 4 components. Run the full build. Open the application and exercise each affected component:
- AppComponent: verify welcome popup and do-more banner still appear
- PopupComponent: verify it opens and closes correctly with animation
- OrganizationDetailsComponent: navigate to an org, verify all stats load, verify inline edit works
- ListCardOrganizationInfoComponent: verify org name editing works end-to-end including the save confirmation

If any component breaks after adding OnPush, the root cause is almost always either: a remaining mutable state update, a remaining `cdr.detectChanges()` that was removed too early, or a plain class property (not a signal) that changes but doesn't trigger OnPush. Debug carefully.

WIP commit after Phase 3.
