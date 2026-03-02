# chore(ip-sprint): IP-9 BER — Convert service BehaviorSubjects to signals, add OnPush, fix missing subscription cleanup

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-9-ber-signals-behaviorsubject-onpush-cleanup`
**Project:** BER (`accessibility-map-frontend`)
**Date:** 2026-03-02
**Difficulty:** Medium
**Estimated days:** 2

---

## Learning Objective

Apply the signal modernization skills from Stories IP-1 and IP-3 (NTM) to a different project — BER — which is at a different point in its modernization journey. The key learning difference from the NTM stories:

1. **Converting service-level `BehaviorSubject` state** — NTM stories dealt with component-level patterns. Here, the `BehaviorSubject` state lives in shared services that are `providedIn: 'root'` and consumed by multiple components. This adds the complexity of: how do consuming components adapt when a service switches from `.asObservable()` to a signal? What about components that pipe the Observable in RxJS chains?

2. **The `toObservable()` migration bridge** — When a service exposes a `signal`, components that need it as an Observable (for `combineLatest`, `switchMap`, etc.) can use `toObservable(service.mySignal)`. This bridge pattern is the key to migrating services incrementally without breaking all consumers at once.

3. **`takeUntilDestroyed()` in services vs components** — BER has subscriptions in services (specifically `map-element.ts` and `map-source.ts`) that use the old `Subject + takeUntil + onDestroy()` pattern. These are not Angular components — they are plain TypeScript classes used as map layer abstractions. This means `inject(DestroyRef)` is NOT available (it only works in injection context). Learning to recognize this and use alternative patterns is an important nuance.

4. **OnPush as a final step** — BER has great signal adoption in components but only 2/15 have OnPush. The reason is clear: the services still emit via BehaviorSubject Observables, which some components consume with `async` pipe. Once services switch to signals, components can drop `async` pipe and use signals directly — making OnPush safe to add.

---

## Learning Context

### BER's current state — very clean, targeted improvements needed

BER is the most modern of the three projects in terms of template syntax and component architecture:
- Angular 18, fully standalone
- Zero `*ngIf`/`*ngFor` — 100% `@if`/`@for`
- Zero `async` pipe in most components (signals used instead)
- `inject()` used everywhere (37 occurrences, near-zero constructor injection)
- `input()` and `output()` already used in step components

The main improvement areas are:
1. Service-level state still uses `BehaviorSubject` (accessibility-data.service, destination-data.service)
2. Only 2/15 components have OnPush
3. 3 files have subscriptions missing `takeUntilDestroyed`
4. `map-element.ts` and `map-source.ts` use the `Subject + takeUntil` destroy pattern (not in Angular injection context)

### The main target: AccessibilityDataService

File: `accessibility-map-frontend/src/app/shared/services/accessibility-data.service.ts`

This is the central shared service for the map. It currently holds state as BehaviorSubjects:

```typescript
@Injectable({ providedIn: 'root' })
export class AccessibilityDataService {
  private readonly selectedMunicipalityId = new BehaviorSubject<string | undefined>(undefined);
  selectedMunicipalityId$ = this.selectedMunicipalityId.asObservable();

  private readonly inaccessibleRoadSections = new BehaviorSubject<InaccessibleRoadSection[]>([]);
  inaccessibleRoadSections$ = this.inaccessibleRoadSections.asObservable();

  private readonly matchedRoadSection = new BehaviorSubject<InaccessibleRoadSection | undefined>(undefined);
  matchedRoadSection$ = this.matchedRoadSection.asObservable();

  private readonly _filter = new BehaviorSubject<AccessibilityFilter | undefined>(undefined);
  filter$ = this._filter.asObservable();

  showDisclaimer$ = new Subject<void>(); // Event-based, keep as Subject
}
```

The modern equivalent:

```typescript
@Injectable({ providedIn: 'root' })
export class AccessibilityDataService {
  readonly selectedMunicipalityId = signal<string | undefined>(undefined);
  readonly inaccessibleRoadSections = signal<InaccessibleRoadSection[]>([]);
  readonly matchedRoadSection = signal<InaccessibleRoadSection | undefined>(undefined);
  readonly filter = signal<AccessibilityFilter | undefined>(undefined);

  showDisclaimer$ = new Subject<void>(); // Event-based Subject — keep this, it's not state
}
```

**Migration strategy for consumers:** Any component/service that currently subscribes to `selectedMunicipalityId$` can:
- Read the signal directly: `service.selectedMunicipalityId()` (in templates or computed)
- Use `toObservable(service.selectedMunicipalityId)` if they need it in an RxJS pipeline

The `showDisclaimer$` Subject stays — it's an event stream, not state. `BehaviorSubject` is for state; `Subject` for events. Learn to distinguish these.

### Secondary target: DestinationDataService

File: `accessibility-map-frontend/src/app/shared/services/destination-data.service.ts`

```typescript
private readonly _destination = new BehaviorSubject<Position | undefined>(undefined);
destination$ = this._destination.asObservable();
```

Same pattern, same fix: `destination = signal<Position | undefined>(undefined)`.

### The map-element.ts / map-source.ts destroy pattern

Files:
- `accessibility-map-frontend/src/app/modules/map/elements/base/map-element.ts`
- `accessibility-map-frontend/src/app/modules/map/elements/base/map-source.ts`

Both have:
```typescript
protected unsubscribe = new Subject<void>();

onDestroy() {
  this.unsubscribe.next();
  this.unsubscribe.complete();
}
```

**Key constraint:** These are NOT Angular components or services. They are plain TypeScript classes used as map layer abstractions. `inject(DestroyRef)` is not available here — `inject()` only works inside Angular's dependency injection context (component/service constructor or field initializer).

**Options:**
1. Keep the `Subject + takeUntil` pattern — it's valid for non-Angular classes, just boilerplate
2. Convert to a `DestroyRef`-like manual approach where callers pass in a destroy callback
3. If these classes ARE constructed inside an Angular injection context (e.g., inside a service constructor), they could receive a `DestroyRef` as a constructor parameter

Read the actual files to understand how `map-element.ts` and `map-source.ts` are instantiated. If they're constructed inside a service/component (inside injection context), option 3 is elegant. If not, option 1 is pragmatic and fine.

**Important:** Don't over-engineer this. The `Subject + takeUntil + onDestroy` pattern is not "wrong" for plain TypeScript classes — it's the only option. The main improvement is documenting WHY inject(DestroyRef) doesn't work here, which is itself a valuable learning.

### The 3 files with missing subscription cleanup

From the audit:

1. **`step-three.component.ts`** — `ngOnInit` subscription to `vehicleLoadControl.valueChanges` with no cleanup:
   ```typescript
   ngOnInit() {
     this.vehicleLoadControl.valueChanges.subscribe((value) => {
       this.vehicleTotalWeightControl.patchValue((value ?? 0) + (this.vehicleInfo()?.weight ?? 0));
     });
   }
   ```
   Fix: `private destroyRef = inject(DestroyRef)` + `.pipe(takeUntilDestroyed(this.destroyRef))`
   Better: Convert entirely to a `computed()` signal that derives the total weight from `vehicleLoadControl` value + `vehicleInfo()`. Reactive forms work with signals via `toSignal(this.vehicleLoadControl.valueChanges)`.

2. **`user-vehicle-summary.component.ts`** — 2 subscriptions without cleanup. Read the file to find the specific subscriptions and apply `takeUntilDestroyed`.

3. **`form-control-validation.component.ts`** — already uses `untilDestroyed(this)` from `@ngneat/until-destroy` (which is fine, but inconsistent with the `takeUntilDestroyed` pattern used elsewhere). Leave as-is — mixing cleanup approaches is lower priority.

### Adding OnPush after service signals

Once `AccessibilityDataService` exposes signals instead of Observables:
- Components can drop `| async` pipe from template expressions
- With no more Observable subscription management needed, OnPush is safe to add
- `ChangeDetectionStrategy.OnPush` should be added to all components that:
  - Only receive data via `input()` signals
  - Read service state via signals (not subscriptions)
  - Use `toSignal()` for any remaining Observables

Target components for OnPush in this story: the components that directly consume `AccessibilityDataService` signals. Read those component files to confirm they don't have hidden mutable state.

---

## Analysis

### Files to change

| File | Action |
|------|--------|
| `src/app/shared/services/accessibility-data.service.ts` | Convert 4 BehaviorSubjects to `signal()`, keep `showDisclaimer$` Subject |
| `src/app/shared/services/destination-data.service.ts` | Convert `_destination` BehaviorSubject to `signal()` |
| All consumers of `selectedMunicipalityId$`, `inaccessibleRoadSections$`, etc. | Update to read signal directly or via `toObservable()` |
| `src/app/modules/data-input/step-three/step-three.component.ts` | Add `takeUntilDestroyed` or convert to `toSignal` + computed |
| `src/app/modules/map/components/user-vehicle/summary/user-vehicle-summary.component.ts` | Add `takeUntilDestroyed` to 2 subscriptions |
| Components consuming service signals (verify which ones) | Add `changeDetection: ChangeDetectionStrategy.OnPush` |

### What NOT to change

- `showDisclaimer$ = new Subject<void>()` — this is an event stream, not state, keep it
- `map-element.ts` and `map-source.ts` destroy pattern — acceptable for non-Angular classes; document the reason
- `form-control-validation.component.ts` cleanup pattern — already handled, different library, low priority

### Watch out for

- Property naming: BehaviorSubject was `private selectedMunicipalityId` exposed as `selectedMunicipalityId$`. With signals, the naming convention is just `selectedMunicipalityId` (the signal is the public property, no `$` suffix). Search all consumers for `selectedMunicipalityId$` and update to `selectedMunicipalityId()`.
- Components that use the service Observable in a `combineLatest` or `switchMap` pipeline — these need `toObservable()` from `@angular/core/rxjs-interop`
- The `filter$` BehaviorSubject: `filter` is a common JavaScript keyword — renaming to `filter = signal()` is fine since it's a class property, not a global. But verify no naming collisions.

### Acceptance criteria

- `AccessibilityDataService`: 4 BehaviorSubjects replaced with `signal()`, `showDisclaimer$` Subject preserved
- `DestinationDataService`: BehaviorSubject replaced with `signal()`
- All consumers updated: `selectedMunicipalityId$` → `selectedMunicipalityId()`, etc.
- `step-three.component.ts` subscription has `takeUntilDestroyed` or is replaced with `toSignal` + computed
- `user-vehicle-summary.component.ts`: both subscriptions have cleanup
- Target components that fully use signals have `changeDetection: ChangeDetectionStrategy.OnPush`
- Build passes, 0 TypeScript errors
- Manual test: map loads, municipality selection works, vehicle form submits correctly

---

## Implementation Plan

### Phase 1: Migrate AccessibilityDataService

Read the full service file. Map all 4 BehaviorSubject properties. Find all consumers (grep for `selectedMunicipalityId$`, `inaccessibleRoadSections$`, `matchedRoadSection$`, `filter$`). Convert the service first. Then update consumers one by one — either to direct signal reads or `toObservable()` where needed.

WIP commit after Phase 1.

### Phase 2: Migrate DestinationDataService

Smaller scope. Same approach. Find consumers of `destination$`, update them.

WIP commit after Phase 2.

### Phase 3: Fix missing subscription cleanup

Read `step-three.component.ts` and `user-vehicle-summary.component.ts`. Add `takeUntilDestroyed` to the uncleaned subscriptions. For `step-three`, evaluate whether the `valueChanges` subscription can be eliminated entirely with `toSignal(this.vehicleLoadControl.valueChanges)` + a `computed()` for the derived weight value.

WIP commit after Phase 3.

### Phase 4: Add OnPush to qualifying components

Identify which components now fully use signals (either directly via `input()`/`signal()` or via `toSignal()`). Add `changeDetection: ChangeDetectionStrategy.OnPush` to each. Build and manually test the map, vehicle form, and data input steps.

WIP commit after Phase 4.
