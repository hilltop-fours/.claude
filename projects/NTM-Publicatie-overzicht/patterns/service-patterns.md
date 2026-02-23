# Service Patterns - NTM Publicatie Overzicht

Rules for what code belongs in `*.service.ts` files and what does not.
Based on analysis of all 26 existing services in the codebase.

---

## What a Service Is

A service **does things** — it makes HTTP calls, coordinates state, performs computations, or integrates with third-party libraries.

Services do NOT hold application state. That is the repository's job.
Components and other consumers call services indirectly via repositories, or directly for non-HTTP coordination work.

There is no `BaseService` in this project. All services are plain injectable classes.

---

## Service Categories

Services fall into these categories. When creating a new service, it MUST fit one of these.

### 1. API/HTTP Services (Thin HTTP Wrappers)

**What they do**: Make HTTP calls against a backend API and return typed `Observable<T>`. No logic beyond URL building and optional header construction.

**Conventions**:
- `readonly #http = inject(HttpClient)` — only dependency
- `baseUrl` field built from `environment.apiBaseUrl`
- Methods return `Observable<T>` directly — no `.subscribe()`, no side effects
- Use `.pipe(share())` on calls that may be subscribed multiple times simultaneously (favorites, transfers, bulk operations)
- Use `HttpParams` for query parameter objects, `Params` type from `@angular/router` for filter params
- Use `HttpHeaders` for optional per-request headers (e.g., `Accept-Language`)
- One service per backend API domain: `UserService` for `/users`, `OrganizationService` for `/organizations`
- No `@UntilDestroy()` — services don't subscribe, so no cleanup needed

**Real examples**: `DataPublicationService`, `OrganizationService`, `UserService`, `StandardsService`, `InfoMessageService`, `NotificationsService`, `ExportService`, `StatisticsService`, `DataImportService`, `RegionsService`, `DatasetService`, `ExternalDataService`, `RequiredPublicationService`, `ObligationService`, `ImageService`

**Typical structure**:
```typescript
@Injectable({ providedIn: 'root' })
export class MyFeatureService {
  readonly #http = inject(HttpClient);

  baseUrl = `${environment.apiBaseUrl}/my-feature`;

  getAll(params?: Params): Observable<MyModel[]> {
    return this.#http.get<MyModel[]>(this.baseUrl, { params });
  }

  find(id: string): Observable<MyModel> {
    return this.#http.get<MyModel>(`${this.baseUrl}/${id}`);
  }

  create(model: MyModel): Observable<MyModel> {
    return this.#http.post<MyModel>(this.baseUrl, model);
  }

  update(model: MyModel): Observable<MyModel> {
    return this.#http.put<MyModel>(`${this.baseUrl}/${model.id}`, model);
  }

  delete(id: string): Observable<void> {
    return this.#http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```

**When to use `.pipe(share())`**:
```typescript
// Use share() when the caller may subscribe multiple times to the same emission
// (e.g., a repository that both subscribes AND returns the observable)
createFavorite(id: string): Observable<void> {
  return this.#http.post<void>(`${this.baseUrl}/${id}/favorite`, {}).pipe(share());
}
```

**Accept-Language header pattern** (for localized endpoints):
```typescript
find(id: string, acceptLanguage?: string): Observable<MyModel> {
  const headers = acceptLanguage ? new HttpHeaders({ 'Accept-Language': acceptLanguage }) : new HttpHeaders();
  return this.#http.get<MyModel>(`${this.baseUrl}/${id}`, { headers });
}
```

---

### 2. Complex API Services (Third-Party Integration or Multi-Step Orchestration)

**What they do**: Wrap API calls that require third-party coordination or multi-step RxJS orchestration before the HTTP call can be made.

**Conventions**:
- May inject external library services alongside `HttpClient`
- Use `switchMap` to sequence async steps (e.g., get token first, then call API)
- Still return `Observable<T>` — no subscribing

**Real examples**: `ContactService` (chains reCAPTCHA token → HTTP POST)

**Typical structure**:
```typescript
@Injectable({ providedIn: 'root' })
export class ContactService {
  readonly #http = inject(HttpClient);
  readonly #recaptcha = inject(ReCaptchaV3Service);

  baseUrl = `${environment.apiBaseUrl}/contact-request`;

  request(contactRequest: IContactRequest): Observable<void> {
    return this.#recaptcha.execute('contact').pipe(
      switchMap((token) =>
        this.#http.post<void>(this.baseUrl, { ...contactRequest, recaptchaToken: token })
      )
    );
  }
}
```

---

### 3. Authentication / Authorization Service

**What they do**: Wrap the NDW authentication library (`NdwAuthService`) and expose login state, token decoding, and domain-specific permission checks.

**This is a singleton service** that combines:
- Auth state as signals and observables (delegated from `NdwAuthService`)
- JWT decoding to extract user ID, organization ID, and permission roles
- Domain-specific permission check methods per entity type

**Conventions**:
- Inject `NdwAuthService`, `OAuthService`, and `UserRepository`
- Expose `isLoggedIn` as a **signal** (`toSignal`) for template use
- Expose `isLoggedIn$` as an **observable** for reactive chains
- Use `computed()` for derived signals (e.g., `isLoggedInNtmUser`)
- JWT decoding via `jwtDecode<KeycloakJwt>` — always reads from `OAuthService.getAccessToken()`
- `hasPermission(permissions[], oneOfPermission?)` for generic checks
- `hasPermissionToEdit*()` methods for entity-specific authorization rules
- Subscribe to `loginSuccess$` in constructor to trigger user fetch via repository

**Real example**: `AuthService`

**Note**: This category exists only once. Do not create additional auth-like services.

---

### 4. URL / Filter Coordination Services

**What they do**: Synchronize filter state with the URL via query parameters. Used by filter components and parent pages to update/read the active filters without tight coupling.

**Conventions**:
- Inject `Router` and `ActivatedRoute`
- Single method: `updateUrlParams(queryParams: Params): void`
- Use `router.navigate([], { relativeTo: route, queryParams, queryParamsHandling: 'merge' })`
- No state of their own — they write to the URL and let components react via `route.queryParams`
- No observables exposed — purely imperative

**Real examples**: `FiltersService`, `PublicationsFiltersService`, `StandardsFiltersService`

**Known duplication**: These three services are currently identical. When working with filter coordination, prefer injecting `FiltersService` from `shared/services/` as the general-purpose version. Feature-specific variants (`PublicationsFiltersService`, `StandardsFiltersService`) exist for historical reasons.

**Typical structure**:
```typescript
@Injectable({ providedIn: 'root' })
export class FiltersService {
  readonly #route = inject(ActivatedRoute);
  readonly #router = inject(Router);

  updateUrlParams(queryParams: Params): void {
    this.#router.navigate([], {
      relativeTo: this.#route,
      queryParams,
      queryParamsHandling: 'merge',
    });
  }
}
```

---

### 5. Framework Integration Services

**What they do**: Integrate with Angular's core framework mechanisms (router, title, meta tags) and coordinate with the translate service and repositories.

**Conventions**:
- May extend Angular built-ins (e.g., `TitleStrategy`)
- May listen to `NavigationEnd` events from `Router`
- Use `@UntilDestroy()` + `untilDestroyed()` if subscribing internally
- Do NOT hold domain data — read from repositories and forward to Angular services

**Real examples**: `TitleService` (extends `TitleStrategy`), `MetaService` (manages Open Graph tags)

**Title resolvers** (`title-resolvers.service.ts`) are a sub-pattern: they implement Angular's `Resolve<string>` interface and use `switchMap` to combine a translated title with entity data from a repository.

---

### 6. Utility / Helper Services (Stateless Computation or DOM Helpers)

**What they do**: Pure computation or DOM manipulation helpers with no HTTP calls and no application state.

**Conventions**:
- No `HttpClient`, no store, no repositories
- Methods take inputs and return outputs — no side effects where possible
- DOM-manipulating helpers use `DOCUMENT` / `WINDOW` injectables (from `ng-web-apis`) instead of accessing globals directly
- May use instance state only when needed for intermediate computation (not persistent state)

**Real examples**:
- `CollisionDetectionService` — calculates optimal floating element position using `getBoundingClientRect()` and applies CSS classes
- `ScrollLockService` — saves scroll position and toggles `no-scroll` CSS class on body
- `VisitService` — reads/writes `localStorage` and `sessionStorage` for welcome message state

---

## What Does NOT Belong in a Service

| Code type | Where it belongs instead |
|-----------|--------------------------|
| Elf store management | Repository (`*.repository.ts`) |
| `onHttpPending` / `onHttpSuccess` / `onHttpError` calls | Repository only |
| Subscribing to HTTP calls | Repository (services only return observables) |
| Toast notifications | Repository (via `BaseRepository`) |
| Route navigation beyond query params | Component or guard |
| Template/rendering logic | Component or pipe |
| Model-to-view transformation | Pipe (for pure display) |
| AG Grid column definitions | Component or constants file |
| Route guards | Guard file (`*.guard.ts`) |
| Single-use helper used only once | Private method in the component that uses it |

### Key Boundary: Service vs Repository

- **Service**: Does things — makes HTTP calls, orchestrates async steps, computes, coordinates
- **Repository**: Holds things — manages the Elf store, exposes state as observables, handles HTTP lifecycle via `BaseRepository`
- A repository injects a service to trigger HTTP calls
- A service never subscribes — it always returns `Observable<T>` and lets the repository subscribe
- A service may inject a repository to read existing state (e.g., `AuthService` reads `UserRepository`)
- Exception: `AuthService` calls `#userRepository.fetchLoggedInUser()` on login success — this is acceptable because it is a one-time lifecycle trigger, not ongoing state management

---

## Structural Conventions

### Injection
```typescript
readonly #http = inject(HttpClient);
readonly #someService = inject(SomeService);
```
Always `readonly`, always `#` private prefix, always `inject()`. Never constructor parameter injection.

### Scope
- Default: `@Injectable({ providedIn: 'root' })` — singleton for all services
- Never use component-level providers for services — use `@Injectable({ providedIn: 'root' })` universally

### Observable conventions
- HTTP services: methods return `Observable<T>`, no class-level fields for observables
- Auth/coordination services: class-level observable fields use `$` suffix: `isLoggedIn$`, `loggedInUser$`
- Signals (auth service only): no suffix — `isLoggedIn`, `isLoggedInNtmUser`

### Lifecycle cleanup
- API/HTTP services: no `@UntilDestroy()` needed — they never subscribe
- Services that subscribe internally (e.g., `AuthService`, `MetaService`, `TitleService`): use `@UntilDestroy()` + `untilDestroyed(this)`, or inject `DestroyRef` and use `takeUntilDestroyed(this.#destroyRef)`

### URL building
```typescript
baseUrl = `${environment.apiBaseUrl}/my-feature`;

// Subpath:   `${this.baseUrl}/${id}`
// Action:    `${this.baseUrl}/${id}/approve`
// Nested:    `${this.baseUrl}/${parentId}/children`
```
Always build `baseUrl` as a class field. Never hardcode full URLs inline in methods.

### Query parameters
```typescript
// From Params (route filters — most common)
getAll(params?: Params): Observable<T[]> {
  return this.#http.get<T[]>(this.baseUrl, { params });
}

// From explicit object (constructed in service)
getFiltered(status: string): Observable<T[]> {
  const params = new HttpParams().set('status', status);
  return this.#http.get<T[]>(this.baseUrl, { params });
}
```

---

## File Location

| Category | Location |
|----------|----------|
| Framework/infrastructure services | `core/services/` |
| Data access / API services | `core/data-access/{feature}/` |
| Shared utility services | `shared/services/` |
| Feature-specific non-HTTP services | `core/data-access/{feature}/` alongside the repository |

Services that have a paired repository live in the same folder:
```
core/data-access/publications/
  data-publication.service.ts     ← HTTP service
  data-publication.repository.ts  ← state management
  publications-filters.service.ts ← URL coordination
  types/
```

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| File | `{feature-name}.service.ts` (kebab-case) | `data-publication.service.ts` |
| Class | `{FeatureName}Service` (PascalCase) | `DataPublicationService` |
| `baseUrl` field | Always named `baseUrl` | `baseUrl = \`${environment.apiBaseUrl}/...\`` |
| Method names | Descriptive verb: what it does | `find`, `getAll`, `approve`, `transferOwnership` |
| HTTP field | Always `#http` | `readonly #http = inject(HttpClient)` |

---

## Complete Minimal Example

```typescript
import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Params } from '@angular/router';
import { environment } from '@env/environment';
import { Observable } from 'rxjs';
import { IMyModel } from './types';

@Injectable({
  providedIn: 'root',
})
export class MyFeatureService {
  readonly #http = inject(HttpClient);

  baseUrl = `${environment.apiBaseUrl}/my-feature`;

  getAll(params?: Params): Observable<IMyModel[]> {
    return this.#http.get<IMyModel[]>(this.baseUrl, { params });
  }

  find(id: string): Observable<IMyModel> {
    return this.#http.get<IMyModel>(`${this.baseUrl}/${id}`);
  }

  create(model: IMyModel): Observable<IMyModel> {
    return this.#http.post<IMyModel>(this.baseUrl, model);
  }

  update(model: IMyModel): Observable<IMyModel> {
    return this.#http.put<IMyModel>(`${this.baseUrl}/${model.id}`, model);
  }

  delete(id: string): Observable<void> {
    return this.#http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```
