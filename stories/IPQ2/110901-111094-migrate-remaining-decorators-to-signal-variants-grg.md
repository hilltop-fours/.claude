# chore(signals): #110901 #111094 migrate remaining decorators to signal variants (GRG)

**Story:** #110901 / **Task:** #111094
**Branch:** `chore/110901/111094/migrate-remaining-decorators-to-signal-variants-grg`
**Date:** 2026-03-10

---

## SCOPE BOUNDARY — STRICT

**This story replaces decorator syntax with signal equivalents, in small safe phases. GRG is more sensitive than NTM — changes are kept minimal and independently verifiable per phase.**

### What is IN scope

| Change | Phase | Notes |
|--------|-------|-------|
| `@Input()` → `input()` | Phase 1 | Update template reads to `foo()` |
| `@Output()` → `output()` | Phase 1 | Keep `EventEmitter` only if something `.pipe()`s it |
| `@Input` + `@Output xChange` pair → `model()` | Phase 1 | Only 2 candidates: `collapsible` + `speed-limit-control` |
| `ngOnChanges` → `effect()` | Phase 2 | **Forced** — signal inputs break `ngOnChanges`. 14 files affected. Separate PRs per component group. |

### What is OUT of scope — do NOT touch

| Pattern | Reason |
|---------|--------|
| `@ViewChild` / `@ViewChildren` / `@ContentChildren` | Not present in GRG codebase — nothing to do |
| `@HostBinding()` / `@HostListener()` | Not present in GRG codebase — nothing to do |
| `ChangeDetectorRef` removal | Only remove if migration makes it dead code. Most cdr files are unrelated to input/output. Do not proactively remove. |
| Getter/setter → `signal()` | Separate story — not forced by decorator migration |
| Plain getters → `computed()` | Separate story — not forced by decorator migration |
| Plain mutable properties → `signal()` | Separate story |
| `BehaviorSubject` cleanup | Covered by story #110901 original scope (separate concern) |
| `Observable` + `async` pipe → `toSignal()` | Separate architectural decision |
| `ChangeDetectionStrategy.OnPush` additions | Separate story |
| `ngOnInit`, `ngAfterViewInit`, `ngOnDestroy` | Not forced by decorator migration — leave as-is |
| `takeUntilDestroyed` additions | Unrelated to decorator migration |
| Any logic inside lifecycle hooks | Not a decorator change |

**The test:** if a change would not be required to keep the component compiling and working after the decorator swap, it does not belong in this PR.

---

## Codebase Scan Results (2026-03-10)

| Pattern | Count |
|---------|-------|
| `@Input()` | 27 files |
| `@Output()` | 35 files |
| `model()` candidates (`@Input` + `@Output xChange`) | 2 files |
| `ngOnChanges` | 14 files |
| `@ViewChild/Children/ContentChildren` | 0 — not in GRG |
| `@HostBinding/Listener` | 0 — not in GRG |
| `ChangeDetectorRef` | 6 files (mostly unrelated to input/output) |

### model() candidates

1. `app/shared/components/collapsible/collapsible.component.ts`
   - `@Input() open` + `@Output() openChange` → `readonly open = model(false)`

2. `app/modules/road-feature/components/overview/feature-forms/speed-limit/speed-limit-control/speed-limit-control.component.ts`
   - `@Input() ...` + `@Output() speedLimitChange` → `readonly speedLimit = model<ESpeedLimit>()`
   - Note: verify the input name matches the output name minus `Change` — may need renaming

---

## Per-File Migration Checklist

Apply to every file touched in Phase 1. Go through each item in order.

### 1. `@Input()` → `input()`
- `@Input() foo: Type` → `readonly foo = input<Type>()`
- `@Input() foo: Type = default` → `readonly foo = input(default)`
- `@Input({ required: true }) foo!: Type` → `readonly foo = input.required<Type>()`
- Update template: `foo` → `foo()` everywhere the input is read
- Update TS: `this.foo` → `this.foo()` everywhere the input is read in the class body
- Remove `Input` from `@angular/core` import if no longer used

### 2. `@Output()` → `output()`
- `@Output() foo = new EventEmitter<Type>()` → `readonly foo = output<Type>()`
- `this.foo.emit(value)` stays the same ✓
- Remove `Output`, `EventEmitter` from import if no longer used
- **Exception:** keep `EventEmitter` if something subscribes to it with `.pipe()`

### 3. `@Input()` + `@Output() xChange` → `model()`
- Replace both with: `readonly x = model(defaultValue)`
- Internal emits: `this.xChange.emit(value)` → `this.x.set(value)`
- Parent template: `[x]="val" (xChange)="val=$event"` → `[(x)]="val"`
- Add `model` to import, remove `Input`, `Output`, `EventEmitter` if no longer needed

### 4. `ngOnChanges` check (per file, after steps 1–3)
- If the component has `ngOnChanges`: **do not remove it in Phase 1**
- Mark it as "needs Phase 2 treatment" — Phase 2 converts it to `effect()`
- Exception: if `ngOnChanges` is empty or only watches inputs that are now signals and does nothing meaningful → can remove in Phase 1, but be careful

### 5. `ChangeDetectorRef` check (per file)
- Only remove if ALL `cdr.detectChanges()` calls are now dead code after steps 1–3
- If still used for any reason → leave it completely untouched

### 6. `readonly` audit
- Every `input()`, `output()`, `model()` must be `readonly`

### 7. Private `#` audit
- Injected services should use `#` prefix — but only fix if already touching the class

---

## PR Tracking Table

One row per group. Update as work progresses.

| # | Group | Scope | Task title (Azure DevOps) | Branch | PR | Merged |
|---|-------|-------|--------------------------|--------|----|--------|
| A | `shared/` — input/output/model (safe) | `shared` | `[FE] signals: shared components input output` | `chore/110901/111400/signals-shared-components-input-output` | open | — |
| B | `mutations-table/` — output only (safe) | `mutations-table` | `[FE] signals: mutations table components input output` | `chore/110901/111401/signals-mutations-table-components-input-output` | open | — |
| C | `detail-cards/` — input/output (safe) | `detail-cards` | `[FE] signals: detail card components input output` | — | — | — |
| D | `feature-forms/` simple — input/output/model (safe) | `feature-forms` | `[FE] signals: feature form components input output` | — | — | — |
| E | `shared/` — input + ngOnChanges (coupled) | `shared` | `[FE] signals: shared components input output effect` | — | — | — |
| F | `multi-select/` + `multi-*-list-item/` — input + ngOnChanges (coupled) | `multi-select` | `[FE] signals: multi-select components input output effect` | — | — | — |
| G | `feature-forms/` — input + ngOnChanges (coupled) | `feature-forms` | `[FE] signals: feature form components input output effect` | — | — | — |

> **Branch format:** `chore/110901/{task-id}/{kebab-case-scope}`
> **Commit format (squashed PR title):** `chore({scope}): #110901 #{task-id} description`
>
> **Workflow per group:** Do the migration first (edit files), then commit directly with the PR title format — no WIP commits. Squash = commit immediately as PR title.

---

## Phase 1 — `@Input()` / `@Output()` / `model()` — safe files (no ngOnChanges)

**Goal:** Replace decorator-based inputs and outputs in files with NO `ngOnChanges`. Fully self-contained — no forced follow-up work per PR.

---

### Group A — `shared/` components
Safe: no ngOnChanges. Contains 1 `model()` candidate.

| File | @Input | @Output | Notes |
|------|--------|---------|-------|
| `app/shared/components/collapsible/collapsible.component.ts` | ✓ | ✓ `openChange` | **model candidate** → `open` + `openChange` → `model(false)` |
| `app/shared/components/detail-page-header/detail-page-header.component.ts` | ✓ | ✓ | — |
| `app/shared/components/edit-bar/edit-bar.component.ts` | ✓ | ✓ | — |
| `app/shared/components/upload-page-header/upload-page-header.component.ts` | ✓ | — | — |

---

### Group B — `mutations-table/` components
Safe: output-only, no ngOnChanges. 13 files, mechanically identical.

| File |
|------|
| `app/modules/road-feature/components/overview/mutations-table/school-zone/school-zone-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/rvm/rvm-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/speed-limit/speed-limit-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/traffic-types/traffic-type-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/road-authority/road-authority-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/road-category/road-category-mutations-table-component.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/road-narrowing/road-narrowing-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/length-restriction/length-restriction-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/load-restriction/load-restriction-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/driving-direction/driving-direction-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/height-restriction/height-restriction-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/axle-load-restriction/axle-load-restriction-mutations-table.component.ts` |
| `app/modules/road-feature/components/overview/mutations-table/carriageway-type/carriageway-type-mutations-table.component.ts` |

---

### Group C — `detail-cards/` components
Safe: no ngOnChanges.

| File | @Input | @Output |
|------|--------|---------|
| `app/modules/road-feature/components/overview/detail-cards/feature-title/feature-title.component.ts` | ✓ | — |
| `app/modules/road-feature/components/overview/detail-cards/details-base/details-base.component.ts` | ✓ | ✓ |
| `app/modules/road-feature/components/overview/detail-cards/school-zone-details/school-zone-details.component.ts` | — | ✓ |
| `app/modules/road-feature/components/overview/detail-cards/school-zone-details-display/school-zone-details-display.component.ts` | — | ✓ |

---

### Group D — `feature-forms/` simple components (no ngOnChanges)
Safe: no ngOnChanges. Contains 1 `model()` candidate.

| File | @Input | @Output | Notes |
|------|--------|---------|-------|
| `app/modules/road-feature/components/overview/feature-forms/school-zone/school-zone-form/school-zone-form.component.ts` | ✓ | — | — |
| `app/modules/road-feature/components/overview/feature-forms/rvm/rvm-type-select/rvm-type-select.component.ts` | ✓ | — | — |
| `app/modules/road-feature/components/overview/feature-forms/road-category/road-category-control/road-category-control.component.ts` | ✓ | — | — |
| `app/modules/road-feature/components/overview/feature-forms/road-category/road-category-form/road-category-form.component.ts` | — | ✓ | — |
| `app/modules/road-feature/components/overview/feature-forms/driving-direction/driving-direction-select/driving-direction-select.component.ts` | ✓ | — | — |
| `app/modules/road-feature/components/overview/feature-forms/feature-form-base/feature-form-base.component.ts` | ✓ | ✓ | — |
| `app/modules/road-feature/components/overview/feature-forms/speed-limit/speed-limit-control/speed-limit-control.component.ts` | ✓ | ✓ `speedLimitChange` | **model candidate** — verify input name matches output minus `Change` |
| `app/modules/road-feature/components/overview/feature-forms/speed-limit/speed-limit-form-array/speed-limit-form-array.component.ts` | ✓ | ✓ | — |

**Verification after each group:** `npm run build` from `traffic-sign-frontend/` — 0 errors.

---

## Phase 2 — `@Input()` / `@Output()` + `ngOnChanges` → `effect()` — coupled files

**Goal:** These files have BOTH `@Input()` AND `ngOnChanges`. Input migration and `ngOnChanges` fix MUST ship in the same PR — shipping input migration alone silently breaks behavior.

**How to convert `ngOnChanges` per file:**
- Convert `@Input()` → `input()` first
- Replace `ngOnChanges(changes: SimpleChanges)` with `effect(() => { ... })` as a class field or in constructor
- Read signal inside effect: `this.foo()`
- Remove `OnChanges`, `SimpleChanges` from import if unused
- **Initial run warning:** `effect()` fires immediately on construction with the current value. If old `ngOnChanges` guarded with `if (changes.foo.isFirstChange()) return` — restructure accordingly. Read each file carefully before converting.

---

### Group E — `shared/` components with ngOnChanges (coupled)

| File | ngOnChanges watches |
|------|-------------------|
| `app/shared/components/sprite-image/sprite-image.component.ts` | `code` → calls `#setSpriteStyle()` |
| `app/shared/components/traffic-sign-image/traffic-sign-image.component.ts` | `trafficSignImageId` → calls `getImage()` |

---

### Group F — `multi-select/` + `multi-*-list-item/` with ngOnChanges (coupled)
All watch `roadSectionFeature` — pattern is identical across all 6 files.

| File |
|------|
| `app/modules/road-feature/components/overview/multi-select/multi-driving-direction-item/multi-driving-direction-item.component.ts` |
| `app/modules/road-feature/components/overview/multi-select/multi-carriageway-type-item/multi-carriageway-type-item.component.ts` |
| `app/modules/road-feature/components/overview/feature-forms/speed-limit/multi-speed-limit-list-item/multi-speed-limit-list-item.component.ts` |
| `app/modules/road-feature/components/overview/feature-forms/rvm/multi-rvm-list-item/multi-rvm-list-item.component.ts` |
| `app/modules/road-feature/components/overview/feature-forms/road-category/multi-road-category-list-item/multi-road-category-list-item.component.ts` |
| `app/modules/road-feature/components/overview/feature-forms/hgv-charge/multi-hgv-charge-list-item/multi-hgv-charge-list-item.component.ts` |

---

### Group G — `feature-forms/` form components with ngOnChanges (coupled)
5 watch `disableForm` (identical pattern), 1 watches `maxLength`.

| File | ngOnChanges watches |
|------|-------------------|
| `app/modules/road-feature/components/overview/feature-forms/speed-limit/speed-limit-form/speed-limit-form.component.ts` | `maxLength` |
| `app/modules/road-feature/components/overview/feature-forms/road-narrowing/road-narrowing-form/road-narrowing-form.component.ts` | `disableForm` |
| `app/modules/road-feature/components/overview/feature-forms/load-restriction/load-restriction-form/load-restriction-form.component.ts` | `disableForm` |
| `app/modules/road-feature/components/overview/feature-forms/length-restriction/form/length-restriction-form.component.ts` | `disableForm` |
| `app/modules/road-feature/components/overview/feature-forms/height-restriction/height-restriction-form/height-restriction-form.component.ts` | `disableForm` |
| `app/modules/road-feature/components/overview/feature-forms/axle-load-restriction/form/axle-load-restriction-form.component.ts` | `disableForm` |

**Verification after each group:** `npm run build` — 0 errors. Manually test affected feature in browser.

---

## Story — Original Text

### Description

GRG [FE] overgebleven inputs en outputs migreren naar signal variants

### Acceptance Criteria

(Not provided in Azure DevOps — derived from IPQ2 research file IP-8)

### Discussion

None

---

## Task — Original Text

### Description

overgebleven @ decorators migreren naar signal variants

### Discussion

None

---

## Reference

- NTM equivalent story: `110904-111093-overgebleven-decorators-migreren-naar-signal-variants-ntm.md`
- IPQ2 research: `ip-8-grg-modernize-old-angular-patterns.md`
- Related GRG stories (separate scope): IP-2 (NgRx Signals store), IP-4 (@defer), IP-5 (BaseMutationRepository), IP-7 (detail card base generics)
