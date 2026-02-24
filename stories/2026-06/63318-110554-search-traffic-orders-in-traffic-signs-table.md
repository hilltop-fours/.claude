# feat(traffic-sign): #63318 #110554 Support search on verkeersbesluit, leveranciersID in traffic signs table

**Story:** #63318
**Task:** #110554
**Branch:** `feat/63318/110554/search-traffic-orders-in-traffic-signs-table`
**Date:** 2026-02-24

---

## Story — Original Text

### Description

Tabel met alle verkeersborden

in deze tabel kunnen zoeken op:
- verkeersbesluit
- leveranciersID
- ownercode

### Acceptance Criteria

naast wijzigingen tabel een knop voor alle borden
zelfde kolommen als wijzigingen tabel (+ drie kolommen zoals hierboven en NDW ID)

### Discussion

Ruth Alkema (6h ago): Jojuist in de daily besproken dat we van het zoeken op ownercode een deel 2 gaan maken

Ruth Alkema (7h ago, edited): Voorstel:
- Dus een extra knop naast 'toon wijzigingen tabel'. Andere mogelijkheid: verander de knop die er al is in 'toon tabel', en maak dan iets met twee tabbladen, 1 voor wijzigingen en 1 voor de borden.
- De tabel zelf bevat dan de kolommen zoals genoemd in acceptance criteria, dus:
  - datum (niet nodig, alleen handig voor de mutaties)
  - wegbeheerder
  - rvv code
  - verkeersbesluit
  - leveranciers ID
  - acties ?

---

## Task — Original Text

### Description
See story

### Discussion
None

---

## Analysis

### What this story is about

Add a new "Alle borden" table next to the existing "Wijzigingen" mutations table. The table shows all traffic signs (not just mutations), with search/filter support on `verkeersbesluit`, `leveranciersID`, and `NDW ID` (ownercode deferred to deel 2).

### Clarifications agreed

- **Columns**: Ruth's proposal — no datum column (only useful for mutations). Columns: wegbeheerder (type + code), rvv code, verkeersbesluit, leveranciers ID, NDW ID, acties
- **UI layout**: Extra button "Toon alle borden" next to "Toon wijzigingen tabel" — each opens its own table, not simultaneously
- **Backend**: NOT merged — mock the `verkeersbesluit` and `leveranciersID` search filters for now
- **NDW ID**: The internal `id` field (UUID) of the traffic sign

### Data model mapping

| Column | Source field | Notes |
|--------|-------------|-------|
| Wegbeheerder soort | `ownerRoadAuthorityType` | `RoadAuthorityType` enum |
| Wegbeheerder code | `ownerRoadAuthorityCode` | string |
| RVV code | `rvvCode` | `RvvCode` enum |
| Verkeersbesluit | `details.trafficOrderUrl` | URL string |
| Leveranciers ID | `externalIds[0].id` | from `externalIds[]` array (system + id) |
| NDW ID | `id` | UUID |
| Acties | — | zoom + select buttons (RowActionsComponent) |

### Backend search support

- `trafficOrderUrl` search: backend `TrafficSignCriteria` already has `trafficOrderIds` field, but `TrafficSignsParams` in frontend doesn't expose it yet → add to params when mocking
- `externalId` search: NOT in `TrafficSignCriteria` yet → pure mock on frontend
- Service: `TrafficSignService.getAll()` → `GET /api/traffic-signs`

### Key files for this feature

**Toggle button + state**:
- `traffic-sign-layer-selection.component.html/ts` — "Toon wijzigingen tabel" button + `toggleMutationsTable()` method
- `overview-map.repository.ts` — `changesVisibleForElement: MapElementEnum | undefined` state (Elf store)

**Layout + rendering**:
- `road-feature-overview.component.html` — `@switch (changesVisibleForElement())` renders the correct table
- `road-feature-overview.component.scss` — CSS grid: `--show-table` class shows the table panel

**Existing mutations table (to copy architecture from)**:
- `traffic-sign-mutations-table/traffic-sign-mutations-table.component.ts/html/scss`
- `traffic-sign-mutation.service.ts` — datasource for mutations
- `traffic-sign-mutation.repository.ts` — Elf store persisting filter/column state to localStorage

**Reusable shared components**:
- `page-size-status-panel.component.ts` — AG Grid status bar: page size
- `pagination-status-panel.component.ts` — AG Grid status bar: pagination
- `row-actions.component.ts` — cell renderer: zoom + select buttons
- `abstract-list.component.ts` — base class: `initGridApi()`, `resetTable()`
- `ag-grid.service.ts` — translates AG Grid request to Spring pagination HTTP params

**Data service for new table**:
- `traffic-sign.service.ts` → `getAll()` → `GET /api/traffic-signs`
- `traffic-sign.interface.ts` — `TrafficSign` model with all fields

**New files to create**:
- `traffic-sign-all-table.component.ts/html/scss` — new AG Grid table component
- `traffic-sign-all-table.repository.ts` — Elf store for persisting filter/column state
- New `MapElementEnum` value: `TrafficSignAll` (or reuse `TrafficSign` with a sub-view)

### MapElementEnum consideration

Currently `MapElementEnum.TrafficSign` toggles the mutations table. Since we're adding a separate button (not tabs), we likely need a new enum value like `MapElementEnum.TrafficSignAll` to track which table is open, or we could store both as `changesVisibleForElement` only holds one value at a time.

---

## Implementation Plan

### Phase 1: Models, enum, and component shell

- Add `TrafficSignAll` to `MapElementEnum`
- Create `TrafficSignAllTableComponent` shell (empty AG Grid, no data yet)
- Add new toggle button "Toon alle borden" in `traffic-sign-layer-selection.component.html`
- Wire button to set `changesVisibleForElement = MapElementEnum.TrafficSignAll`
- Add `@case (mapElementEnum.TrafficSignAll)` in `road-feature-overview.component.html`
- Register new component in barrel exports

WIP commit after Phase 1.

### Phase 2: Dev tools + mock service

- Mock `TrafficSignService.getAll()` in a dev-tools service to return fake traffic signs with `trafficOrderUrl`, `externalIds`, and `id` fields populated
- Ensure the mock returns enough rows to test pagination

WIP commit after Phase 2.

### Phase 3: Table implementation

- Implement `TrafficSignAllTableComponent` fully:
  - Column defs: wegbeheerder soort, wegbeheerder code, rvv code, verkeersbesluit (trafficOrderUrl), leveranciers ID (externalIds[0].id), NDW ID (id), acties
  - Server-side AG Grid datasource using `TrafficSignService.getAll()`
  - Search/filter inputs for: verkeersbesluit (text), leveranciers ID (text), NDW ID (text)
  - Reuse `PageSizeStatusPanel`, `PaginationStatusPanel`, `RowActions`
  - Extend `AbstractListComponent`
- Create `TrafficSignAllTableRepository` (Elf store) to persist filter/column state

WIP commit after Phase 3.

### Phase 4: Polish and wire-up

- Close button (sets `changesVisibleForElement = undefined`)
- Export CSV button
- Reset button (clears filters)
- Ensure "Toon alle borden" and "Toon wijzigingen tabel" are mutually exclusive (opening one closes the other — already handled by single `changesVisibleForElement` signal)
- Style: same layout as mutations table

WIP commit after Phase 4.
