# chore(signals): #110901 migrate remaining inputs and outputs to signal variants (GRG)

**Story:** #110901
**Branch:** `chore/110901/migrate-remaining-inputs-outputs-to-signal-variants-grg`
**Date:** 2026-03-04

---

## Story — Original Text

### Description

GRG [FE] overgebleven inputs en outputs migreren naar signal variants

### Acceptance Criteria

(Not provided in Azure DevOps — derived from IPQ2 research file IP-8)

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

This story modernizes the GRG (`traffic-sign-frontend`) by replacing old Angular patterns with signal-based equivalents. It follows the scope of IPQ2 research file **IP-8** (`ip-8-grg-modernize-old-angular-patterns.md`).

### What old patterns exist today (from IP-8 research)

**Pattern 1 — `BehaviorSubject` as `@Input` bridge in `DetailsBaseComponent`:**
```typescript
// OLD: Manual sync from @Input to BehaviorSubject in ngOnInit
@Input() isMutation = false;
isMutation$ = new BehaviorSubject(false);
ngOnInit() { this.isMutation$.next(this.isMutation); }
```
This existed because `@Input()` was never reactive before Angular 17. Now replaced by `input()` signal + `toObservable()`.
- **File:** `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/details-base/details-base.component.ts`
- **Impact:** Base class extended by **11+ child components** — all consume `this.isMutation$` in `combineLatest` chains

**Pattern 2 — `BehaviorSubject` wrapping a `toSignal()` (double pattern):**
```typescript
// OLD: completely redundant
filterActiveRoadAuthority$: BehaviorSubject<boolean> = new BehaviorSubject<boolean>(false);
filterActiveRoadAuthority = toSignal(this.filterActiveRoadAuthority$);
```
Direct `signal(false)` is the correct pattern — no BehaviorSubject needed.
- **File:** `traffic-sign-frontend/src/app/modules/road-feature/components/overview/mutations-table/abstract-mutations-table.component.ts`

**Pattern 3 — Manual `ngOnDestroy` for Subject cleanup:**
```typescript
// OLD: boilerplate per component
triggerVerificationsUpdate = new BehaviorSubject<void>(undefined);
ngOnDestroy() { this.triggerVerificationsUpdate.complete(); }
```
`DestroyRef` + `takeUntilDestroyed()` replaces this completely.
- **File:** `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/school-zone-details/school-zone-details.component.ts`

**Pattern 4 — `BehaviorSubject` as mutable state in `AppComponent`:**
```typescript
// OLD
organizationIdBS = new BehaviorSubject<string | undefined>(undefined);
```
Replace with `signal<string | undefined>(undefined)`. All `.next()` → `.set()`, `.asObservable()` → `toObservable()`.
- **File:** `traffic-sign-frontend/src/app/app.component.ts`

### What NOT to change in this story

- `RoadCategoryRepository` and `SpeedLimitRepository` — constructor subscriptions with `combineLatest + takeUntilDestroyed` are already correct modern patterns
- Services using `BehaviorSubject` for HTTP caching with `shareReplay` — different pattern, separate story
- Any `BehaviorSubject` with external subscribers outside the class — needs careful assessment first

### Key risk: DetailsBaseComponent blast radius

`DetailsBaseComponent` is extended by **11+ child components**. Changing `isMutation$` from `BehaviorSubject<boolean>` to `Observable<boolean>` (via `toObservable()`) keeps the same type, so `combineLatest` calls in children compile unchanged. But search all children for direct reads of `this.isMutation` (plain property) → those become `this.isMutation()` (signal read) after migration.

### Scope decision

Holistic cleanup included — also survey for remaining BehaviorSubject bridges and missing `takeUntilDestroyed` in components touched by this story.

---

## Implementation Plan

### Phase 1: Fix AbstractMutationsTableComponent (simplest change)

**File:** `traffic-sign-frontend/src/app/modules/road-feature/components/overview/mutations-table/abstract-mutations-table.component.ts`

**Changes:**
- Remove `filterActiveRoadAuthority$: BehaviorSubject<boolean>` field
- Remove `filterActiveRoadAuthority = toSignal(this.filterActiveRoadAuthority$)` field
- Replace both with: `filterActiveRoadAuthority = signal(false)`
- All `.next(true/false)` callers → `.set(true/false)` or `.update(v => !v)`
- Remove `BehaviorSubject` import if no longer used

**Verify:** `npm run build` from `traffic-sign-frontend/`. Test mutations table filter toggle.

WIP commit after Phase 1.

### Phase 2: Fix DetailsBaseComponent base class

**File:** `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/details-base/details-base.component.ts`

**Before changing:** Read the full file + 2-3 child classes. Map all uses of `isMutation$` and `isMutation`.

**Changes:**
- Replace `@Input() isMutation = false` with `isMutation = input(false)`
- Replace `isMutation$ = new BehaviorSubject(false)` with `isMutation$ = toObservable(this.isMutation)`
- Remove `ngOnInit()` if its only content was the `BehaviorSubject.next()` sync (check carefully for other logic)
- Find all child class reads of `this.isMutation` as a plain property → update to `this.isMutation()` (signal read)
- `combineLatest([this.isMutation$, ...])` chains in children compile unchanged (type stays `Observable<boolean>`)

**Imports:** Add `input` from `@angular/core`, `toObservable` from `@angular/core/rxjs-interop`. Remove `@Input`, `BehaviorSubject`.

**Verify:** `npm run build` — watch for child class errors. Fix any `this.isMutation` → `this.isMutation()` in children.

WIP commit after Phase 2.

### Phase 3: Fix SchoolZoneDetailsComponent

**File:** `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/school-zone-details/school-zone-details.component.ts`

**Changes:**
- Remove `ngOnDestroy()` method entirely
- Ensure `triggerVerificationsUpdate` pipeline has `takeUntilDestroyed(this.#destroyRef)` — no explicit `.complete()` needed
- If `triggerVerificationsUpdate` is `BehaviorSubject` and the initial emission is unnecessary, convert to plain `Subject<void>`
- Simplify constructor if it only chains to `super()` and calls a method that could be a field initializer
- Verify `readonly #destroyRef = inject(DestroyRef)` is present

**Verify:** `npm run build`. Test school zone details card — verifications load and update correctly.

WIP commit after Phase 3.

### Phase 4: Fix AppComponent BehaviorSubject

**File:** `traffic-sign-frontend/src/app/app.component.ts`

**Changes:**
- Replace `organizationIdBS = new BehaviorSubject<string | undefined>(undefined)` with `organizationId = signal<string | undefined>(undefined)`
- All `.next(value)` → `.set(value)`
- All `.asObservable()` → `toObservable(this.organizationId)` where Observable is needed, or read signal directly
- All `.getValue()` → `this.organizationId()` (signal read)
- Remove `BehaviorSubject` import if no longer used

**Verify:** `npm run build`. Test organization selection flow throughout the app.

WIP commit after Phase 4.

### Phase 5: Holistic cleanup — survey remaining BehaviorSubject bridges + takeUntilDestroyed gaps

Scan touched components for:
1. Remaining `BehaviorSubject` acting as pure state holder (no external subscribers) — convert to `signal()`
2. `.subscribe()` calls missing `takeUntilDestroyed()` — add it

**Verify:** `npm run build` — 0 errors.

WIP commit after Phase 5.

---

## Reference

- IPQ2 research: `ip-8-grg-modernize-old-angular-patterns.md`
- Related GRG IPQ2 stories (future work): IP-2 (NgRx Signals store), IP-4 (@defer), IP-5 (BaseMutationRepository), IP-7 (detail card base generics)
