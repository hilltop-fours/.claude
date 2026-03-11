# [FE] NTM — SonarQube ESLint rules

**Story:** #84569 / **Task:** #111426
**Branch:** `chore/84569/111426/sonarqube-eslint-rules`
**Date:** 2026-03-11

---

## Story — Original Text

### Description

No description provided in Azure DevOps.

Context (from discussion): SonarQube enforces certain rules that cause build errors after the fact. The goal is to configure ESLint to surface these same rules as warnings during development, so violations are caught in the IDE while programming — not discovered late after a SonarQube scan.

### Acceptance Criteria

None specified.

### Discussion

None.

---

## Task — Original Text

### Description

See story.

### Discussion

None.

---

## Analysis

NTM had no `@ndwnu/eslint-config` — used a hand-rolled `eslint.config.js` with direct `angular-eslint` + `@typescript-eslint` imports, and a legacy `.eslintrc.json` was already staged as deleted.
No format migration needed — already flat config.
No `@angular/material` in deps, so the GRG lock file canary doesn't apply.
`typescript-eslint` meta-package was missing and needed explicitly (peer dep of `angular-eslint`).
`--legacy-peer-deps` required due to `@ndwnu/eslint-config` pinning `@angular-eslint@18` peer deps while NTM runs Angular 20.

---

## Implementation Plan

Follow GRG implementation — same files, same structure. See GRG story for key learnings.

---

## What was actually done (NTM implementation — 2026-03-11)

### Files changed
- `.eslintrc.json` — deleted (was the old legacy config, already staged)
- `eslint.config.js` — rewritten: global ignores first, beta.5 `.cjs` import path, sonar config imported, `prefer-on-push` turned off, `ntm` selector prefix
- `eslint.sonar.config.js` — new file, same sonar rules as GRG
- `package.json` — removed 8 explicit `@angular-eslint/*` + `@typescript-eslint/*` packages; added `@ndwnu/eslint-config: ^0.0.1-beta.5` and `typescript-eslint: ^8.26.0`
- `package-lock.json` — updated via `npm install --legacy-peer-deps`

### NTM-specific notes
- `eslint-plugin-prettier` and `eslint-plugin-storybook` remain in `package.json` — unused but out of scope for this PR
- `@ndwnu/eslint-config` peer dep conflict (`@angular-eslint@18` vs Angular 20) — resolved with `--legacy-peer-deps`; safe because NTM has no `@angular/material` dep that could go missing from lock file
