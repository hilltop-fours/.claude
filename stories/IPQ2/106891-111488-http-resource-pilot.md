# chore(http-resource): #106891 httpResource uitproberen

**Story:** #106891 / **Task:** #111488
**Branch:** `chore/106891/111488/http-resource-pilot`
**Date:** 2026-03-12

---

## Story — Original Text

### Description

Angular updates

### Acceptance Criteria

None

### Discussion

None

---

## Task — Original Text

### Description

httpResource uitproberen

### Discussion

None

---

## Analysis

**What this task is:** A learning spike on the experimental `httpResource` API from `@angular/common/http` (v21). Applied to the `/verplichte-publicaties` feature — both the overview and detail page — as a self-contained pilot with no shared state concerns.

**Why this page:** `RequiredPublicationsOverviewComponent` and `RequiredPublicationsDetailComponent` are ideal candidates:
- No elf store sharing — no other component reads this data
- Simple GET-only endpoints: `GET /api/data-regulations` and `GET /api/data-regulations/{type}`
- Detail page has a reactive URL (depends on `type` input signal) — perfect showcase of `httpResource` reactive refetch

**What was removed:**
- `RequiredPublicationRepository` — deleted entirely (elf store, `onHttpPending/Success/Error` boilerplate)
- `RequiredPublicationService` — deleted entirely (HttpClient wrapper)
- `toSignal()` + `HttpState` + `toResponse()` pattern — replaced with `httpResource`

**What was built:**

`HttpResourceService` (`core/services/http-resource.service.ts`) — singleton wrapper around `httpResource` that:
- Creates the resource with a typed URL function
- Registers an `effect()` via `{ injector: this.#injector }` to watch `resource.error()` and show a toast
- Returns the `HttpResourceRef<T | undefined>` directly to the component

Components use `this.#httpResourceService.get<T>(urlFn, errorKey)` — one line per fetch.

**Key learnings:**

1. `httpResource` always returns `T | undefined` — `undefined` during loading/idle. Use `hasValue()` as the template guard, `value()!` is safe inside `@if (resource.hasValue())`.
2. URL function returning `undefined` suppresses the request — used in detail page: `() => this.type() ? \`/api/data-regulations/${this.type()}\` : undefined`. Replaces the old `effect()` + repository call.
3. `httpResource` is GET-only by design. Never use for POST/PUT/DELETE.
4. Success toasts don't belong on GET resources — confirmed by codebase research: all `showSuccessToast` calls are on mutations (create/update/delete). Service has no success toast method.
5. `httpResource` is imported from `@angular/common/http`, not `@angular/core`.
6. The `effect()` inside the service needs `{ injector: this.#injector }` because it's created outside a component injection context.
7. Zod `parse` option was explored but rejected — `IDataRegulation` TypeScript interface already describes the shape. Runtime validation overhead not worth it for internal APIs.

**What `httpResource` replaces vs what stays:**

| Old | New |
|---|---|
| Repository + elf store | `httpResourceService.get()` |
| `toSignal()` in component | `httpResource` signal directly |
| `HttpState` loading/error flags | `resource.isLoading()`, `resource.error()`, `resource.hasValue()` |
| `effect()` to trigger refetch on param change | URL function with signal dependency |
| `onHttpError` toast | `effect()` in `HttpResourceService` |

**Status:** Experimental — `httpResource` marked `@experimental 19.2`. API may change before stable. Do not merge to main as production code.

---

## Implementation Plan

### Phase 1 — HttpResourceService
Create `src/app/core/services/http-resource.service.ts` with `get<T>(url, errorKey, options?)` method. Wires error toast via `effect({ injector })`.

### Phase 2 — Overview page
Replace `RequiredPublicationsOverviewComponent` to use `#httpResourceService.get<IDataRegulation[]>()`. Remove repository/toSignal/HttpState imports. Update template to use `regulationsResource.isLoading()` / `regulationsResource.hasValue()` / `regulationsResource.value()!`.

### Phase 3 — Detail page
Replace `RequiredPublicationsDetailComponent`. Reactive URL: `() => this.type() ? \`/api/data-regulations/${this.type()}\` : undefined`. Remove `effect()` + repository call. Computed signals read from `regulationResource.value()` directly — no intermediate signal needed.

### Phase 4 — Cleanup
Delete `required-publication.repository.ts` and `required-publication.service.ts`. Verify build passes.
