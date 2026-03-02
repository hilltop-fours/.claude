# chore(ip-sprint): IP-5 Extract BaseMutationRepository<T> to eliminate boilerplate in 13 elf repositories

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-5-grg-base-mutation-repository-generics`
**Project:** GRG (`traffic-sign-frontend`)
**Date:** 2026-03-02
**Difficulty:** Hard
**Estimated days:** 3

---

## Learning Objective

Learn advanced TypeScript generics in a real Angular service context:

1. **Generic base classes with type constraints** — writing `abstract class BaseMutationRepository<T extends SomeConstraint>` and understanding how TypeScript enforces the constraint at the call site, how methods in the base class can use the generic type `T`, and what "type-safe generics" actually means in practice when working with entity shapes

2. **`abstract` classes vs. factory functions** — understanding when to use an abstract class (shared methods + forced extension) vs. a factory function (pure composition, no inheritance). This story uses the abstract class approach to match the architectural convention already visible in NTM (`BaseRepository`), but you'll understand the trade-off

3. **TypeScript strict mode challenges with generics** — encountering and solving real type errors that come up when a base class tries to reference generic type parameters inside elf's `createStore`, `withEntities`, and entity predicate functions. This is where the real learning is: generics in theory vs. generics under `strict: true`

4. **Recognizing and eliminating structural duplication** — the 13 mutation repositories are the textbook definition of code duplication: identical structure, only the type changes. Understanding how to identify this pattern and extract it correctly is a core software design skill that applies well beyond Angular

---

## Learning Context

### The duplication problem: 13 identical files

Under `traffic-sign-frontend/src/app/modules/road-feature/state/` there are 13 files following this exact structure:

```
axle-load-restriction-mutation.repository.ts
carriageway-type-mutation.repository.ts
driving-direction-mutation.repository.ts
height-restriction-mutation.repository.ts
hgv-charge-mutation.repository.ts
length-restriction-mutation.repository.ts
load-restriction-mutation.repository.ts
road-authority-mutation.repository.ts
road-category-mutation.repository.ts
road-narrowing-mutation.repository.ts
rvm-mutation.repository.ts
school-zone-mutation.repository.ts
traffic-type-mutation.repository.ts
```

(Note: `speed-limit-mutation.repository.ts` was migrated to `@ngrx/signals` in Story IP-2 and is no longer elf-based — so it is excluded here.)

Each of these files is structurally identical. Here is a representative example — they all look like this:

```typescript
import { Injectable } from '@angular/core';
import { addEntities, deleteEntitiesByPredicate, selectAllEntities, setEntities, withEntities } from '@ngneat/elf-entities';
import { createState, createStore } from '@ngneat/elf';
import { map } from 'rxjs';
import { featureCollection } from '@turf/turf';
import { RoadCategoryMutation } from '../../interfaces/road-category-mutation.interface';

const { state, config } = createState(withEntities<RoadCategoryMutation>());
const store = createStore({ name: 'road-category-mutation' }, withEntities<RoadCategoryMutation>());

@Injectable({ providedIn: 'root' })
export class RoadCategoryMutationRepository {
  get mutations(): RoadCategoryMutation[] {
    return getAllEntities()({ ref: store.state });
  }

  mutations$ = store.pipe(selectAllEntities());

  mutationsAsFeatureCollection$ = this.mutations$.pipe(
    map((mutations) => featureCollection(mutations.map((m) => m.asGeoJsonFeature())))
  );

  setMutations(mutations: RoadCategoryMutation[]): void {
    store.update(setEntities(mutations));
  }

  addMutations(mutations: RoadCategoryMutation[]): void {
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

The ONLY things that differ between files:
- The type: `RoadCategoryMutation`, `DrivingDirectionMutation`, `AxleLoadRestrictionMutation`, etc.
- The store name string: `'road-category-mutation'`, `'driving-direction-mutation'`, etc.
- Occasional extra methods specific to that mutation type (e.g. a `mapFeatureToMutation` helper)

Everything else — `setMutations`, `addMutations`, `deleteMutation`, `mutations$`, `mutationsAsFeatureCollection$` — is copy-pasted.

### The constraint: what all mutation types have in common

For the base class to work generically, every mutation type `T` must have:
- An `id` property (required by elf's entity store for identification)
- A `properties.roadSectionId: number` property (used in `deleteMutation` and `addMutations` predicates)
- An `asGeoJsonFeature()` method (used in `mutationsAsFeatureCollection$`)

This means the type constraint is:
```typescript
interface MutationEntity {
  id: string | number;
  properties: {
    roadSectionId: number;
  };
  asGeoJsonFeature(): Feature; // from @turf/turf or GeoJSON type
}
```

Read the actual mutation interfaces to confirm this shape before writing the constraint — they may use slightly different property names.

### The abstract base class design

```typescript
// base-mutation.repository.ts
export abstract class BaseMutationRepository<T extends MutationEntity> {
  protected abstract store: ReturnType<typeof createStore>; // elf store — see challenge below

  get mutations(): T[] { ... }
  mutations$: Observable<T[]>;
  mutationsAsFeatureCollection$: Observable<FeatureCollection>;

  setMutations(mutations: T[]): void { ... }
  addMutations(mutations: T[]): void { ... }
  deleteMutation(roadSectionId: number): void { ... }
}
```

A concrete repository then becomes:

```typescript
const store = createStore({ name: 'road-category-mutation' }, withEntities<RoadCategoryMutation>());

@Injectable({ providedIn: 'root' })
export class RoadCategoryMutationRepository extends BaseMutationRepository<RoadCategoryMutation> {
  protected override store = store;
}
```

That's the target: under 10 lines for each concrete class.

### The TypeScript challenge you will encounter

Elf's `createStore` returns a complex generic type that depends on the entity type passed to `withEntities<T>()`. When you try to type `protected abstract store: ReturnType<typeof createStore>` in the base class without the specific entity type, TypeScript will complain — the methods like `store.update(setEntities(...))` need the store to know it holds entities of type `T`.

This is the hard part of this story. There are several approaches:
1. Type the store as `any` in the base class and accept the loss of type safety there (pragmatic but dirty)
2. Use `EmitRef` or elf's exported store types if they are parameterized properly (ideal but may require research)
3. Use a generic type parameter for the store type itself: `abstract class BaseMutationRepository<T extends MutationEntity, S extends Store = Store>` (complex but fully typed)

Research elf's type system before deciding. Option 1 is acceptable for this sprint if Option 2/3 proves too complex — the learning value is in understanding *why* it's hard, not necessarily achieving perfect typing.

### Inheritance vs. composition: why we choose abstract class here

An alternative approach would be a factory function:
```typescript
export function createMutationRepository<T extends MutationEntity>(name: string) {
  const store = createStore({ name }, withEntities<T>());
  return {
    get mutations() { ... },
    mutations$: ...,
    setMutations(mutations: T[]) { ... },
    // ...
  };
}
```

This is more idiomatic for functional/elf style. However, we choose the abstract class because:
- It matches the `BaseRepository` pattern already established in NTM — consistency across projects
- Angular's `@Injectable({ providedIn: 'root' })` works naturally on classes, not factory-returned objects
- The abstract class approach allows adding lifecycle hooks or `inject()` calls in the base later
- It is easier for IDEs to understand and navigate

### Scope: migrate 3 of the 13, mark the rest

This story does NOT migrate all 13 repositories. Migrating 3 repositories to the base class produces the same learning value as migrating 13, but takes a third of the time. The remaining 10 get a `// TODO: migrate to BaseMutationRepository` comment.

The 3 to migrate are chosen for variety:
- `road-category-mutation.repository.ts` — simple, no extra methods
- `driving-direction-mutation.repository.ts` — simple, no extra methods
- `carriageway-type-mutation.repository.ts` — simple, no extra methods

These are the simplest cases. If they all work, the base class is proven. The more complex ones (if any have extra methods) are left for follow-up.

---

## Analysis

### Files to create

| File | Purpose |
|------|---------|
| `src/app/modules/road-feature/state/base-mutation.repository.ts` | New abstract base class with all shared logic |

### Files to modify

| File | Action |
|------|--------|
| `src/app/modules/road-feature/state/road-category-mutation.repository.ts` | Extend `BaseMutationRepository<RoadCategoryMutation>` — reduce to ~10 lines |
| `src/app/modules/road-feature/state/driving-direction-mutation.repository.ts` | Extend `BaseMutationRepository<DrivingDirectionMutation>` — reduce to ~10 lines |
| `src/app/modules/road-feature/state/carriageway-type-mutation.repository.ts` | Extend `BaseMutationRepository<CarriagewayTypeMutation>` — reduce to ~10 lines |
| The other 10 `*-mutation.repository.ts` files | Add `// TODO: migrate to BaseMutationRepository` comment at top |

### Research needed before starting

- Read 2-3 of the mutation interface files (e.g. `road-category-mutation.interface.ts`) to confirm the exact shape: does `id` exist? Is `properties.roadSectionId` present in all? Does `asGeoJsonFeature()` exist on all?
- Read elf's TypeScript types to understand how `createStore` + `withEntities<T>` types flow — can you parameterize the store type?
- Read `NTM`'s `BaseRepository` at `ntm-frontend/src/app/core/data-access/base-repository.ts` for structural inspiration (it's a different pattern but shows how abstract base classes are used in this codebase)

### Acceptance criteria

- `BaseMutationRepository<T extends MutationEntity>` abstract class exists with all shared methods implemented generically
- The `MutationEntity` interface constraint is defined (either in the same file or a nearby interfaces file)
- The 3 migrated repositories each extend `BaseMutationRepository<TheirType>` and are each under 15 lines
- The 3 migrated repositories contain only: the module-level elf store creation, the class declaration with `extends`, the `protected store` override, and any type-specific methods (if any)
- The other 10 files have a `// TODO: migrate to BaseMutationRepository` comment
- All consumers of the 3 migrated repositories compile without changes (the public API is identical)
- Build passes under `strict: true`

---

## Implementation Plan

### Phase 1: Research and design

Read 3 mutation interface files to confirm the shared shape. Read NTM's `BaseRepository` for structural inspiration. Sketch the `MutationEntity` constraint and the base class method signatures on paper or in comments. Decide how to type the elf store in the base class — research elf's type exports.

No code changes in this phase.

### Phase 2: Write BaseMutationRepository

Create `base-mutation.repository.ts`. Write the `MutationEntity` interface constraint. Implement the abstract base class with all shared methods: `mutations` getter, `mutations$`, `mutationsAsFeatureCollection$`, `setMutations`, `addMutations`, `deleteMutation`. Work through TypeScript errors carefully — this is where the learning happens. Do not use `any` unless all other approaches are proven unworkable.

WIP commit after Phase 2.

### Phase 3: Migrate the 3 target repositories

Convert `road-category-mutation.repository.ts`, `driving-direction-mutation.repository.ts`, and `carriageway-type-mutation.repository.ts` to extend `BaseMutationRepository`. Each should reduce to: elf store creation + class extending base + `protected store` property. Run `npm run build` after each one to catch issues early.

WIP commit after Phase 3.

### Phase 4: Mark the remaining 10 and final verification

Add `// TODO: migrate to BaseMutationRepository — see story IP-5` to the top of the 10 unmigrated files. Run the full build. Verify all consumers of the 3 migrated repositories compile correctly. Smoke test the feature in the browser for the 3 migrated mutation types (road category, driving direction, carriageway type) to confirm behavior is unchanged.

WIP commit after Phase 4.
