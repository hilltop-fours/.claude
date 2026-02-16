# Repository Patterns - GRG Wegkenmerken Verkeersborden

Rules for what code belongs in `*.repository.ts` files and what does not.
Based on analysis of 20+ existing repositories across the codebase.

---

## What a Repository Is

A repository is a **state container**. It holds data and exposes it reactively.
It uses `@ngneat/elf` as its state management library.

Repositories do NOT perform HTTP calls, business logic, or UI operations.
They are the single source of truth for a specific slice of application state.

---

## Repository Categories

### 1. Entity Collection Repositories (Most Common)

**What they do**: Store collections of typed entities (usually GeoJSON features) using Elf's `withEntities`.

**Conventions**:
- Store created outside the class: `const store = createStore({ name: '...' }, withEntities<T>())`
- Expose sync getter: `get items() { return store.query(getAllEntities()); }`
- Expose observable: `items$ = store.pipe(selectAllEntities())`
- Expose derived `featureCollection$` for map consumption
- CRUD methods: `setItems()`, `addItems()`, `editItem()`, `deleteItem()`
- Delete by predicate when entity ID is a nested property

**Real examples**: `EnvironmentalZoneRepository`, `SpeedLimitRepository`, `RoadSectionRepository`, `RvmRepository`, `SpeedLimitMutationRepository`, `RoadCategoryRepository`

**Typical structure**:
```typescript
const store = createStore({ name: 'entityName' }, withEntities<FeatureType>());

@Injectable({ providedIn: 'root' })
export class EntityRepository {
  get items() { return store.query(getAllEntities()); }
  items$ = store.pipe(selectAllEntities());
  featureCollection$ = this.items$.pipe(map(features => featureCollection(features)));

  setItems(items: FeatureType[]) { store.update(setEntities(items)); }
  addItems(items: FeatureType[]) { store.update(addEntities(items)); }
  deleteItem(id: string) {
    store.update(deleteEntitiesByPredicate(e => e.properties.someId === id));
  }
}
```

### 2. UI State Repositories (Props-Based)

**What they do**: Store UI preferences, filter state, table configuration using Elf's `withProps`.

**Conventions**:
- Store created with `withProps<InterfaceType>(initialState)`
- Expose typed getters per property
- Expose typed observables per property using `select()`
- Update methods per property using `setProp()` or spread update
- Often have a `reset()` method to restore defaults
- May persist to localStorage using `persistState()`

**Real examples**: `MapFilterRepository`, `RoadFeatureRepository`, `UserRepository`, `TrafficSignMutationRepository`, `FindingsRepository`

**Typical structure**:
```typescript
interface UiProps {
  filterState?: FilterModel;
  columnState?: ColumnState[];
}

const store = createStore({ name: 'uiState' }, withProps<UiProps>({ ... }));

@Injectable({ providedIn: 'root' })
export class UiStateRepository {
  get filterState() { return store.getValue()?.filterState; }

  updateFilterState(filter: FilterModel) {
    store.update(state => ({ ...state, filterState: filter }));
  }

  reset() { store.reset(); }
}
```

### 3. BehaviorSubject Repositories (Simple Reactive State)

**What they do**: Hold reactive state using plain `BehaviorSubject` instead of Elf stores. Used for simpler cases or map visualization data.

**Conventions**:
- Private `BehaviorSubject` with `#` prefix
- Public observable via `.asObservable()`
- Update methods call `.next()`
- `clear()` method to reset to empty state

**Real examples**: `TrafficSignBearingRepository` (map bearing lines/arrows)

### 4. Aggregation/Facade Repositories (Coordinators)

**What they do**: Inject many other repositories/services and act as a single access point for a subsystem.

**Conventions**:
- Inject 5-20+ dependencies
- Don't manage their own store
- Methods delegate to composed services/repositories
- Used for complex setup (registering map elements, coordinating selections)

**Real examples**: `MapSelectionRepository`, `MapLocationElementRepository`, `OverviewMapElementRepository`

---

## What Does NOT Belong in a Repository

| Code type | Where it belongs instead |
|-----------|------------------------|
| HTTP/API calls | Service (`*.service.ts`) |
| Data transformation / business logic | Service |
| Form validation | Service or component |
| Route navigation | Component or guard |
| Complex RxJS orchestration (switchMap, combineLatest of HTTP) | Service |
| Template/rendering logic | Component or pipe |
| Toast notifications | Service (exception: some repos do this after state update — acceptable but discouraged) |

### Key Boundary: Repository vs Service

| Responsibility | Repository | Service |
|---------------|-----------|---------|
| Hold entity collections | Yes | No |
| Hold UI state (filters, columns) | Yes | No |
| Expose reactive streams of state | Yes | Only for computed/derived data |
| Make HTTP calls | No | Yes |
| Transform data for API | No | Yes |
| Transform data for display | No | Yes (presentation services) |
| Cache API responses | No | Yes (CacheService) |
| Coordinate multiple API calls | No | Yes |
| Update state after API call | Acceptable (via tap) | Delegates to repository |

### Acceptable Exceptions

Two patterns exist where repositories touch services:
1. **`TrafficSignRepository`**: Wraps service HTTP calls with `pollUntilUpdated()` and updates map state via `tap()`. This is acceptable because the polling+state-update is tightly coupled.
2. **`ParkingBanRepository`**: Wraps service calls with error handling (toast) and state updates. Same justification.

These are the ONLY acceptable cases. New repositories should NOT add HTTP call wrapping unless the pattern exactly matches these two.

---

## Structural Conventions

### Store Definition
- Always created OUTSIDE the class as a module-level `const`
- Named with the entity/concern: `createStore({ name: 'speedLimit' }, ...)`
- One store per repository — never share stores between repositories

### Scope
- Always `@Injectable({ providedIn: 'root' })` — singleton
- Exception: `MapRoadSectionElementRepository` uses base class pattern with per-instance stores

### Naming
- File: `{entity-name}.repository.ts` (kebab-case)
- Class: `{EntityName}Repository` (PascalCase)
- Separate read vs mutation: `speed-limit.repository.ts` (display data) vs `speed-limit-mutation.repository.ts` (pending changes)

### Observable & Getter Patterns
```typescript
// Observable (reactive, for templates and subscriptions)
items$ = store.pipe(selectAllEntities());
filterState$ = store.pipe(select(state => state.filterState));

// Synchronous getter (for imperative code)
get items() { return store.query(getAllEntities()); }
get filterState() { return store.getValue()?.filterState; }

// Derived observable (for map rendering)
featureCollection$ = this.items$.pipe(map(features => featureCollection(features)));
```

### Signals (Emerging Pattern)
Some newer repositories expose signals via `toSignal()`:
```typescript
organization = toSignal(this.organization$);
```
This is acceptable in repositories but not required.

### localStorage Persistence
Only for state that should survive page refresh:
- User preferences (active road authority, organization)
- Table state (column order, filters, period)
- Map state (last position/zoom)

Pattern:
```typescript
export const persist = persistState(store, {
  key: 'unique-key',
  storage: localStorageStrategy,
});
```

### File Location
| Category | Location |
|----------|----------|
| Feature entity state | `modules/{feature}/state/` or `modules/{feature}/services/` |
| Map state | `shared/modules/mapv2/state/` |
| Shared state | `shared/services/` (e.g., UserRepository) |

### CRUD Method Naming
```
set{Entity}(items)      — Replace all entities
add{Entity}(items)      — Add to existing collection
edit{Entity}(item)      — Delete + add (replace single entity)
delete{Entity}(id)      — Remove by ID or predicate
update{Property}(value) — Update a single UI prop
reset()                 — Restore to initial state
```
