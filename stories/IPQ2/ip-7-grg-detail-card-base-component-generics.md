# chore(ip-sprint): IP-7 Extract GenericRestrictionDetailsComponent base class for 11 duplicate detail cards

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-7-grg-detail-card-base-component-generics`
**Project:** GRG (`traffic-sign-frontend`)
**Date:** 2026-03-02
**Difficulty:** Hard
**Estimated days:** 3

---

## Learning Objective

Apply abstract base class design to **Angular components** specifically — not just services. This is more nuanced than Story IP-5 (which dealt with plain injectable services) because Angular components have:

- A `@Component` decorator with `imports: []`, `templateUrl`, `styleUrl`, `selector` — none of which can be inherited
- Lifecycle hooks that may need coordinating between base and child
- Template bindings that must match the component's own public API
- The Angular compiler's awareness of the component tree — a base class component does not participate in Angular's component tree on its own

Key concepts to learn:

1. **Abstract component base classes in Angular** — how `abstract class BaseComponent` works with Angular components: the base class typically has NO `@Component` decorator; only concrete subclasses do. The base class holds shared TypeScript logic (signals, computed, methods, injections) while each subclass provides its own template and decorator.

2. **Generic TypeScript with Angular signals** — parameterizing `toSignal()` pipelines over a generic feature type `T` while keeping full TypeScript inference. Understand where type inference fails and where explicit type parameters are needed.

3. **Shared `imports: []` constants** — Angular allows you to define a `const SHARED_IMPORTS = [ComponentA, DirectiveB, ...]` array and spread it into a component's `imports`. This eliminates the repetition of 8 identical imports across 11 files.

4. **Spotting and fixing a real naming bug** — `LengthRestrictionDetailsComponent` has a signal named `axleLoadRestrictionFeatures` (wrong domain name) that is used throughout the class. This is a silent bug that compiles fine but is semantically wrong. Part of this story is identifying and fixing it.

---

## Learning Context

### The duplication: 11 detail card components with 95% identical logic

Under `traffic-sign-frontend/src/app/modules/road-feature/components/overview/detail-cards/` there are 11 components that share virtually the same TypeScript class body. The components are:

- `axle-load-restriction-details.component.ts`
- `height-restriction-details.component.ts`
- `length-restriction-details.component.ts`
- `load-restriction-details.component.ts`
- `road-narrowing-details.component.ts`
- `rvm-details.component.ts` (slight variation — no `isMutation` check)
- `road-category-details.component.ts`
- `traffic-type-details.component.ts`
- `school-zone-details.component.ts` (more significant variation — see below)
- `hgv-charge-details.component.ts` (uses a `getFeaturesResource()` pattern — different, see below)
- `speed-limit-details.component.ts` (most complex — multiple features, proposals, drawing — do NOT include in base class)

All of the "simple" ones follow this exact structure (height restriction shown as example):

```typescript
@Component({
  selector: 'app-height-restriction-details',
  standalone: true,
  imports: [AsyncPipe, FeatureTitleComponent, LoadingComponent, SidePanelCardComponent, ...],
  templateUrl: './height-restriction-details.component.html',
  styleUrl: './height-restriction-details.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HeightRestrictionDetailsComponent extends DetailsBaseComponent {
  readonly #heightRestrictionService = inject(HeightRestrictionService);

  mapElement = MapElementEnum.HeightRestriction;
  featureVersion$ = this.#heightRestrictionService.version$;

  heightRestrictionFeatures = toSignal(
    combineLatest([this.isMutation$, this.roadSectionId$]).pipe(
      switchMap(([isMutation, roadSectionId]) =>
        !isMutation
          ? this.#heightRestrictionService.getFeaturesForRoadSection(roadSectionId)
          : this.#heightRestrictionService.findMutation(roadSectionId).pipe(
              map((mutations) =>
                mutations.map((mutation) => ({
                  id: roadSectionId,
                  properties: { ...(mutation as Partial<HeightRestrictionProperties>), restrictionValue: mutation.restrictionValue },
                }) as HeightRestrictionFeature),
              ),
            ),
      ),
      map((features) => [...features].sort((a, b) => a.properties?.from - b.properties?.from)),
      map((features) => ({ value: features, error: undefined })),
      catchError((err) => of({ value: undefined, error: err })),
    ),
  );

  dataError = computed(() => this.heightRestrictionFeatures()?.error?.message);
  features = computed(() => {
    const value = this.heightRestrictionFeatures()?.value;
    if (value) {
      this.featureDetails.emit(value.map((f) => String(f.properties.restrictionValue)));
    }
    return value;
  });
  noFeaturesAvailable = computed(() => this.heightRestrictionFeatures()?.value?.length === 0);
  multipleFeaturesAvailable = computed(() => (this.heightRestrictionFeatures()?.value?.length || 0) > 1);
}
```

The only differences between the 8 "simple" components:
1. The injected service name and type
2. The `MapElementEnum` value
3. The `featureVersion$` source (same pattern, different service)
4. The property name in `featureDetails.emit()` (e.g. `restrictionValue`, `brin6`, `from`, etc.)

### The naming bug in LengthRestrictionDetailsComponent

`length-restriction-details.component.ts` line 38 has:

```typescript
axleLoadRestrictionFeatures = toSignal(  // ← WRONG DOMAIN NAME
  combineLatest([this.isMutation$, this.roadSectionId$]).pipe(
    switchMap(([isMutation, roadSectionId]) =>
      !isMutation
        ? this.#lengthRestrictionService.getFeaturesForRoadSection(roadSectionId)  // ← correct service
```

The signal is named `axleLoadRestrictionFeatures` but it serves the **length restriction** domain. Lines 63, 64, 71, and 72 reference this wrong name. It compiles fine because TypeScript doesn't know about domain semantics, only types. This is a copy-paste bug that was never caught.

Fixing this is part of Phase 1 of this story — before extracting the base class, fix the naming so the extraction is clean.

### The service interface that must exist for generics to work

For the base class to work generically, all services must share a common interface:

```typescript
interface RestrictionFeatureService<TFeature, TMutation> {
  getFeaturesForRoadSection(roadSectionId: number): Observable<TFeature[]>;
  findMutation(roadSectionId: number): Observable<TMutation[]>;
  version$: Observable<number>; // or whatever version$ type is
}
```

Read the actual service files to determine the exact method signatures. The interface may not exist yet and may need to be created.

### What goes in the base class vs what stays in the subclass

**In the abstract base class:**
- The `toSignal(combineLatest(...).pipe(...))` pipeline (parameterized over `T`)
- `dataError = computed(...)`, `noFeaturesAvailable = computed(...)`, `multipleFeaturesAvailable = computed(...)`
- The `features = computed(...)` that calls `featureDetails.emit(...)` — but the emit value depends on a property key, which must be provided by the subclass as an abstract getter

**In each concrete subclass:**
- `@Component({ ... })` decorator (cannot be inherited)
- `inject(ConcreteService)`
- `mapElement = MapElementEnum.ConcreteValue`
- `featureVersion$ = this.service.version$`
- The abstract getter for which property to emit (e.g. `'restrictionValue'`)

### The shared imports constant

All detail card components import the same 8 things. Create a shared constant:

```typescript
// In detail-cards/detail-card-imports.ts (new file)
export const DETAIL_CARD_BASE_IMPORTS = [
  AsyncPipe,
  FeatureTitleComponent,
  LoadingComponent,
  SidePanelCardComponent,
  SidePanelCardContentComponent,
  SidePanelCardHeaderComponent,
  TooltipDirective,
] as const;
```

Then each component uses `imports: [...DETAIL_CARD_BASE_IMPORTS, SpecificPipeA, SpecificPipeB]`.

### Components to EXCLUDE from the base class

- `speed-limit-details` — much more complex (multiple features, proposals, drawing state). Leave it as-is.
- `hgv-charge-details` — uses a `getFeaturesResource()` pattern that returns Angular's Resource API (`.error()`, `.value()`). This is actually a MORE modern pattern. Leave it as-is and document it as "this component uses the Resource API — investigate this pattern separately."
- `school-zone-details` — has a `BehaviorSubject` trigger, a manual constructor, and `ngOnDestroy`. It should be cleaned up separately before being included in the base class migration.

### Scope for this story: migrate 3 of 8 simple components

Same as IP-5: prove the base class works with 3 migrations, mark the rest with `// TODO`.

Best candidates for migration (simplest, most representative):
- `height-restriction-details` — clean, representative example
- `length-restriction-details` — also gets the naming bug fixed
- `load-restriction-details` — similar structure, confirms base class works for multiple types

---

## Analysis

### Files to create

| File | Purpose |
|------|---------|
| `src/app/modules/road-feature/components/overview/detail-cards/detail-card-imports.ts` | Shared `DETAIL_CARD_BASE_IMPORTS` constant |
| `src/app/modules/road-feature/components/overview/detail-cards/restriction-details-base.component.ts` | Abstract base class with shared `toSignal` pipeline |

### Files to modify

| File | Action |
|------|--------|
| `length-restriction-details.component.ts` | Fix `axleLoadRestrictionFeatures` naming bug first, then migrate to base |
| `height-restriction-details.component.ts` | Migrate to base class |
| `load-restriction-details.component.ts` | Migrate to base class |
| Remaining 5 simple detail card `.component.ts` files | Add `// TODO: migrate to RestrictionDetailsBaseComponent` comment |

### Research needed before starting

- Read `details-base.component.ts` to understand what `DetailsBaseComponent` already provides (`isMutation$`, `roadSectionId$`, `featureDetails` output, `destroyRef`)
- Read 3 actual service files (e.g. `height-restriction.service.ts`) to confirm method signatures: does `getFeaturesForRoadSection` and `findMutation` exist on all of them with compatible signatures?
- Read `hgv-charge-details.component.ts` to understand the Resource API pattern — document it in a code comment so it's not confused with the base class approach
- Confirm whether `version$` exists on all services and what its type is

### Acceptance criteria

- Naming bug in `length-restriction-details.component.ts` fixed (`axleLoadRestrictionFeatures` → `lengthRestrictionFeatures`)
- `DETAIL_CARD_BASE_IMPORTS` constant created and works as a spread in component `imports: []`
- `RestrictionDetailsBaseComponent<T, TMutation>` abstract class exists with the shared `toSignal` pipeline
- 3 migrated components each extend the base, have no duplicate signal/computed logic, and are each under 30 lines of class body
- The remaining 5 simple components have `// TODO: migrate to RestrictionDetailsBaseComponent` comments
- Build passes with 0 TypeScript errors under strict mode
- UI: all 3 migrated detail cards render correctly and show feature data

---

## Implementation Plan

### Phase 1: Fix the naming bug

Go to `length-restriction-details.component.ts`. Rename `axleLoadRestrictionFeatures` to `lengthRestrictionFeatures` everywhere in the file (signal declaration + all computed references). Run `npm run build` to confirm the fix doesn't introduce errors.

WIP commit after Phase 1.

### Phase 2: Create the shared imports constant

Create `detail-card-imports.ts`. Identify the 8 imports common to all detail card components (read 3 different component files to confirm the exact list). Export the constant. Do NOT apply it to any components yet — that comes in Phase 3 alongside the base class.

### Phase 3: Write RestrictionDetailsBaseComponent

Create `restriction-details-base.component.ts`. Define the `RestrictionFeatureService<T, TMutation>` interface (or use structural typing). Write the abstract base class extending `DetailsBaseComponent`. Implement the shared `toSignal` pipeline generically. Define abstract getters/properties that each subclass must provide (the service, the property key to emit, the `MapElementEnum` value). Work through TypeScript generic errors carefully.

WIP commit after Phase 3.

### Phase 4: Migrate 3 components

Migrate `height-restriction-details`, `length-restriction-details`, and `load-restriction-details` to extend `RestrictionDetailsBaseComponent`. Apply `DETAIL_CARD_BASE_IMPORTS` spread to their `imports: []`. Run `npm run build` after each one. Manually test each in the browser.

Add `// TODO` comments to the remaining 5 simple components.

WIP commit after Phase 4.
