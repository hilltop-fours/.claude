# NTM Publicatie Overzicht — Project Context

Machine-optimized. Claude-facing only.

**Frontend**: `ntm-frontend/src/` (edit only here)
**Backends**: `ntm-backend`, `ntm-tracker-backend` (reference only)
**Design system**: `ndw-design/` (reference only)

---

## Design System

Location: `/ndw-design/libs/ntm`
Import: `import { ComponentName } from '@shared/components/component-name'`

Rules:
- Default to design system components for UI elements — assume they exist
- NEVER hardcode strings/values that exist in component models
- Search design system before creating custom components

---

## Language Rules

- Code & comments: English
- Commit messages: English (see `$CLAUDE_ROOT/global/git.md`)
- UI text: Dutch via ngx-translate (`@ngx-translate/core`)
- NEVER hardcode Dutch strings — always use translation keys: `{{ 'KEY' | translate }}`

**Translation files**: `src/i18n/nl.json` (Dutch) + `src/i18n/en.json` (English)
- ALL new keys must be in BOTH files
- Use descriptive namespaced keys

---

## Filter Components — Query Params Pattern

Filter components MUST subscribe to `route.queryParams` and reactively update state when params change. Parent clears filters by updating URL — child components react automatically.

```typescript
// ✅ CORRECT — reactive subscription
this.route.queryParams.pipe(untilDestroyed(this)).subscribe((params) => {
  const activeFilters = params[this.queryParamName]?.split(',') || [];
  this.#updateOptions(activeFilters);
});

// ❌ WRONG — one-time snapshot in ngOnInit
ngOnInit() {
  const activeFilters = this.getActiveFiltersFromQueryParams(); // snapshot only!
}

// ✅ CORRECT parent clear
clearFilters() { this.#filtersService.updateUrlParams({ [QUERY_PARAMS.MY_FILTER]: null }); }
// ❌ WRONG parent clear
clearFilters() {
  this.#filtersService.updateUrlParams({ ... });
  this.filterComponents().forEach((f) => f.deselectAll()); // tight coupling
}
```

Reference examples: `data-import-filter-date.component.ts`, `search-input.component.ts`, `publication-review-filter-status.component.ts`

---

## Backend API Mapping

Backend docs are 100% authoritative ground truth.

| Feature | Backend doc |
|---------|------------|
| Data Publications (CRUD, search, approve, reject, hold, transfer, favorites, import) | `backend/ntm-backend.md` |
| Datasets (listing only: `/datasets`) | `backend/ntm-backend.md` |
| Datasets (import, reject, detail: `/datasets/**`) | `backend/ntm-tracker-backend.md` |
| Organizations (CRUD, roles, users, logos, permissions, repair) | `backend/ntm-backend.md` |
| Users (CRUD, current user, password reset) | `backend/ntm-backend.md` |
| Notifications & Subscriptions | `backend/ntm-backend.md` |
| Favorites | `backend/ntm-backend.md` |
| Regions & Municipalities | `backend/ntm-backend.md` |
| Standards | `backend/ntm-backend.md` |
| Data Regulations | `backend/ntm-backend.md` |
| Statistics | `backend/ntm-backend.md` |
| Export | `backend/ntm-backend.md` |
| Info Messages | `backend/ntm-backend.md` |
| Blobs / Images | `backend/ntm-backend.md` |
| Contact Requests | `backend/ntm-backend.md` |
| Translations | `backend/ntm-backend.md` |
| DCAT (`/v1/**`) | `backend/ntm-backend.md` |
| External Organizations | `backend/ntm-tracker-backend.md` |
| External Categories | `backend/ntm-tracker-backend.md` |

**Endpoint → backend quick reference:**
- `/data-publications/**`, `/organizations/**`, `/users/**`, `/notifications/**`, `/subscriptions/**`, `/favorites/**`, `/regions/**`, `/standards/**`, `/data-regulations/**`, `/statistics/**`, `/export/**`, `/info-messages/**`, `/blobs/**`, `/contact-request`, `/translations/**`, `/v1/**`, `/datasets` → `ntm-backend.md`
- `/datasets/**`, `/external-organizations/**`, `/external-categories/**` → `ntm-tracker-backend.md`

---

## Pattern Documentation

| Context | Read |
|---------|------|
| `*.service.ts` files | `patterns/service-patterns.md` |
| `*.repository.ts` files | `patterns/repository-patterns.md` |
| Accessible forms (WCAG 3.3.1) | `patterns/form-accessibility.md` |
| Query params, routing, deep linking | `patterns/query-params.md` |

---

## Backend Service Registry (for backend-update workflow)

| Backend | Repo path |
|---------|-----------|
| ntm-backend | `/Users/daniel/Developer/NTM-Publicatie-overzicht/ntm-backend/` |
| ntm-tracker-backend | `/Users/daniel/Developer/NTM-Publicatie-overzicht/ntm-tracker-backend/` |
