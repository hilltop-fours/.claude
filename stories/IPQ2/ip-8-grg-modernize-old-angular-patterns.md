# chore(ip-sprint): IP-8 Modernize old Angular patterns in GRG — BehaviorSubject, ngOnDestroy, DetailsBaseComponent

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-8-grg-modernize-old-angular-patterns`
**Project:** GRG (`traffic-sign-frontend`)
**Date:** 2026-03-02
**Difficulty:** Medium
**Estimated days:** 2

---

## Learning Objective

Learn what "modernizing an Angular codebase" actually means in practice — not just swapping syntax, but understanding WHY each old pattern existed, what problem Angular's new APIs solve, and how to migrate safely without breaking behavior.

Specifically:

1. **`BehaviorSubject` → `signal()`** — Understand that `BehaviorSubject` was the pre-signal way to hold mutable reactive state. It carries Observable subscription overhead and requires `.next()` to update, `.asObservable()` to expose, and `.getValue()` to read synchronously. `signal()` replaces all three with a single read/write API that Angular's rendering engine understands natively. Learn to identify when a `BehaviorSubject` is pure UI state (always replace) vs a stream with subscribers (may need `toObservable()` bridge).

2. **`ngOnDestroy` + manual `Subject.complete()` → `DestroyRef` + `takeUntilDestroyed()`** — The old pattern of injecting a `Subject`, piping `takeUntil(this.destroy$)`, then completing the Subject in `ngOnDestroy` is ~8 lines of boilerplate per component. `takeUntilDestroyed(destroyRef)` achieves the same in 1 line. `DestroyRef` is Angular's own destroy lifecycle hook, injected via `inject(DestroyRef)`, and it fires at the right time in the component/service destruction cycle.

3. **Modernizing a base class that child classes depend on** — `DetailsBaseComponent` is extended by 11+ child components. Any change to the base class propagates to all children. This requires careful, incremental migration: change the base, verify children still compile, test a sample child manually. This is the most architectural skill in this story — understanding the blast radius of a base class change.

4. **`BehaviorSubject` as a bridge for `isMutation` input** — `DetailsBaseComponent` has `isMutation$ = new BehaviorSubject(false)` which it manually syncs in `ngOnInit` from its `@Input() isMutation`. This is a workaround for the fact that `@Input` values weren't reactive before Angular 17's `input()` signals. With `input()`, this bridge is no longer needed. Understanding this "bridge pattern" and why it became obsolete is a key insight.

---

## Learning Context

### DetailsBaseComponent — the root of many old patterns

File: `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/details-base/details-base.component.ts`

This is the base class for all 11+ detail card components. It currently has:

```typescript
// OLD PATTERN 1: BehaviorSubject as reactive @Input bridge
@Input() isMutation = false;
isMutation$ = new BehaviorSubject(false);

ngOnInit() {
  this.isMutation$.next(this.isMutation); // Manual sync in lifecycle hook
}
```

Why this existed: Before Angular 17's `input()` signal, `@Input()` values were plain class properties — not Observable, not reactive. If child classes needed `isMutation` as an Observable (to use in `combineLatest`, `switchMap`, etc.), the only way was to manually copy the value into a `BehaviorSubject` in `ngOnInit`. This was standard Angular practice for years.

The modern equivalent:

```typescript
// MODERN: input() signal is inherently reactive
isMutation = input(false);

// To get an Observable from a signal input (for combineLatest etc.):
isMutation$ = toObservable(this.isMutation);
// OR use the signal directly in computed()/effect()
```

Note: since `isMutation$` is used in `combineLatest([this.isMutation$, this.roadSectionId$])` throughout child classes, we need `toObservable(this.isMutation)` to maintain Observable compatibility — OR we change child classes to use signals directly (which is the better long-term approach but is in scope for Story IP-7).

For this story, the safe migration is: `isMutation = input(false)` + `isMutation$ = toObservable(this.isMutation)`. This preserves all child class Observable chains while removing the manual `BehaviorSubject` bridge.

### AbstractMutationsTableComponent — BehaviorSubject for filter state

File: `traffic-sign-frontend/src/app/modules/road-feature/components/overview/mutations-table/abstract-mutations-table.component.ts`

Currently has:

```typescript
// OLD PATTERN 2: BehaviorSubject wrapping a signal (double pattern!)
filterActiveRoadAuthority$: BehaviorSubject<boolean> = new BehaviorSubject<boolean>(false);
filterActiveRoadAuthority = toSignal(this.filterActiveRoadAuthority$);
```

This is especially redundant: a `BehaviorSubject` being immediately converted to a `signal` via `toSignal()`. It means every toggle goes through: `BehaviorSubject.next()` → Observable emission → `toSignal()` subscription → signal update. The direct version is:

```typescript
// MODERN: signal directly
filterActiveRoadAuthority = signal(false);
```

Then wherever the code calls `this.filterActiveRoadAuthority$.next(!current)`, replace with `this.filterActiveRoadAuthority.update(v => !v)`.

### SchoolZoneDetailsComponent — multiple old patterns in one file

File: `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/school-zone-details/school-zone-details.component.ts`

This component has accumulated several old patterns:

```typescript
// OLD PATTERN 3: Manual ngOnDestroy with Subject.complete()
triggerVerificationsUpdate = new BehaviorSubject<void>(undefined);

ngOnDestroy() {
  this.triggerVerificationsUpdate.complete();
}
```

The `triggerVerificationsUpdate` BehaviorSubject is used to trigger re-fetches of verification data. In the signal world, this could be a `signal<number>(0)` increment counter, or better yet, a `signal<void>(undefined)` with `.set(undefined)` as the trigger. But since it's used as an Observable (piped in `switchMap`), the cleanest migration is to keep it as a Subject but remove the manual `ngOnDestroy` in favor of `takeUntilDestroyed`:

```typescript
// MODERN: DestroyRef handles cleanup, no ngOnDestroy needed
readonly #destroyRef = inject(DestroyRef);
triggerVerificationsUpdate = new Subject<void>(); // Subject not BehaviorSubject (no initial value needed for a trigger)

// Remove ngOnDestroy entirely — the Subject doesn't need explicit completion
// because its pipeline uses takeUntilDestroyed(this.#destroyRef)
```

Also: this component has a manual `constructor() { super(); this.#listenToFeatures(); }`. This is the only detail card with a manual constructor. The `#listenToFeatures()` call could likely be moved to a field initializer or `ngOnInit` to eliminate the explicit constructor.

### AppComponent — BehaviorSubject for organizationId

File: `traffic-sign-frontend/src/app/app.component.ts`

```typescript
// OLD PATTERN 4: BehaviorSubject as mutable state holder
organizationIdBS = new BehaviorSubject<string | undefined>(undefined);
```

This is used to track the currently selected organization. It should be:

```typescript
organizationId = signal<string | undefined>(undefined);
```

Then all places that call `.next()` call `.set()`, and places that subscribe to `.asObservable()` either use `toObservable(this.organizationId)` or read the signal directly.

### RoadCategoryRepository and SpeedLimitRepository — constructor subscription pattern

Files:
- `src/app/modules/road-feature/state/road-category.repository.ts`
- `src/app/modules/road-feature/state/speed-limit.repository.ts`

Both use constructor subscriptions with `combineLatest + takeUntilDestroyed`. This is actually a GOOD, modern pattern — there is nothing wrong with it. The only improvement would be using `effect()` to drive the same logic reactively if the inputs become signals. But since `selectedRoadSectionIds$` and `visibleRoadFeatureMapElementId$` are still Observables (from elf stores), the constructor subscription with `takeUntilDestroyed` is appropriate here.

**Verdict: leave these as-is for this story.** Document in a comment that they can be converted to `effect()` once the elf stores are migrated to signals (future work).

---

## Analysis

### Files to change

| File | Pattern to fix | Modern replacement |
|------|---------------|-------------------|
| `details-base.component.ts` | `BehaviorSubject isMutation$` + `ngOnInit` sync | `isMutation = input(false)` + `isMutation$ = toObservable(this.isMutation)` |
| `abstract-mutations-table.component.ts` | `BehaviorSubject<boolean>` + `toSignal()` wrapper | `signal(false)` directly |
| `school-zone-details.component.ts` | Manual `ngOnDestroy` + `BehaviorSubject trigger` + manual constructor | Remove `ngOnDestroy`, use `takeUntilDestroyed`, simplify constructor |
| `app.component.ts` | `organizationIdBS = new BehaviorSubject(...)` | `organizationId = signal<string \| undefined>(undefined)` |

### What NOT to change in this story

- `road-category.repository.ts` and `speed-limit.repository.ts` constructor subscriptions — these are fine
- Services that use BehaviorSubject for HTTP caching (with `shareReplay`) — a different pattern, not in scope
- Any BehaviorSubject that has external subscribers from outside the class (needs careful assessment before changing)

### Key things to verify before changing DetailsBaseComponent

`DetailsBaseComponent` is extended by 11+ components. Before changing `isMutation$` from `BehaviorSubject` to `toObservable(this.isMutation)`:

1. Search all child classes for uses of `this.isMutation$` — they all use it in `combineLatest([this.isMutation$, this.roadSectionId$])`. With `toObservable(this.isMutation)` the type is still `Observable<boolean>`, so these should compile unchanged.
2. Search all child classes for direct reads of `this.isMutation` (the @Input property) — these become `this.isMutation()` (signal call) after migration.
3. Check if any child class overrides `ngOnInit` with `super.ngOnInit()` — they will need updating if `ngOnInit` is removed from the base.

### Acceptance criteria

- `DetailsBaseComponent.isMutation$` is `toObservable(this.isMutation)` where `isMutation = input(false)`
- `DetailsBaseComponent` no longer has `ngOnInit` for the BehaviorSubject sync
- All 11 child components still compile without changes to their `combineLatest` usage
- `AbstractMutationsTableComponent.filterActiveRoadAuthority` is a plain `signal(false)` with no BehaviorSubject anywhere
- `SchoolZoneDetailsComponent` has no `ngOnDestroy` (cleanup handled by `takeUntilDestroyed`)
- `AppComponent.organizationIdBS` replaced with `organizationId = signal<string | undefined>(undefined)`; all `.next()` calls replaced with `.set()`; all `.asObservable()` usages replaced with `toObservable(this.organizationId)` where needed
- Build passes, 0 TypeScript errors
- Manual test: speed limit details card loads correctly, mutations table filter toggle works, org selection in app component works

---

## Implementation Plan

### Phase 1: Fix AbstractMutationsTableComponent

The simplest change. Replace `filterActiveRoadAuthority$: BehaviorSubject<boolean>` + `toSignal()` with a direct `signal(false)`. Find all callers of `.next(true/false)` and replace with `.set(true/false)` or `.update(v => !v)`. Build and test the mutations table filter.

WIP commit after Phase 1.

### Phase 2: Fix DetailsBaseComponent

Read `details-base.component.ts` fully. Map all uses of `isMutation$` and `isMutation` in the file and in 2-3 child classes. Replace `@Input() isMutation` with `isMutation = input(false)`. Replace `isMutation$ = new BehaviorSubject(false)` with `isMutation$ = toObservable(this.isMutation)`. Remove the `ngOnInit` (or keep it if other logic lives there — read carefully). Run `npm run build` and fix any child class errors (likely `this.isMutation` → `this.isMutation()` in some places).

WIP commit after Phase 2.

### Phase 3: Fix SchoolZoneDetailsComponent

Read the full file. Remove `ngOnDestroy()` and the `triggerVerificationsUpdate.complete()` call. Ensure the pipeline that uses `triggerVerificationsUpdate` has `takeUntilDestroyed(this.#destroyRef)` so it cleans up properly. Simplify the constructor if possible. Build and manually test school zone details.

WIP commit after Phase 3.

### Phase 4: Fix AppComponent BehaviorSubject

Replace `organizationIdBS = new BehaviorSubject<string | undefined>(undefined)` with `organizationId = signal<string | undefined>(undefined)`. Search for all usages: `.next()` → `.set()`, `.asObservable()` → `toObservable(this.organizationId)` or direct signal read. Build and test organization selection flow.

WIP commit after Phase 4.

---

## Additional Old Patterns to Modernize (General — Any Project)

Discovered during IP-sprint implementation. These patterns appear across projects and are candidates for future stories.

---

### Decorator migration scope boundary (applicable to any project's decorator migration story)

When doing a story specifically about migrating `@Input`/`@Output`/`@ViewChild` etc. to signal variants, the scope must be kept tight. The rule agreed for NTM story #110904/#111093:

**IN scope (forced by the migration):**
- `@Input()` → `input()`, `@Output()` → `output()`, `@ViewChild()` → `viewChild()`, etc.
- `ngOnChanges` → `effect()` — signal inputs do not trigger `ngOnChanges`, so it breaks. Must be replaced.
- `ChangeDetectorRef` removal — only when it becomes dead code as a direct result of the migration.

**OUT of scope (leave untouched, defer to a separate story):**
- `ngOnInit`, `ngAfterViewInit` — these work fine alongside signal inputs; not forced by the migration.
- `ngOnDestroy` / `takeUntilDestroyed` / `@UntilDestroy()` — unrelated to decorator migration.
- `Observable` + `async` pipe → `toSignal()` conversions — separate architectural decision.
- `ChangeDetectionStrategy.OnPush` additions — separate story.
- Array mutation bugs (`splice`, `push`) — unrelated bug fix.

**Test:** if the change would not be required to keep the component compiling and working after the decorator swap, it does not belong in the PR.

---

---

### `@UntilDestroy()` + `untilDestroyed(this)` → `takeUntilDestroyed(destroyRef)`

**Old pattern** (`@ngneat/until-destroy` — third-party library):
```typescript
import { UntilDestroy, untilDestroyed } from '@ngneat/until-destroy';

@UntilDestroy()
export class MyComponent {
  constructor() {
    someObservable$.pipe(untilDestroyed(this)).subscribe(...);
  }
}
```

**Modern equivalent** (Angular built-in since v16):
```typescript
import { DestroyRef, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

export class MyComponent {
  readonly #destroyRef = inject(DestroyRef);

  constructor() {
    someObservable$.pipe(takeUntilDestroyed(this.#destroyRef)).subscribe(...);
  }
}
```

**Why:** `takeUntilDestroyed` is Angular's own API — no third-party dependency. `DestroyRef` fires at the correct point in the component/service destruction cycle. The `@UntilDestroy()` class decorator and `untilDestroyed(this)` operator can both be removed entirely.

**Note:** `takeUntilDestroyed()` can also be called without arguments *if called inside an injection context* (constructor or field initializer). Pass `destroyRef` explicitly when calling from inside methods or effects.

---

### `implements OnDestroy` + manual `ngOnDestroy` → `DestroyRef` / `takeUntilDestroyed`

**Old pattern:**
```typescript
export class MyComponent implements OnDestroy {
  readonly #destroy$ = new Subject<void>();

  constructor() {
    someObservable$.pipe(takeUntil(this.#destroy$)).subscribe(...);
  }

  ngOnDestroy() {
    this.#destroy$.next();
    this.#destroy$.complete();
  }
}
```

**Modern equivalent:**
```typescript
export class MyComponent {
  readonly #destroyRef = inject(DestroyRef);

  constructor() {
    someObservable$.pipe(takeUntilDestroyed(this.#destroyRef)).subscribe(...);
  }
  // No ngOnDestroy needed
}
```

**Why:** ~8 lines of boilerplate reduced to 1. The `Subject`, `ngOnDestroy`, `OnDestroy` interface, and `takeUntil` can all be removed.

---

### Missing `ChangeDetectionStrategy.OnPush`

Components without `OnPush` use Angular's default change detection, which checks every component on every event (click, timer, HTTP response). This is slow and unnecessary once a component uses signal inputs — Angular's signal system is already reactive.

**Rule:** Every component with `input()`, `output()`, `model()`, `signal()`, or `computed()` should have `OnPush`. A component that is purely template-driven (no async subscriptions, no imperative mutations) can also safely get `OnPush`.

**How to add:**
```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  ...
})
```

**Prerequisite:** Before adding `OnPush`, ensure no `ChangeDetectorRef.detectChanges()` calls remain — those are workarounds for Default CD and are unnecessary with signals + `OnPush`.

---

### `toSignal()` inside repository/service files

**Old pattern (avoid):**
```typescript
// notifications.repository.ts
notificationCountSignal = toSignal(this.notificationCount$); // ← wrong place
```

**Why it's wrong:** Repositories should expose pure Observables — that is their only job. `toSignal()` creates a subscription that lives as long as the injection context (the repo/service), not the component consuming it. Components should do their own `toSignal()` if they need a signal.

**Fix:** Remove `toSignal()` from repo/service files. Let the consuming component do:
```typescript
readonly notificationCount = toSignal(this.#notificationsRepo.notificationCount$);
```

---

### `setTimeout` patterns → `afterNextRender()` / `afterRender()`

**Old pattern:**
```typescript
// Used to delay until after Angular has rendered
ngAfterViewInit() {
  setTimeout(() => {
    this.doSomethingWithDom();
    this.#cdr.detectChanges();
  }, 0);
}
```

**Modern equivalent** (Angular v17+):
```typescript
constructor() {
  afterNextRender(() => {
    this.doSomethingWithDom();
    // No cdr needed — Angular re-renders automatically after afterNextRender
  });
}
```

**Why:** `setTimeout(..., 0)` is a hack to escape the current change detection cycle. `afterNextRender()` is Angular's explicit API for "run this after the next render cycle". It is SSR-safe (does not run on the server), self-documenting, and does not require `cdr.detectChanges()`.

**Note:** Use `afterNextRender` for one-time post-render initialization. Use `afterRender` for logic that must run after every render.

---

### `ngOnInit` → constructor / field initializer / `effect()`

**Old pattern:**
```typescript
export class MyComponent implements OnInit {
  data: SomeType;

  ngOnInit() {
    this.data = this.#service.getData();
  }
}
```

**Modern equivalent:**
```typescript
export class MyComponent {
  readonly data = this.#service.getData(); // field initializer
  // OR
  readonly data = toSignal(this.#service.getData$); // if Observable
  // OR
  constructor() {
    effect(() => { /* runs when signals change */ });
  }
}
```

**Why:** `ngOnInit` was needed because injected services weren't available in the constructor in older Angular versions (before `inject()`). With `inject()`, services are available at field initialization time — no lifecycle hook needed. The remaining legitimate use case for `ngOnInit` is code that must run after `@Input()` values are set, but with `input()` signals that use case moves to `effect()` in the constructor.

**Rule of thumb:** If `ngOnInit` only reads `inject()`-able services (not `@Input()` values), move it to a field initializer or the constructor. If it reacts to inputs, use `effect()`. If nothing remains in `ngOnInit`, remove `implements OnInit` and the method.
