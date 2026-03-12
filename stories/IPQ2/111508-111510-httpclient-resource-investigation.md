# httpResource Investigation — traffic sign service find

**Story:** #111508 / **Task:** #111510
**Branch:** `spike/111508/111510/httpclient-resource-investigation`
**Date:** 2026-03-12

---

## Story — Original Text

### Description

httpResource onderzoek

### Acceptance Criteria

None

### Discussion

None

---

## Task — Original Text

### Description

traffic sign service kan find weg?

### Discussion

None

---

## Analysis

### Goal & Constraint

**Long-term goal:** Move to a fully signal-based environment — no RxJS in components or services.
**Hard constraint:** Never bridge back to RxJS. `toObservable()`, `toSignal()`, and any Observable casting are off the table as migration strategies.

---

### What `httpResource` is

- Angular 19.2+, still marked **experimental** as of v21
- Returns `HttpResourceRef<T>` — a `WritableResource` with `.value()`, `.isLoading()`, `.error()`, `.status()` as signals
- Accepts a reactive URL/request factory (signal-driven): re-fetches automatically when signal dependencies change
- **GET-only** by default (JSON). Supports `.text()`, `.blob()`, `.arrayBuffer()` variants
- No imperative trigger — you cannot call `.refresh()` with a new id; reactivity is driven purely by signal inputs

---

### Current callers of `find(id: string): Observable<TrafficSign>`

| Caller | File | Pattern | Replaceable with httpResource? |
|--------|------|---------|-------------------------------|
| `updateLocation()` | `traffic-sign.service.ts:191` | `find().pipe(map, switchMap(update))` — fetch-then-mutate | ❌ Not directly — mutation chain requires Observable |
| `patchTrafficSign()` | `traffic-sign.service.ts:199` | Same fetch-then-mutate | ❌ Same |
| `pollUntilUpdated` (×3) | `traffic-sign.repository.ts:21,31,41` | Polling loop after create/update/remove — re-fetches until condition met | ❌ httpResource has no polling/retry-until primitive |
| `road-section.guard.ts:27` | `road-section.guard.ts` | `find().pipe(switchMap)` in a route guard — returns `Observable<boolean>` | ❌ Angular route guards are Observable/Promise-based; no signal API yet |
| `traffic-sign-title-resolver.ts:20` | `traffic-sign-title-resolver.ts` | `find().pipe(map)` in a route resolver — returns `Observable<string>` | ❌ Angular resolvers are Observable/Promise-based; no signal API yet |
| `traffic-sign-selection.service.ts:53` | `traffic-sign-selection.service.ts` | `combineLatest(ids.map(id => find(id)))` — multi-fetch driven by BehaviorSubject | ❌ Entire service is RxJS-based; httpResource does not support array-of-ids pattern |
| `road-feature-overview.component.ts:197` | `road-feature-overview.component.ts` | `find().pipe(take(1)).subscribe(...)` — one-shot imperative fetch | ❌ httpResource has no imperative one-shot call API |

---

### Verdict: `find()` cannot be removed today

`httpResource` is a **reactive GET primitive** — it fits the `getTrafficSign(id: Signal)` pattern perfectly (already done). But it cannot replace `find()` because:

1. **Mutation chains** (`updateLocation`, `patchTrafficSign`) need the fetched value synchronously inside an Observable pipe. No signal equivalent for fetch-then-mutate exists yet.
2. **Polling** (`pollUntilUpdated`) requires imperative re-fetch on a condition — `httpResource` has no `reload()` with conditional logic.
3. **Route guards & resolvers** are framework-level Observable contracts. Angular has not shipped a signal-based guard/resolver API as of v21.
4. **Multi-ID parallel fetch** (`combineLatest` over array) — `httpResource` is singular; no built-in equivalent for dynamic arrays of resources.
5. **Imperative one-shot fetch** (`zoomToTrafficSign`) — no way to trigger `httpResource` imperatively without a wrapping signal.

### What needs to change in Angular before `find()` can go away

- Signal-based route guards (no ETA from Angular team as of v21)
- Signal-based resolvers (same)
- A `httpResource` equivalent for imperative/one-shot fetches without signal input
- The `pollUntilUpdated` pattern would need a signals-native retry/polling primitive (possible with `resource` + manual `reload()`, but complex)
- `traffic-sign-selection.service.ts` would need full rewrite to signals before its fetch pattern can be replaced

### Recommendation

Keep `find()` for now. The blocker is not willingness — it is missing framework APIs. Revisit when Angular ships signal-based guards/resolvers (likely v22+). Track Angular roadmap on this.

---

## Partial Replacement Analysis

The question is not "can we replace all callers" but "which callers can move to pure signals today, with no RxJS bridge."

### Caller-by-caller verdict

| Caller | Pattern | Signal-only replacement possible? | Notes |
|--------|---------|-----------------------------------|-------|
| `getTrafficSign()` | Already `httpResource` ✅ | — | Done |
| `getTrafficSignHistory()` | Already `httpResource` ✅ | — | Done |
| `road-feature-overview.component.ts:197` `zoomToTrafficSign()` | One-shot imperative fetch → `.subscribe()` | ✅ **Yes** | Convert component to hold a `selectedId = signal<string\|undefined>()`, create an `httpResource` off it, react with `effect()`. Caller sets the signal, effect reads `.value()` for coordinates. |
| `traffic-sign-title-resolver.ts:20` | Route resolver → `Observable<string>` | ❌ **No** | Angular resolvers have no signal API yet. Blocked by framework. |
| `road-section.guard.ts:27` | Route guard → `Observable<boolean>` | ❌ **No** | Same — guards are Observable/Promise contracts. Blocked by framework. |
| `updateLocation()` / `patchTrafficSign()` | Fetch-then-mutate pipe | ❌ **No** | These are mutation operations. `httpResource` is GET-only. The fetch here is just a prelude to a write — it belongs in a mutation flow, not a resource. |
| `pollUntilUpdated` ×3 in `traffic-sign.repository.ts` | Poll-after-mutate | ❌ **No** | `pollUntilUpdated` uses RxJS `retry` + `delay`. Angular's `resource` has `.reload()` but no conditional-retry-with-delay primitive. Would require a custom signal-based polling utility that doesn't exist yet. |
| `traffic-sign-selection.service.ts:53` | `combineLatest(ids.map(find))` — dynamic array of parallel fetches | ❌ **No** | `httpResource` is singular. A signal-based equivalent for a dynamic array of resources would require `computed(() => ids().map(id => httpResource(...)))` which creates resources inside a computed — not allowed (resources must be created in an injection context, not reactively). This caller requires a full service rewrite and a framework-level solution. |

---

### What can be done now (without `toObservable`)

**1 caller is cleanly replaceable today:**

`zoomToTrafficSign()` in [road-feature-overview.component.ts](src/app/modules/features/pages/overview/road-feature-overview.component.ts) — it does a one-shot `find().pipe(take(1)).subscribe()` just to read coordinates. This is the cleanest `httpResource` candidate: introduce a `zoomTargetId = signal<string|undefined>()`, wire an `httpResource` to it, and react via `effect()`. No RxJS needed.

### What cannot be done yet

- **5 callers are hard-blocked** by missing Angular APIs (guards, resolvers, no array-resource primitive, no signal-polling primitive)
- **2 callers** (`updateLocation`, `patchTrafficSign`) are mutation flows — `find()` there is a fetch-before-write. Even in a fully signal world, mutations will likely still be imperative. These may never move to `httpResource` regardless of framework maturity.

### Recommendation

Do the `zoomToTrafficSign` replacement as a low-risk, high-signal-purity win. Leave everything else until Angular ships signal guards/resolvers (v22+ likely). Do not invent workarounds — wait for the framework.

---

## HttpResourceRef API — Verified from Angular v21 Docs

Source: https://angular.dev/api/common/http/HttpResourceRef

`HttpResourceRef<T>` extends both `WritableResource<T>` and `ResourceRef<T>`.

### Signals (properties)

| Signal | Type | Description |
|--------|------|-------------|
| `value` | `WritableSignal<T>` | Current data value |
| `status` | `Signal<ResourceStatus>` | Current status: `idle`, `loading`, `reloading`, `resolved`, `error`, `local` |
| `isLoading` | `Signal<boolean>` | True when loading or reloading |
| `error` | `Signal<Error \| undefined>` | Last known error |
| `snapshot` | `Signal<ResourceSnapshot<T>>` | Full state snapshot |
| `headers` | `Signal<HttpHeaders \| undefined>` | HTTP response headers |
| `statusCode` | `Signal<number \| undefined>` | HTTP response status code |
| `progress` | `Signal<HttpProgressEvent \| undefined>` | Progress events (if `reportProgress: true`) |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `set(value: T)` | `void` | Convenience wrapper for `value.set()` — writes local value directly, no HTTP call |
| `update(updater: (value: T) => T)` | `void` | Convenience wrapper for `value.update()` — transforms current value locally, no HTTP call |
| `reload()` | `boolean` | Re-fetches from server. Note: resource does not enter reloading state until actual request is made |
| `hasValue()` | `boolean` | Type guard — true when value is not undefined |
| `asReadonly()` | `Resource<T>` | Returns read-only variant |
| `destroy()` | `void` | Cleanup |

**Key clarification:** `set()` and `update()` write to the local signal only — they do NOT trigger an HTTP call. They put the resource into `'local'` status. `reload()` is the only method that goes back to the server.

---

## ng-elf vs Signal Architecture Research

### Current ng-elf usage in this codebase

**36 files** use `@ngneat/elf`. Split into two categories:

**Category A — UI/client state** (no server data):
Filter state, table column config, edit mode flags, localStorage persistence. Examples: `traffic-sign-mutation.repository.ts`, `map-filter.repository.ts`, `road-feature-edit.repository.ts`.

**Category B — Server entity cache** (data fetched from API, stored in memory):
Entity collections like `SpeedLimitFeature[]`, `TrafficSignFeature[]`, `ParkingBan[]`. Examples: `speed-limit.repository.ts`, `traffic-sign-update.service.ts`, `road-section.repository.ts`.

### ng-elf status

- Latest version: **2.5.1**, last published **2 years ago**
- No signal support — Observable/RxJS only
- No official deprecation, but active development has fully stalled
- No migration guide exists from the elf team
- Not endorsed by the Angular team

### Can httpResource coexist with ng-elf?

Technically yes. Architecturally — it creates two competing reactive systems in the same app (signals + Observables), which works against the hard constraint of no RxJS bridging. Not a viable long-term strategy.

| | ng-elf (current) | httpResource |
|---|---|---|
| Server entity cache | ✅ `withEntities` | ✅ per-resource |
| UI/client state | ✅ `withProps` | ❌ HTTP-only |
| Shared across components | ✅ singleton service | ⚠️ only if in root service |
| Multiple entities by ID array | ✅ yes | ❌ no primitive |
| After-mutation update | `upsertEntities()` | `.set()` / `.update()` / `.reload()` |
| Reactivity primitive | RxJS Observable | Signal |
| Maintenance | stalled | n/a |

---

## The Intended Replacement: @ngrx/signals (SignalStore)

Source: https://ngrx.io/guide/signals/signal-store + https://www.angulararchitects.io/blog/using-the-resource-api-with-the-ngrx-signal-store/

`@ngrx/signals` is the **official, actively developed, Angular-team-endorsed** signal-based state management solution. It is the direct migration target for ng-elf.

### Why it fits

- Fully signal-based — no RxJS required
- `withEntities` — same entity pattern as `@ngneat/elf-entities` (add, set, upsert, delete)
- `withState` / `withProps` — same concept as elf's `withProps` for UI state
- `withProps` + `resource()` — **the integration point for httpResource/resource API**
- localStorage persistence supported
- Zoneless compatible
- `@ngrx/signals/testing` for unit tests
- NgRx v20: actively adding features (`prependEntity`, `upsertEntity`, `withLinkedState`, Events plugin)
- SignalStore overtook ComponentStore as the 2nd most popular Angular state management library (2025)

### How resource() integrates inside a SignalStore

```typescript
export const TrafficSignStore = signalStore(
  { providedIn: 'root' },
  withState({ filter: { status: [], rvvCode: [] } }),
  withProps(() => ({
    _service: inject(TrafficSignService),
    _toastService: inject(ToastService),
  })),
  withProps((store) => ({
    // resource() lives INSIDE the store — private by convention (_prefix)
    _trafficSignsResource: resource({
      params: store.filter,
      loader: ({ params, abortSignal }) =>
        store._service.findAll(params, abortSignal),
    }),
  })),
  withProps((store) => ({
    // expose read-only to consumers
    trafficSignsResource: store._trafficSignsResource.asReadonly(),
  })),
  withComputed((store) => ({
    trafficSigns: computed(() => store._trafficSignsResource.value()),
    isLoading: computed(() => store._trafficSignsResource.isLoading()),
  })),
  withMethods((store) => ({
    updateFilter: signalMethod<TrafficSignFilter>((filter) =>
      patchState(store, { filter }),
    ),
    reloadSigns: () => store._trafficSignsResource.reload(),
    // optimistic local update after a mutation:
    locallyUpdateSign: (updated: TrafficSign) =>
      store._trafficSignsResource.update((signs) =>
        signs?.map((s) => (s.id === updated.id ? updated : s)),
      ),
  })),
  withHooks({
    onInit(store) {
      // effect for error toast — stays inside the store
      effect(() => {
        if (store._trafficSignsResource.error()) {
          store._toastService.showError();
        }
      });
    },
  }),
);
```

### After-mutation update pattern (replaces upsertEntities)

After a `PUT`/`PATCH` succeeds, two options:

1. **Optimistic local patch** (instant UI, no round-trip):
   `store.locallyUpdateSign(updatedSign)` → calls `resource.update()` → status becomes `'local'`

2. **Re-fetch from server** (source of truth, matches current `pollUntilUpdated` intent):
   `store.reloadSigns()` → calls `resource.reload()` → re-fetches, status becomes `'reloading'` then `'resolved'`

### Architecture naming clarification

Current codebase has an inverted naming: files called "repository" are ng-elf stores (state), while files called "service" are the HTTP layer. In NgRx SignalStore architecture:

- The **store** IS the repository — it holds state + wires resource fetching
- The **service** becomes a thin HTTP data-access layer injected into the store
- This migration would naturally fix the naming inversion

### Migration path summary

| Current | Migrate to |
|---------|-----------|
| `@ngneat/elf` `createStore` + `withProps` (UI state) | `@ngrx/signals` `signalStore` + `withState` |
| `@ngneat/elf` `createStore` + `withEntities` (server cache) | `@ngrx/signals` `signalStore` + `withProps(resource())` |
| `@ngneat/elf-entities` `upsertEntities` after mutation | `resource.update()` (optimistic) or `resource.reload()` (re-fetch) |
| `@ngneat/elf-persist-state` `persistState` | custom `withHooks` + localStorage in `signalStore` (or community plugin) |
| `store.pipe(selectAllEntities())` (Observable) | `computed(() => store._resource.value())` (Signal) |
| `store.query(getAllEntities())` (sync) | `store.trafficSigns()` (Signal call — sync) |

---

## Angular's Signal Vision — Plain Service vs signalStore

Source: angular.dev (no store prescribed by Angular itself)

**Angular does NOT prescribe a store library.** Their own vision is:

```
plain Injectable service + httpResource = enough for most cases
```

The decision tree:

| Situation | Use |
|-----------|-----|
| Single entity, reactive GET, 1-2 consumers | plain service + `httpResource` |
| Shared UI state + server data across many components | `signalStore` |
| Complex entity collections, pagination, interdependent resources | `signalStore` + `withEntities` |

ng-elf vs signalStore line count (same feature):

```typescript
// ng-elf — two things: module-level variable + class that wraps it
const store = createStore({ name: 'todo' }, withEntities<Todo>(), withProps<{filter: string}>({ filter: 'all' }));
@Injectable({ providedIn: 'root' })
export class TodoRepository {
  filter$ = store.pipe(select(state => state.filter));
  todos$ = store.pipe(selectAllEntities());
  setFilter(f: string) { store.update(setProp('filter', f)); }
  setTodos(t: Todo[]) { store.update(setEntities(t)); }
}

// signalStore — one thing, IS the injectable
export const TodoStore = signalStore(
  { providedIn: 'root' },
  withState({ filter: 'all' }),
  withEntities<Todo>(),
  withMethods((store) => ({
    setFilter: (f: string) => patchState(store, { filter: f }),
    setTodos: (t: Todo[]) => patchState(store, setAllEntities(t)),
  })),
);
```

Template reads: ng-elf needs `filter$ | async`, signalStore reads `store.filter()` synchronously.

---

## Real Migration Candidates in This Codebase

### SIMPLE — Plain service + httpResource, no store needed

These are read-only or simple-mutation services with no shared UI state. Angular's own pattern covers them fully.

---

#### Candidate S1: `CountyService`

**File:** [county.service.ts](src/app/shared/services/county.service.ts)

**Current pattern:**
```typescript
getCounties(): Observable<County[]> {
  return this.#cacheService.get<County[]>(this.countiesCacheKey) ?? this.#loadCountiesCache();
}
getCountyByCode(code: string): Observable<County | undefined> {
  return this.getCounties().pipe(map(counties => counties.find(c => c.code === code)));
}
```
Manual RxJS cache via `CacheService`. Consumers must subscribe or use `async` pipe.

**Signal replacement:**
```typescript
@Injectable({ providedIn: 'root' })
export class CountyService {
  readonly #counties = httpResource<County[]>(() => `${environment.apiBaseUrl}/area/counties`);

  // derived — replaces getCountyByCode()
  getByCode(code: string): Signal<County | undefined> {
    return computed(() => this.#counties.value()?.find(c => c.code === code));
  }

  readonly isLoading = this.#counties.isLoading;
}
```

**What goes away:** `CacheService` dependency (httpResource caches until signal input changes), all RxJS operators, `async` pipe in templates.
**Complexity:** zero — pure reactive GET, no mutations.
**One catch:** `getByCode()` currently returns `Observable` — callers need updating too.

---

#### Candidate S2: `MunicipalityService`

**File:** [municipality.service.ts](src/app/shared/services/municipality.service.ts)

**Current pattern:** Manual RxJS cache + `SwalService` for error toast via `tap`. Same pattern as `CountyService`.

**Signal replacement:**
```typescript
@Injectable({ providedIn: 'root' })
export class MunicipalityService {
  readonly #municipalities = httpResource<MunicipalityFeatureCollection>(
    () => `${environment.accessibilityUrl}/municipalities`
  );

  constructor() {
    effect(() => {
      if (this.#municipalities.error()) Swal.fire({ ...swalToastError });
    });
  }

  getFeature(municipalityId: string): Signal<MunicipalityFeature | undefined> {
    return computed(() =>
      this.#municipalities.value()?.features.find(m => m.id === municipalityId)
    );
  }
}
```

**What goes away:** `CacheService`, `SwalService`, all pipe operators. Error toast moves into `effect()`.
**Complexity:** zero mutations.
**One catch:** Same — callers need to switch from `Observable` to `Signal`.

---

#### Candidate S3: `NlsIssueService`

**File:** [nls-issue.service.ts](src/app/shared/services/nls-issue.service.ts)

**Current pattern:** Three methods — `getIssue(id)`, `updateIssue(id, body)`, `searchIssues(search)`. All return Observables. No cache, no state.

**Signal replacement:**
```typescript
@Injectable({ providedIn: 'root' })
export class NlsIssueService {
  readonly #http = inject(HttpClient);

  // callers pass a signal — resource re-fetches when id changes
  getIssue(id: Signal<string | undefined>) {
    return httpResource<HgvIssue>(() =>
      id() ? `${BASE_PATH}/${id()}` : undefined,
      { transform: issue => this.#mapIssue(issue) }  // replaces .pipe(map(...))
    );
  }

  // mutations stay as HttpClient → Promise via firstValueFrom
  updateIssue(id: string, issue: UpdateIssue): Promise<Issue> {
    return firstValueFrom(this.#http.patch<Issue>(`${BASE_PATH}/${id}`, issue));
  }

  searchIssues(search: SearchIssues): Promise<HgvIssuesPage> {
    return firstValueFrom(
      this.#http.post<Issues>(`${BASE_PATH}/search`, search).pipe(map(this.#mapIssues))
    );
  }
}
```

**What goes away:** `map` pipe on GET, Observable return types for reads.
**One catch:** `searchIssues` is a POST used as a query (not a mutation) — `httpResource` can't do POST GETs directly. Stays as `firstValueFrom`. Acceptable.

---

### MEDIUM — Plain service + `signal()` for UI state, no signalStore needed

These have some shared state but it's simple enough that raw `signal()` inside an Injectable handles it — no `signalStore` overhead required.

---

#### Candidate M1: `RoadAuthorityService`

**File:** [road-authority.service.ts](src/app/shared/services/road-authority.service.ts)

**Current pattern:** Already half-migrated — uses `toSignal(this.roadAuthorities$)`. Uses manual `CacheService` for the list. `deleteMutation` returns Observable through `swalService`.

**Signal replacement:**
```typescript
@Injectable({ providedIn: 'root' })
export class RoadAuthorityService {
  readonly #http = inject(HttpClient);

  // list — shared across 7+ consumers, singleton = one request
  readonly roadAuthorities = httpResource<RoadAuthority[]>(
    () => `${environment.apiBaseUrl}/road-authorities`
  );

  // derived lookup — replaces findRoadAuthority()
  findRoadAuthority(type: string, code: string): Signal<RoadAuthority | undefined> {
    return computed(() =>
      this.roadAuthorities.value()?.find(ra => ra.type === type && ra.code === code)
        ?? this.#fallback(type, code)
    );
  }

  // mutations stay as HttpClient → Promise
  async deleteMutation(roadSectionId: number): Promise<void> {
    await firstValueFrom(this.#http.delete<void>(`${this.getUrl()}/road-sections/${roadSectionId}`));
    // no reload needed — this doesn't affect the roadAuthorities list
  }
}
```

**What goes away:** `CacheService`, `toSignal()` bridge (was `toSignal(Observable)` — the anti-pattern we want to eliminate), RxJS operators.
**One catch:** `getMutations()` and `findMutation()` use `withVersion()` from `BaseWkdService` — that's an Observable-based base class. Those two methods stay as-is for now.
**MVP verdict:** Replace the list GET + `findRoadAuthority` now. Leave `getMutations`/`findMutation` until `BaseWkdService` is migrated.

---

#### Candidate M2: `TrafficSignService` — `getTrafficSign` + `getTrafficSignHistory` (already done ✅)

Already the exact correct pattern. Shown here as the reference for what "done" looks like:
```typescript
getTrafficSign(id: Signal<string | undefined>) {
  const resource = httpResource<TrafficSign>(() => id() ? `${this.baseUrl}/${id()}` : undefined);
  effect(() => { this.#showToastError(resource.error); });
  return resource;
}
```
Service holds the resource, caller passes a signal, error goes into `effect()`. This is the template.

---

#### Candidate M3: `UserRepository` (ng-elf → plain signals, no signalStore)

**File:** [user.repository.ts](src/app/modules/user/state/user.repository.ts)

**Current pattern:** ng-elf `withProps` store for UI state: `organization`, `activeRoadAuthority`, `mapState`, `lastErrors`. Persisted to localStorage. No HTTP calls at all.

**Signal replacement — no signalStore needed, just signals in a service:**
```typescript
@Injectable({ providedIn: 'root' })
export class UserRepository {
  // raw signals replace ng-elf withProps
  readonly organization = signal<Organization | undefined>(undefined);
  readonly activeRoadAuthority = signal<RoadAuthority | undefined>(undefined);
  readonly mapState = signal<MapState>(defaultMapState);

  // localStorage persistence replaces @ngneat/elf-persist-state
  constructor() {
    const saved = localStorage.getItem('user-ui');
    if (saved) this.mapState.set(JSON.parse(saved).mapState ?? defaultMapState);

    effect(() => {
      localStorage.setItem('user-ui', JSON.stringify({ mapState: this.mapState() }));
    });
  }

  setOrganization(org: Organization) { this.organization.set(org); }
  setActiveRoadAuthority(ra: RoadAuthority) { this.activeRoadAuthority.set(ra); }
  setMapState(state: MapState) { this.mapState.set(state); }
}
```

**What goes away:** `@ngneat/elf`, `@ngneat/elf-persist-state`, module-level `createStore`, all Observable selectors.
**Callers change from:** `repo.mapState$.pipe(...)` → `repo.mapState()` (synchronous signal read).
**One catch:** Need to check if `activeMunicipality` computed signal still works — it derives from `activeRoadAuthority` which becomes a plain signal. Should be straightforward with `computed()`.
**Verdict:** This is the easiest ng-elf removal in the whole codebase. Pure UI state, no HTTP, no entities — just swap `withProps` for `signal()`.

---

### Decision guide — when to use what

```
Does it fetch data from the server?
├── YES → use httpResource in the service
│         service.someResource = httpResource(() => url())
│
└── NO → use signal() in the service
          service.someState = signal(initialValue)

Does it need to coordinate multiple resources + complex filter state + entity collections?
└── YES → consider signalStore (not needed for anything above)
```

---

## Implementation Plan

N/A — research spike, no code changes.
