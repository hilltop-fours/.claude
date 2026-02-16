# Service Patterns - GRG Wegkenmerken Verkeersborden

Rules for what code belongs in `*.service.ts` files and what does not.
Based on analysis of 15+ existing services across the codebase.

---

## Service Categories

Services in this project fall into these categories. When creating a new service, it MUST fit one of these.

### 1. API/HTTP Services (Thin HTTP Wrappers)

**What they do**: Make HTTP calls and return typed Observables. No logic beyond parameter building.

**Conventions**:
- Extend `BaseService` (provides error handling)
- Inject `HttpClient` only
- Return `Observable<T>` directly — no `.subscribe()`, no side effects
- Build URLs from `environment.apiBaseUrl`
- One service per backend API domain (e.g., `UserService` for user endpoints)

**Real examples**: `UserService`, `OpeningHoursService`, `GeoConversionService`, `PdokLocationService`, `CurrentStateService`, `FeedbackService`

**Typical structure**:
```
- readonly #http = inject(HttpClient)
- baseUrl from environment
- Methods: get/create/update/delete that return Observable<T>
```

### 2. Complex API Services (With Data Transformation)

**What they do**: Wrap API calls with caching, version management, and data transformations.

**Conventions**:
- May extend `BaseWkdService` for WKD-specific versioned logic
- Use `CacheService` for memoization
- Heavy RxJS: `switchMap`, `combineLatest`, `map`, `shareReplay(1)`
- May inject repositories to read state needed for API calls
- Transform backend DTOs to domain models within the pipe

**Real examples**: `SpeedLimitService`, `TrafficSignSelectionService`, `FindingDataService`

### 3. Utility/Helper Services (Stateless Transformations)

**What they do**: Pure functions organized by domain. No HTTP, no state, no side effects.

**Conventions**:
- No `HttpClient` injection
- Methods are pure: input in, output out
- May have `static` methods
- Could theoretically be standalone functions, but kept as services for DI consistency
- Naming: `*Service`, `*HelperService`, `*PresentationService`, `*UtilsService`

**Real examples**: `NlsService` (enum conversions), `TrafficSignPresentationService` (model-to-UI), `FindingUtilsService` (text formatting), `WkdHelperService` (URL building), `AgGridService` (grid params conversion)

### 4. UI Coordination Services (Cross-Component State)

**What they do**: Synchronize state between components that don't have a parent-child relationship.

**Conventions**:
- Use `BehaviorSubject` or signals for local state
- Expose public observables (with `$` suffix)
- Use `debounceTime`, `distinctUntilChanged` to prevent excessive updates
- Use `takeUntilDestroyed(this.#destroyRef)` for cleanup
- May sync state with URL query params (`ActivatedRoute`, `Router`)

**Real examples**: `TrafficSignSelectionService`, `BaseQueryParamService`, `MaplibreService` (cursor state)

### 5. Presentation Services (Display Logic)

**What they do**: Convert domain models to view-ready data. Image paths, colors, feature construction.

**Conventions**:
- No HTTP calls, no state
- Take domain models, return presentation models or GeoJSON features
- Hardcoded asset paths, color mappings, constants
- Used by components and other services, never by repositories

**Real examples**: `TrafficSignPresentationService` (rvvCode to image, model to GeoJSON feature)

### 6. Form/Validation Helper Services

**What they do**: Provide reactive form validation logic, especially for dynamic forms.

**Conventions**:
- Work with `FormArray`, `FormGroup` — never create forms themselves
- Return validation streams or set validators imperatively
- Use `takeUntilDestroyed` for subscription cleanup
- Scoped to specific form patterns (segments, opening hours)

**Real examples**: `SegmentFormArrayService`

---

## What Does NOT Belong in a Service

| Code type | Where it belongs instead |
|-----------|------------------------|
| State management (store) | Repository (`*.repository.ts`) |
| Entity CRUD on an Elf store | Repository |
| Template-only display logic | Pipe or component |
| Single-use helper used by one component | Private method in that component |
| Direct DOM manipulation | Angular directive |
| GeoJSON feature collection storage | Repository (e.g., `TrafficSignBearingRepository`) |
| AG Grid column definitions | Component or constants file |
| Route guards | Guard file |

### Key Boundary: Service vs Repository

- **Service**: Does things (HTTP calls, transformations, coordination, computation)
- **Repository**: Holds things (entity collections, UI state, filter state)
- A service may *inject* a repository to read/write state
- A repository should NEVER make HTTP calls directly — it delegates to services
- Exception: `TrafficSignRepository` and `ParkingBanRepository` wrap service calls with polling/error handling — this is acceptable when the repository needs to update its own state as a side effect of the API call

---

## Structural Conventions

### Injection
```typescript
readonly #http = inject(HttpClient);
readonly #someService = inject(SomeService);
```
Always `readonly`, always `#` private prefix, always `inject()`.

### Scope
- Default: `@Injectable({ providedIn: 'root' })` — singleton
- Component-level only when the service is truly scoped to one component's lifecycle

### Observable Naming
- Observables: `data$`, `items$` (with `$` suffix)
- Signals: `data`, `items` (no suffix)
- Synchronous getters: `get value()` using `BehaviorSubject.value` or `store.getValue()`

### File Location
| Category | Location |
|----------|----------|
| Framework/infra services | `core/services/` |
| Cross-module utilities | `shared/services/` |
| Feature-specific | `modules/{feature}/services/` |
| Map-related | `shared/modules/mapv2/` subtree |

### Base Classes
- `BaseService` — for HTTP services (adds error handling)
- `BaseWkdService` — for WKD-versioned services (extends BaseService)
- `BaseQueryParamService` — for URL state synchronization
- Only extend these when your service fits the pattern exactly
