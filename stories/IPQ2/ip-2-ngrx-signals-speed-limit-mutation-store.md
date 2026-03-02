# chore(ip-sprint): IP-2 Migrate SpeedLimitMutationRepository to @ngrx/signals signalStore

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-2-ngrx-signals-speed-limit-mutation-store`
**Project:** GRG (`traffic-sign-frontend`)
**Date:** 2026-03-02
**Difficulty:** Medium
**Estimated days:** 2

---

## Learning Objective

Learn `@ngrx/signals` at real-world complexity:

- **`signalStore()`** — the top-level factory that creates a signal-based store class
- **`withState()`** — defining the initial state shape and getting auto-generated signals for each state slice
- **`withMethods()`** — adding methods to the store that can read state (via the store instance) and write state (via `patchState()`)
- **`patchState()`** — the immutable state updater; understand why it's safer than direct mutation
- **`withComputed()`** — defining derived state as computed signals that update automatically when their dependencies change
- **`rxMethod()`** — bridging RxJS Observables into the signal world for async operations (e.g. HTTP calls that need to flow into store state)
- **`tapResponse()`** — the `@ngrx/operators` utility for safe error handling in `rxMethod` pipelines

Understand **why `@ngrx/signals` beats `@ngneat/elf` for new code** in this codebase:
- No `createStore()` module-level singleton that must be created before the service is instantiated
- No `untilDestroyed()` workarounds (signal stores handle lifecycle automatically)
- No `selectAllEntities()` plumbing — just `computed()` signals
- Built into the Angular ecosystem, consistent with Angular's own signal APIs
- First-class TypeScript inference throughout

---

## Learning Context

### The mixed state management problem in GRG

GRG's `traffic-sign-frontend` currently uses **three different state management patterns simultaneously**:

1. **`@ngrx/signals` `signalStore`** — Only one example exists: `src/app/store/info-messages.store.ts`. This is the newest pattern and the intended future direction.

2. **`@ngneat/elf`** — Used in the 13 mutation repositories under `src/app/modules/road-feature/state/`. Elf uses `createStore()` + `withEntities()` to create reactive entity stores. It's a good library but is not Angular-native, requires more boilerplate, and creates friction when mixing with Angular's signal APIs.

3. **`BehaviorSubject`** — Still present in `src/app/app.component.ts` (`organizationIdBS = new BehaviorSubject<string | undefined>(undefined)`). Legacy pattern, should be phased out.

This story picks the clearest, most self-contained elf-based repository and rewrites it as a `signalStore`. The result becomes the **reference implementation** for the remaining 12 mutation repositories.

### The existing @ngrx/signals reference: InfoMessagesStore

File: `src/app/store/info-messages.store.ts`

Read this file thoroughly before starting. It shows:
- How `signalStore({ providedIn: 'root' }, ...)` creates an injectable store
- How `withState<InfoMessagesState>({ infoMessages: [] })` defines initial state
- How `withMethods((store) => ({ ... }))` adds methods that call `patchState(store, { infoMessages: [...] })`
- How `withComputed((store) => ({ ... }))` derives signals from state

This is your map. The goal of Story IP-2 is to apply the same pattern to mutation entity management.

### The target: SpeedLimitMutationRepository

File: `src/app/modules/road-feature/state/speed-limit-mutation.repository.ts`

This elf-based repository is the best migration candidate because:
- It is ~72 lines — small enough to understand fully
- It is used heavily by `SpeedLimitDetailsComponent`, which you'll encounter again in Story IP-5
- It has the full range of entity operations: `setMutations` (replace all), `addMutations` (append/update), `deleteMutation` (remove by predicate) — so you'll learn how to implement each with `patchState`
- It also has a `mapFeatureToMutation` helper function that can be cleanly extracted as a standalone pure function

### What the elf-based repository looks like

The current pattern across all 13 mutation repositories:

```typescript
// 1. A module-level store creation (outside the class)
const { state, config } = createState(withEntities<SpeedLimitMutation>());
const store = createStore({ name: 'speed-limit-mutation' }, withEntities<SpeedLimitMutation>());

// 2. An injectable service wrapping the store
@Injectable({ providedIn: 'root' })
export class SpeedLimitMutationRepository {
  get mutations(): SpeedLimitMutation[] {
    return getAllEntities()({ ref: store.state });
  }

  mutations$ = store.pipe(selectAllEntities());

  mutationsAsFeatureCollection$: Observable<FeatureCollection> = this.mutations$.pipe(
    map((mutations) => featureCollection(mutations.map((m) => m.asGeoJsonFeature())))
  );

  setMutations(mutations: SpeedLimitMutation[]): void {
    store.update(setEntities(mutations));
  }

  addMutations(mutations: SpeedLimitMutation[]): void {
    const roadSectionIds = mutations.map((m) => m.properties.roadSectionId);
    store.update(
      deleteEntitiesByPredicate((m) => roadSectionIds.includes(m.properties.roadSectionId)),
      addEntities(mutations)
    );
  }

  deleteMutation(roadSectionId: number): void {
    store.update(deleteEntitiesByPredicate((m) => m.properties.roadSectionId === roadSectionId));
  }
}
```

### What the signalStore version should look like (design target)

```typescript
// No module-level store creation — the signalStore IS the injectable

type SpeedLimitMutationState = {
  mutations: SpeedLimitMutation[];
};

export const SpeedLimitMutationStore = signalStore(
  { providedIn: 'root' },
  withState<SpeedLimitMutationState>({ mutations: [] }),
  withComputed((store) => ({
    mutationsAsFeatureCollection: computed(() =>
      featureCollection(store.mutations().map((m) => m.asGeoJsonFeature()))
    ),
  })),
  withMethods((store) => ({
    setMutations(mutations: SpeedLimitMutation[]): void {
      patchState(store, { mutations });
    },
    addMutations(mutations: SpeedLimitMutation[]): void {
      const roadSectionIds = mutations.map((m) => m.properties.roadSectionId);
      patchState(store, (state) => ({
        mutations: [
          ...state.mutations.filter((m) => !roadSectionIds.includes(m.properties.roadSectionId)),
          ...mutations,
        ],
      }));
    },
    deleteMutation(roadSectionId: number): void {
      patchState(store, (state) => ({
        mutations: state.mutations.filter((m) => m.properties.roadSectionId !== roadSectionId),
      }));
    },
  }))
);
```

Notice:
- `mutations$` Observable becomes `store.mutations()` signal — consumers read it as a signal, not a stream
- `mutationsAsFeatureCollection$` becomes a `computed()` signal in `withComputed`
- No `getAllEntities()`, no `selectAllEntities()`, no elf imports at all
- The class name changes from `SpeedLimitMutationRepository` to `SpeedLimitMutationStore` — naming convention matches `InfoMessagesStore`
- `mapFeatureToMutation` is extracted as a standalone `export function mapFeatureToMutation(...)` in the same file or a nearby utils file

### Impact on consumers

Any component or service that currently injects `SpeedLimitMutationRepository` and uses `mutations$` as an Observable will need minor updates:
- `mutations$` → use `store.mutations()` directly in template (it's a signal, no async pipe needed) or wrap with `toObservable()` if a stream is needed
- Method calls (`setMutations`, `addMutations`, `deleteMutation`) are unchanged — same API
- The store is still `providedIn: 'root'`, so injection works identically

### Key files to read before starting

- `src/app/store/info-messages.store.ts` — the reference signalStore implementation
- `src/app/modules/road-feature/state/speed-limit-mutation.repository.ts` — the migration target
- Any component that injects `SpeedLimitMutationRepository` (search for it) — understand what API they depend on

---

## Analysis

### Files to change

| File | Action |
|------|--------|
| `src/app/modules/road-feature/state/speed-limit-mutation.repository.ts` | Full rewrite as `signalStore` |
| Any component/service injecting `SpeedLimitMutationRepository` | Update to inject `SpeedLimitMutationStore`, update Observable usages to signal usages |

### What the store does not need

- `rxMethod()` and `tapResponse()` — these are for async operations (HTTP calls that load data into the store). This particular store is written-to by other services (the elf pattern separates HTTP from state). The store itself only holds state and provides methods to update it. Therefore this story does not require `rxMethod()`. *(Story IP-5 may introduce async methods when building the generic base — see that story.)*

### Key concepts to research before starting

- `@ngrx/signals` documentation: `signalStore`, `withState`, `withMethods`, `withComputed`, `patchState`
- How `patchState(store, { key: value })` works vs `patchState(store, (state) => ({ key: derivedValue }))`
- How signals exposed by `withState` are read: `store.mutations()` (it's a function call, not a property)
- How `withComputed` signals are typed and accessed
- Migration path from Observable-based consumers to signal-based consumers

### Acceptance criteria

- File renamed/rewritten: `SpeedLimitMutationStore` (not `SpeedLimitMutationRepository`) implemented as `signalStore`
- `mutations` exposed as a signal (via `withState` — accessed as `store.mutations()`)
- `mutationsAsFeatureCollection` exposed as a `computed` signal (via `withComputed`)
- `setMutations`, `addMutations`, `deleteMutation` implemented as `withMethods` using `patchState`
- `mapFeatureToMutation` extracted as a standalone exported pure function
- No elf imports (`@ngneat/elf`, `@ngneat/elf-entities`) remain in this file
- All consumers compile with no TypeScript errors
- Build passes

---

## Implementation Plan

### Phase 1: Read and understand the reference implementation

Read `info-messages.store.ts` fully. Map each pattern to its `@ngrx/signals` API. Read the elf-based `speed-limit-mutation.repository.ts` and understand the full API surface it exposes to consumers. Search the codebase for all files that inject `SpeedLimitMutationRepository` — list them.

No code changes in this phase. This is research.

### Phase 2: Write the new signalStore

Create the new `signalStore` implementation in the existing file. Keep the old code commented out above it for reference while working. Define `SpeedLimitMutationState`, implement `withState`, `withComputed`, and `withMethods`. Extract `mapFeatureToMutation` as a standalone function.

WIP commit after Phase 2.

### Phase 3: Update all consumers

Find all files that inject `SpeedLimitMutationRepository`. Update each one:
- Change injection token to `SpeedLimitMutationStore`
- Change any `.mutations$` Observable usage to `.mutations()` signal (or wrap with `toObservable()` where an Observable is truly needed)
- Method calls (`setMutations`, `addMutations`, `deleteMutation`) likely work unchanged
- Remove `async` pipe usages in templates if the signal is used directly

WIP commit after Phase 3.

### Phase 4: Clean up and verify

Remove the old commented-out elf code. Remove the elf imports. Run `npm run build` from the `traffic-sign-frontend` directory. Confirm 0 TypeScript errors. Manually verify the speed limit mutations feature works in the browser.

WIP commit after Phase 4.
