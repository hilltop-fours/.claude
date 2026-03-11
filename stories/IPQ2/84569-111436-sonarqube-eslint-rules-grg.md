# [FE] GRG — SonarQube ESLint rules

**Story:** #84569 / **Task:** #111436
**Branch:** `chore/84569/111436/sonarqube-eslint-rules`
**Date:** 2026-03-11

See story context: `84569-111426-sonarqube-eslint-rules.md` (NTM task — same story, same goal)

---

## Analysis

GRG already uses flat config (`eslint.config.js`) with `@ndwnu/eslint-config` as base.
No format migration needed — just add SonarQube rules on top of the existing config.
`@ndwnu/eslint-config` peer deps are pinned to `@angular-eslint@18` but GRG's installed node_modules still work (fragile — breaks on fresh install).
Do not run `npm install` during this task — it will break the existing setup.

---

## Implementation Plan

### Phase 1: Add SonarQube rules to eslint.config.js
Add rules to the existing `files: ['src/**/*.ts']` override block in GRG's `eslint.config.js`.
Same rules as NTM task — reference sonarqube-rules.md for the list.

---

## What was actually done (GRG implementation — 2026-03-11)

### Files changed
- `eslint.config.js` — added `node_modules` to ignores, imported `eslint.sonar.config.js`, updated base import to use `.cjs` path
- `eslint.sonar.config.js` — new file, sonar rules extracted into separate config
- `package.json` — upgraded `@ndwnu/eslint-config` to `^0.0.1-beta.5`, added/corrected `@angular-eslint/*` packages at `^21.3.0`, removed redundant `@eslint/js`
- `package-lock.json` — updated after package changes
- `.vscode/settings.json` — added `eslint.workingDirectories` to fix VSCode ESLint extension in multi-root workspace
- `eslint.ndwnu.local.cjs` — deleted (was a local-only workaround, not committed)

### Key learnings for NTM / BER

**`@ndwnu/eslint-config` beta.5 import path**
Use `require('@ndwnu/eslint-config/eslint.config.cjs')` — NOT `require('@ndwnu/eslint-config')`.
The package exports a `.cjs` file, not a default entry. Using the wrong path causes a silent failure.

**`@angular-eslint/*` packages must be explicit at correct version**
`angular-eslint` meta-package does NOT hoist `@angular-eslint/*` sub-packages to `node_modules/@angular-eslint/`.
`angular.json` uses `@angular-eslint/builder:lint` — if `@angular-eslint/builder` is not explicitly in `package.json`, `npm run lint` fails with:
`Could not find the '@angular-eslint/builder:lint' builder's node package.`
Fix: add all 4 explicitly at the same version as `angular-eslint`:
```
"@angular-eslint/builder": "^21.3.0",
"@angular-eslint/eslint-plugin": "^21.3.0",
"@angular-eslint/eslint-plugin-template": "^21.3.0",
"@angular-eslint/template-parser": "^21.3.0",
```
Do NOT add `@angular-eslint/schematics` — only needed for `ng add`, not linting.

**`@ndwnu/eslint-config` beta.5 declares `@angular-eslint@18` as its own dep**
This creates a version conflict. Resolve with `npm install --legacy-peer-deps`.
Always use `--legacy-peer-deps` for installs on these projects until ndwnu updates their config.

**`@eslint/js` is not needed explicitly**
ESLint v9 installs it as a transitive dep. Only add it explicitly if you `import js from '@eslint/js'` in your config directly.

**VSCode ESLint extension in multi-root workspace**
Without config, the extension resolves ESLint from the workspace root, not the frontend subfolder.
This causes `Could not find config file` errors for files in `node_modules/@ndwnu/eslint-config/`.
Fix: add `.vscode/settings.json` at the project root (NOT inside the frontend):
```json
{
  "eslint.workingDirectories": [
    { "directory": "./traffic-sign-frontend", "changeProcessCWD": true }
  ]
}
```
`changeProcessCWD: true` means the ESLint server process itself chdirs into the frontend folder, so all relative `require()` paths in `eslint.config.js` resolve correctly.
For NTM: `"./ntm-frontend"`. For BER: `"./accessibility-map-frontend"`.

**`node_modules` must be in ESLint ignores**
Flat config does NOT ignore `node_modules` by default when VSCode extension crawls files.
Always have `{ ignores: ['node_modules', 'dist', '.angular', ...] }` as the FIRST config object.

**`npm install` vs fresh install**
The old setup (before this task) only worked because packages happened to be installed from a previous `npm install`. A fresh `npm install` would have broken linting due to version conflicts. This task fixed that permanently.

**Sonar rules in a separate file**
Extracted sonar rules to `eslint.sonar.config.js` for clarity. Import it with `require('./eslint.sonar.config.js')` and spread into the config array. Keep project-specific overrides (selector prefixes, on-push detection) in `eslint.config.js`.

**`no-magic-numbers` removed**
Too noisy in Angular code (form validators, array indices, etc.). Not worth the signal-to-noise ratio.
