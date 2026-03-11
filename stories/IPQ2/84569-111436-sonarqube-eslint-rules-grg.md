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
