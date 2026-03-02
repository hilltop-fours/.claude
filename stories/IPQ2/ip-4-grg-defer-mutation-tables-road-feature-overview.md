# chore(ip-sprint): IP-4 Add @defer to 14 mutation tables in RoadFeatureOverviewComponent

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-4-grg-defer-mutation-tables-road-feature-overview`
**Project:** GRG (`traffic-sign-frontend`)
**Date:** 2026-03-02
**Difficulty:** Medium
**Estimated days:** 2

---

## Learning Objective

Learn Angular's **deferrable views (`@defer`)** — one of the most impactful performance features introduced in Angular 17:

- **`@defer (when condition)`** — defers a block of template until a boolean condition becomes true. The block's components are NOT compiled, NOT included in the initial JavaScript bundle, and NOT rendered until the condition is met.
- **`@defer (on viewport)`** — defers until the placeholder element scrolls into the viewport. Great for below-the-fold content.
- **`@defer (on interaction)`** — defers until the user interacts with the placeholder.
- **`@placeholder`** sub-block — what is shown before the deferred block loads (lightweight content, no JS cost)
- **`@loading`** sub-block — what is shown while the deferred content is loading (can have `minimum` duration to prevent flicker)
- **`@error`** sub-block — what is shown if the deferred block fails to load

Understand the **key mental model**: `@defer` is not just a visibility toggle — it is a **code-splitting boundary**. Angular's build tool treats each `@defer` block as a separate lazy chunk. The components inside it are not imported in the parent component's `imports: []` array at all — they are loaded only when the defer trigger fires.

Understand how to **verify** that defer blocks are actually split by the build: Angular 17+ with the application builder outputs separate chunk files for deferred components. You can see this in the build output or in Angular DevTools' component tree (deferred blocks are marked).

---

## Learning Context

### The problem: 14 eagerly imported components that are mutually exclusive

File: `traffic-sign-frontend/src/app/modules/features/pages/overview/road-feature-overview.component.ts`

This component currently has an `imports: []` array that includes all 14 mutation table components:

- `AxleLoadRestrictionMutationsTableComponent`
- `CarriagewayTypeMutationsTableComponent`
- `DrivingDirectionMutationsTableComponent`
- `HeightRestrictionMutationsTableComponent`
- `HgvChargeMutationsTableComponent`
- `LengthRestrictionMutationsTableComponent`
- `LoadRestrictionMutationsTableComponent`
- `RoadAuthorityMutationsTableComponent`
- `RoadCategoryMutationsTableComponent`
- `RoadNarrowingMutationsTableComponent`
- `RvmMutationsTableComponent`
- `SchoolZoneMutationsTableComponent`
- `SpeedLimitMutationsTableComponent`
- `TrafficTypeMutationsTableComponent`

Each of these is a fully-featured AG Grid component with its own services, column definitions, and state management. They are only visible one at a time — the user selects a map element type (e.g. "speed limit"), and only the corresponding mutations table is shown. In a typical session, a user might open 1-2 of these tables.

Despite this, all 14 are in the initial JavaScript bundle. Every user downloads the JavaScript for all 14 tables on page load, even if they never use most of them.

### How they're currently shown/hidden

In `road-feature-overview.component.html`, the tables are conditionally rendered using `@switch (changesVisibleForElement())` or `@if` conditions. The `changesVisibleForElement` is a signal from `OverviewMapElementRepository` that holds a `MapElementEnum | undefined` value.

The pattern looks roughly like:
```html
@switch (changesVisibleForElement()) {
  @case (mapElementEnum.SpeedLimit) {
    <app-speed-limit-mutations-table />
  }
  @case (mapElementEnum.ParkingBan) {
    <app-parking-ban-mutations-table />
  }
  <!-- ... 12 more cases -->
}
```

The component is conditionally shown, but not deferred — the JavaScript for all 14 is still in the bundle.

### The @defer solution

With `@defer (when condition)`, each table's component code is split into its own lazy chunk and only downloaded + compiled when the condition becomes true. The change looks like this:

```html
@defer (when changesVisibleForElement() === mapElementEnum.SpeedLimit) {
  <app-speed-limit-mutations-table />
} @placeholder {
  <!-- empty or lightweight skeleton -->
} @loading (minimum 100ms) {
  <div>Loading...</div>
}
```

Because the component is no longer in the `imports: []` array, it is automatically code-split by the Angular build tool.

### What changes in the component class

When a component is deferred in the template, it must be **removed from the `imports: []` array** in the component decorator. Angular's compiler handles the import automatically when it processes the `@defer` block. If you leave the component in `imports: []`, it stays in the main bundle and defeats the purpose.

This is the main "gotcha" that developers miss. The test: after the change, run `npm run build` and look for lines like:
```
chunk-XXXXXXXX.js   45 kB  (lazy)
```
Those are the deferred components being split out.

### What @placeholder and @loading should contain

For this use case, the placeholder and loading states can be minimal:
- `@placeholder`: empty or a one-line comment (the table panel is only shown when active, so there's nothing to show "before" the table loads)
- `@loading (minimum 100ms)`: a simple loading indicator — just enough to prevent a flash of empty content if the component loads quickly but not instantly

Don't over-engineer the loading state. The goal is correctness and learning the API, not designing a perfect skeleton screen.

### Performance impact

This change does not affect the user experience in any perceptible way — the tables load fast enough that the defer overhead is negligible. The real benefit is **initial bundle size reduction**: all 14 table components and their transitive dependencies are removed from the main chunk. On a slow connection or a mobile device, this reduces time-to-interactive for the initial page load.

Use Angular DevTools or the build output to confirm the split actually happened.

---

## Analysis

### Files to change

| File | Action |
|------|--------|
| `traffic-sign-frontend/src/app/modules/features/pages/overview/road-feature-overview.component.html` | Wrap each `@case` or `@if` with `@defer (when condition)` + `@placeholder` + `@loading` |
| `traffic-sign-frontend/src/app/modules/features/pages/overview/road-feature-overview.component.ts` | Remove all 14 mutation table components from `imports: []` array |

### What NOT to change

- The `@switch`/`@if` conditions themselves — `@defer` wraps around them, doesn't replace them
- The routing or state management — `changesVisibleForElement()` signal stays as-is
- Any of the 14 table component files themselves — they are not modified

### Things to figure out during implementation

- Does the template use `@switch` or `@if` for the table visibility? Read the template before assuming. If it's `@switch`, you may need to restructure to `@defer` blocks since `@defer` wraps component usage, not switch cases.
- What is the exact signal/property that drives visibility for each table? Map the 14 tables to their conditions.
- Does any table need to stay eagerly loaded (e.g. one that's shown immediately on page load for certain roles)? If so, leave that one without `@defer`.

### Acceptance criteria

- All 14 mutation table components removed from `imports: []` in `RoadFeatureOverviewComponent`
- Each table wrapped in a `@defer (when isVisible)` block with a meaningful condition
- Each `@defer` block has a `@placeholder` and `@loading` sub-block
- Build output shows the table components split into separate lazy chunks (check for `(lazy)` annotation in build output)
- UI behavior unchanged: tables appear when the correct map element is selected, disappear when deselected
- No TypeScript errors, build passes

---

## Implementation Plan

### Phase 1: Read and map the template

Read `road-feature-overview.component.html` in full. Document:
- How each table is currently shown/hidden (exact condition for each of the 14 tables)
- Whether `@switch`, `@if`, or a combination is used
- What signal or property drives each condition

Read `road-feature-overview.component.ts` in full. List all 14 mutation table components currently in `imports: []`.

No code changes in this phase.

### Phase 2: Add @defer to all 14 tables

For each table, wrap its template usage in `@defer (when condition) { ... } @placeholder { } @loading (minimum 100ms) { }`. Keep the conditions identical to the current `@switch/@if` conditions — just add the `@defer` wrapper.

Remove all 14 table components from the `imports: []` array.

WIP commit after Phase 2.

### Phase 3: Verify code splitting

Run `npm run build` from `traffic-sign-frontend`. Look at the build output for `(lazy)` chunks. Confirm the 14 tables are no longer in the main bundle. If any remain in the main bundle, investigate why (likely still in `imports: []` or imported elsewhere in a non-deferred path).

Document findings — what was the approximate size reduction? This is useful for your personal retrospective on the sprint.

### Phase 4: Manual test all tables

Open the application. Select each of the 14 map element types and verify the corresponding table appears correctly. Check browser DevTools Network tab — you should see separate JS chunk files loading when you open each table for the first time.

WIP commit after Phase 4.
