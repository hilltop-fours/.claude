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

### Constraints
- Goal: fully signal-based — no RxJS in components or services
- Hard constraint: never bridge back to RxJS. `toObservable()`, `toSignal()`, Observable casting = off the table

### httpResource facts
- Angular 19.2+, experimental as of v21
- Returns `HttpResourceRef<T>` — signals: `.value()`, `.isLoading()`, `.error()`, `.status()`
- Reactive URL factory: re-fetches when signal inputs change. GET-only (JSON). Variants: `.text()`, `.blob()`, `.arrayBuffer()`
- No imperative trigger — reactivity driven by signal inputs only

### `find()` verdict: cannot be removed today
| Caller | Pattern | Blocked by |
|--------|---------|-----------|
| `updateLocation()` `traffic-sign.service.ts:191` | fetch-then-mutate | no signal mutation primitive |
| `patchTrafficSign()` `traffic-sign.service.ts:199` | fetch-then-mutate | same |
| `pollUntilUpdated` ×3 `traffic-sign.repository.ts:21,31,41` | poll-after-mutate | no signal retry/delay primitive |
| `road-section.guard.ts:27` | guard → `Observable<boolean>` | framework contract, v22+ |
| `traffic-sign-title-resolver.ts:20` | resolver → `Observable<string>` | framework contract, v22+ |
| `traffic-sign-selection.service.ts:53` | `combineLatest(ids.map(find))` | no array-resource primitive |
| `road-feature-overview.component.ts:197` | one-shot `find().pipe(take(1)).subscribe()` | ✅ replaceable — see below |

One caller replaceable today: `zoomToTrafficSign()` — introduce `zoomTargetId = signal<string|undefined>()`, wire `httpResource`, react via `effect()`.

### HttpResourceRef API
| Member | Notes |
|--------|-------|
| `value: WritableSignal<T>` | current data |
| `status: Signal<ResourceStatus>` | idle/loading/reloading/resolved/error/local |
| `isLoading: Signal<boolean>` | |
| `error: Signal<Error\|undefined>` | |
| `headers: Signal<HttpHeaders\|undefined>` | |
| `statusCode: Signal<number\|undefined>` | |
| `set(v)` / `update(fn)` | local write only → status `'local'`, no HTTP |
| `reload()` | re-fetches from server |
| `hasValue()` | type guard |
| `asReadonly()` | `Resource<T>` |
| `destroy()` | cleanup |

### ng-elf status
36 files use `@ngneat/elf`. Latest: 2.5.1, last published 2 years ago. No signal support. No migration guide. Development stalled. Not Angular-team-endorsed.

### Migration target: `@ngrx/signals` SignalStore
Fully signal-based, Angular-team-endorsed, actively developed (v20). `withEntities` = same pattern as `@ngneat/elf-entities`. `withProps(resource())` = integration point for httpResource. Zoneless compatible.

| Current | Target |
|---------|--------|
| `createStore` + `withProps` (UI state) | `signalStore` + `withState` OR plain `signal()` in Injectable |
| `createStore` + `withEntities` (server cache) | `signalStore` + `withProps(resource())` |
| `upsertEntities` after mutation | `resource.update()` (optimistic) or `resource.reload()` (re-fetch) |
| `persistState` | `effect()` + localStorage in constructor |
| `store.pipe(selectAllEntities())` | `computed(() => store._resource.value())` |

### Decision guide
- Fetch from server → `httpResource` in service
- No fetch, UI state only → `signal()` in service
- Multiple resources + complex filter + entity collections → `signalStore`

---

## Migration Candidates

### Root blocker discovered during spike
S1 + S2 are blocked not by the services themselves but by their callers. Both `CountyService` and `MunicipalityService` have callers that chain off `UserRepository.activeMunicipalityId$` (Observable). As long as that is an Observable, those callers must stay in RxJS. **M3 (`UserRepository`) must be done first to unblock S1 + S2.**

### S1: `CountyService` — [county.service.ts](src/app/shared/services/county.service.ts)
Current: manual RxJS cache via `CacheService`. 5 callers.
**BLOCKED by M3.** `parking-ban.repository.ts:getParkingBan()` uses `getCountyByCode()` inside `switchMap`. Root cause: `UserRepository.activeMunicipalityId$` is Observable.
4/5 callers are replaceable (components), but partial migration not worth it without the repo.
Target: `readonly #counties = httpResource<County[]>(() => url)` + `getCountyByCode(code): Signal<County|undefined>` via `computed()`.

### S2: `MunicipalityService` — [municipality.service.ts](src/app/shared/services/municipality.service.ts)
Current: manual RxJS cache + `SwalService` via `tap`. 2 callers.
**BLOCKED by M3.** Both callers (`map-bounds-query-param.service.ts`, `select-road-authority-modal.component.ts`) use `getFeatureForMunicipality()` inside `switchMap` driven by `activeMunicipalityId$`.
Target: `httpResource` + `effect()` for error toast + `getFeature(id): Signal<MunicipalityFeature|undefined>` via `computed()`.

### S3: `NlsIssueService` — [nls-issue.service.ts](src/app/shared/services/nls-issue.service.ts)
Current: `getIssue(id)`, `updateIssue`, `searchIssues` — all Observable, no cache, no state.
**Not yet investigated** — likely independent of UserRepository. Check callers before starting.
Target: `getIssue(id: Signal)` → `httpResource`. Mutations → `firstValueFrom`. `searchIssues` is POST-as-query → stays `firstValueFrom` (acceptable).

### M1: `RoadAuthorityService` — [road-authority.service.ts](src/app/shared/services/road-authority.service.ts)
Current: half-migrated — uses `toSignal(roadAuthorities$)` bridge. `getMutations`/`findMutation` use `BaseWkdService` (Observable base class).
Target: list GET → `httpResource`, remove `toSignal()` bridge. Leave `getMutations`/`findMutation` until `BaseWkdService` migrated.

### M2: `TrafficSignService` `getTrafficSign` + `getTrafficSignHistory` ✅ DONE
Reference pattern: `httpResource(() => id() ? url : undefined)` + `effect(() => showToastError(resource.error))`.

### M3: `UserRepository` — [user.repository.ts](src/app/modules/user/state/user.repository.ts)
**Prerequisite for S1 + S2.** Pure UI state, no HTTP. 4 ng-elf `withProps` fields: `organization`, `activeRoadAuthority`, `mapState`, `lastErrors`. Persisted to localStorage via `@ngneat/elf-persist-state`.
Target: plain `signal()`s in Injectable. `effect()` for localStorage. `computed()` for `activeMunicipalityId`.
See incremental plan below.

---

## Incremental M3 Migration Plan

Strategy: create `user.store.ts` alongside existing `user.repository.ts`. Migrate one property at a time. Old repo delegates to store during transition. Delete repo when empty. Each step = separate WIP commit, independently verifiable.

### Step 1 — `lastErrors` (1 external caller, zero risk to map/auth)
- Caller: `error-list-modal.component.ts:62` — `lastErrors$.subscribe()`
- New store: `readonly lastErrors = signal<ErrorTrace[]>([])`
- Update `addErrorTrace()` and `getLastErrors()` to read/write signal
- Caller: switch from subscribe to `effect()` or direct signal read
- Old repo: remove `lastErrors$`

### Step 2 — `organization` (5 callers)
Callers: `organization.guard.ts`, `road-section-auth.service.ts` ×3, `map-controls.component.ts`
- New store: `readonly organization = signal<Organization | undefined>(undefined)`
- All 5 callers: `organization$` pipe → `organization()` signal read
- Route guard: `inject(UserStore).organization()` directly
- Old repo: remove `organization$`, `getOrganization()` reads signal, `updateOrganization()` delegates

### Step 3 — `activeRoadAuthority` + `activeMunicipalityId` ← UNLOCKS S1 + S2
Callers: `speed-limit.service.ts`, `select-road-authority-modal.component.ts`, `map-bounds-query-param.service.ts`, `global-filter-query-param.service.ts`, `findings.repository.ts`
- New store: `readonly activeRoadAuthority = signal<RoadAuthority | undefined>(undefined)`
- Derived: `readonly activeMunicipalityId = computed(() => #getMunicipalityId(this.activeRoadAuthority()))`
- All callers: Observable pipe → signal read
- After this step: S1 + S2 callers can read `activeMunicipalityId()` synchronously

### Step 4 — `mapState` + localStorage persistence
- New store: `readonly mapState = signal<MapState>(defaultMapState)`
- Constructor: `const saved = localStorage.getItem('user-ui'); if (saved) this.mapState.set(JSON.parse(saved).mapState ?? defaultMapState)`
- `effect()`: `localStorage.setItem('user-ui', JSON.stringify({ mapState: this.mapState() }))`
- Replaces `@ngneat/elf-persist-state` `persistState()`

### Step 5 — Delete `user.repository.ts`, clean up
- Remove `@ngneat/elf` and `@ngneat/elf-persist-state` imports
- Check remaining ng-elf usage — if UserRepository was last pure-UI-state user, assess `package.json` removal (ask user)
- Squash WIP commits for PR

---

## Implementation Plan

Research spike — no code changes were the deliverable. Findings above replace the original N/A plan.

**Corrected execution order (M3 must precede S1 + S2):**
1. M3 Step 1 — `lastErrors` (warm-up, safe)
2. M3 Step 2 — `organization` (moderate blast radius)
3. M3 Step 3 — `activeRoadAuthority` + `activeMunicipalityId` (unlocks S1 + S2)
4. S1 — `CountyService` + all 5 callers
5. S2 — `MunicipalityService` + 2 callers
6. S3 — `NlsIssueService` (investigate callers first)
7. M3 Step 4 — `mapState` + localStorage
8. M3 Step 5 — cleanup + ng-elf removal assessment
9. M1 — `RoadAuthorityService` (after `BaseWkdService` situation is clear)

---

## Architecture Decision — signal facade over ng-elf

`@ngrx/signals` `signalStore` out of scope for this story. `InfoMessagesStore` shows why: `rxMethod` + `patchState` + `withMethods` = large tightly coupled block.

Goal: components live in pure signal environment. ng-elf stays but is hidden.

Pattern: signal facade class wraps elf store internally. Exposes only signals + plain methods. No `$` observables, no `select()` leaking out to callers. Components inject facade only.

`toSignal()` rule: allowed inside facade as internal implementation detail only. Forbidden in components and in public API of any service/repo.

`user.store.ts` is this pattern for UI-only state. For entity repos with HTTP the same applies: facade owns elf store, converts elf selects to signals via `toSignal()` internally, exposes only signals outward.

---

## Page Candidates for Testing

Pages assessed as browser-testable targets (no map, relatively self-contained).

### /bulk-uploads
Component: `bulk-upload/pages/bulk-upload/bulk-upload.component.ts`
Repos used: none — uses `BlobDownloadService` + `FileDownloadService` directly (pure RxJS services, no ng-elf)
Assessment: no ng-elf at all. Skip — not relevant to this migration.

### /infoberichten
Component: `info-messages/pages/list/list.component.ts`
Repos used: `InfoMessagesStore` (`@store/info-messages.store.ts`) — already `@ngrx/signals` `signalStore`, not ng-elf
Assessment: already migrated. Good reference pattern to study, not a migration target.

### /organisaties (overview)
Component: `user/pages/organization-overview/organization-overview.component.ts`
Repos used: none — uses `OrganizationService` directly (plain HTTP Observable service)
Assessment: no ng-elf. Has old RxJS patterns (`BehaviorSubject`, `AsyncPipe`, `console.error`) worth cleaning up later, but not a ng-elf migration target.

### /organisaties/:id/bewerk (edit)
Component: `user/pages/organization-edit/organization-edit.component.ts`
Repos used: `UserRepository` — calls `updateOrganization()` in two places (lines 128, 170)
Assessment: best candidate for M3 Step 2 wiring. Swap `inject(UserRepository)` → `inject(UserSignals)`, update two `updateOrganization()` calls. Visually verifiable: save org → signal updated.

### /kaart/wegvakken/:id/details
Component: `road-feature/components/overview/detail-cards/road-section-details/road-section-details.component.ts`
Repos used: `RoadFeatureEditRepository`, `RoadFeatureRepository`, `OverviewMapElementRepository`, `MapSelectionRepository` — all ng-elf, all map-coupled
Assessment: skip — 4 repos wired to map selection and navigation internally despite no visible map on this route.

### /updates
Component: `updates/pages/updates/updates.component.ts`
Repos used: `InfoMessagesStore` (already `@ngrx/signals`) — reads `store.current`
Assessment: skip — already migrated, nothing to do here.

---

## Migration Rules

- No cleanup/refactor/inline/simplify during any migration step. Structure of new files mirrors source file exactly until cleanup pass.
- Cleanup pass = Step 5 only, after repo deleted.
- Never remove methods/functions that still have callers during migration. Mark with `/** @deprecated Use X instead */` — signals to other devs: "new way exists, migrate when you can." Delete only in the cleanup pass once all callers are gone.
