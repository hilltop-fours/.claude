# chore(deps): #106891 upgrade Angular to v21

**Story:** #106891 / **Task:** #111487
**Branch:** `chore/106891/111487/upgrade-angular-v21`
**Date:** 2026-03-11

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

NTM upgrade to Angular 21

### Discussion

None

---

## Analysis

**Current state:**
- `@angular/core`: 20.3.7 (v20 LTS)
- `@angular/cdk`: ^20.2.10
- `@angular/cli` / `@angular/build`: 20.3.7
- `@angular-eslint/*`: 19.2.x
- `zone.js`: ^0.15.0
- `typescript`: 5.8.2
- Node.js: 22.22.1 ✅ (satisfies `^22.12.0` requirement for v21)

**Target:**
- `@angular/core`: 21.2.3 (latest stable as of 2026-03-11)
- `@angular-eslint/*`: 21.3.0
- `zone.js`: ~0.15.0 or ~0.16.0 (both accepted by v21)
- `typescript`: 5.8.2 stays (5.9.3 available but not required)
- `rxjs`: no change needed (^7.4.0 still compatible)

**No blockers:**
- Node version already satisfies v21 requirement
- zone.js current range resolves fine
- rxjs unchanged
- No NgModules to worry about (already standalone-first)

**Notable jump:** `@angular-eslint` goes from 19.2.x → 21.3.0 (two majors). Their schematics handle this — no manual rule fixes expected, but lint output should be checked after upgrade.

---

## Implementation Plan

### Step 1 — Create branch
```
git checkout -b chore/106891/111487/upgrade-angular-v21
```

### Step 2 — Run `ng update` for Angular core + CDK
```bash
cd ntm-frontend
npx ng update @angular/core@21 @angular/cli@21 @angular/cdk@21
```
- Updates all `@angular/*` packages atomically
- Runs built-in migration schematics (auto-fixes deprecated APIs)
- Updates `@angular-devkit/architect` and `@angular-devkit/core` in lockstep

### Step 3 — Update `@angular-eslint`
```bash
npx ng update @angular-eslint/schematics@21
```
- Updates all `@angular-eslint/*` packages together via schematics runner

### Step 4 — Build check
```bash
npm run build
```
Watch for: template type-checking tightenings, removed APIs, any v20→v21 breaking changes

### Step 5 — Lint check
```bash
npm run lint
```
Watch for: ESLint rule renames from the `@angular-eslint` major jump

### Step 6 — Test
```bash
npm test
```
Confirm no regressions in Jasmine unit tests

---

## Notes

- v20 is the active LTS line; v21 is the current "latest" but not LTS. v22 will be the next LTS (Angular releases LTS on even major versions).
- `ng update` runs migration schematics — always use it instead of manually editing `package.json`.
- After upgrade, `standalone: true` is still the default (was already default in v20) — no component changes needed for that.
