# chore(bootstrap-removal): #106189 #110757 bootstrap last small things

**Story:** #106189 / **Task:** #110757
**Branch:** `feature/106189/110757/bootstrap-last-small-things`
**Date:** 2026-02-26

---

## Story — Original Text

### Description
See parent story B&O George 2026-06

### Acceptance Criteria
See parent story

### Discussion
None

---

## Task — Original Text

### Description
GRG [FE] Bootstrap laatste kleine dingen

### Discussion
None

---

## Analysis

Task covers the remaining bootstrap-removal work that was not included in the previously merged PRs (PR 116425, PR 115671, etc.). Three areas identified via stash deep-dive:

1. **bulk-upload-file** — Remove unused `NgbCollapseModule` import + unused `::ng-deep .ag-root-wrapper` scss rule
2. **road-section-information** — Replace old bootstrap HTML (`mb-1`, `text-muted`) with Angular `@if` blocks + design system classes. Add missing SCSS file (accordion overrides), `styleUrl`, and `index.ts` barrel file
3. **selection-list** — Full restructure from `<section>/<ul class="list-item">` to `<header>/<content>` + `ndwButton tertiary` + `<hr ndwDivider noMargin />` pattern (already established in `multi-select-list` and `multi-speed-limit-list`)

Build passes. Changes are staged and ready to commit.

---

## Implementation Plan

### Phase 1: Apply stash changes (DONE)
- All 9 files applied from recovered stash
- One conflict resolved in `bulk-upload-file.component.scss` (kept `::ng-deep ndw-collapsible` rule, removed `::ng-deep .ag-root-wrapper`)
- Build verified passing

### Phase 2: Commit & PR
- Create branch `feature/106189/110757/bootstrap-last-small-things`
- WIP commit
- Open PR
