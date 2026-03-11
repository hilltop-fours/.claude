# [FE] BER — SonarQube ESLint rules

**Story:** #84569 / **Task:** #111452
**Branch:** `chore/84569/111452/sonarqube-eslint-rules`
**Date:** 2026-03-11

See story context and key learnings: `84569-111436-sonarqube-eslint-rules-grg.md` (GRG task — same story, fully documented)

---

## Analysis

BER uses flat config (`eslint.config.js`) — same starting point as GRG.
Check current `@ndwnu/eslint-config` version in `package.json`; upgrade to `^0.0.1-beta.5` if not already there.
VSCode `settings.json` fix needed at project root: `"./accessibility-map-frontend"` (see GRG learnings).

---

## Implementation Plan

Follow GRG implementation exactly — same files, same structure:

1. Add `{ ignores: ['node_modules', 'dist', '.angular', ...] }` as first block in `eslint.config.js`
2. Update base import to `require('@ndwnu/eslint-config/eslint.config.cjs')`
3. Create `eslint.sonar.config.js` — sonar rules extracted (copy from GRG, adjust selector prefix if BER differs)
4. Import and spread sonar config in `eslint.config.js`
5. Update `@ndwnu/eslint-config` to `^0.0.1-beta.5` in `package.json`
6. Run plain `npm install` (no `--legacy-peer-deps`) — restore lock from `origin/main` first if needed
7. Add `.vscode/settings.json` at project root with `eslint.workingDirectories` for `./accessibility-map-frontend`
8. Run `npx prettier eslint.config.js eslint.sonar.config.js --write` before committing

---

## What was actually done

[To be filled in after implementation]
