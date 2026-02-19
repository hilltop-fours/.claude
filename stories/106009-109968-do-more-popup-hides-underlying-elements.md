# fix(do-more-banner): #106009 #109968 do more popup hides underlying elements

**Story:** #106009 / **Task:** #109968
**Branch:** `fix/106009/109968/do-more-popup-hides-underlying-elements`
**Date:** 2026-02-19

---

## Story — Original Text

### Description
None (parent story: NTM - Beheer 2026-06)

### Acceptance Criteria
None provided

### Discussion
None

---

## Task — Original Text

### Description
"Doe meer met NTM" popup kan onderliggende element hiden

### Discussion
None

---

## Analysis

The "Doe meer met NTM" banner (`ntm-do-more-banner`) slides in from the top of the page using `position: absolute` with `z-index: 10` in `banner.component.scss`. When visible (`is-visible` class applied), it renders at `top: 9rem, right: 0` with `max-width: 25rem`. Since it uses `position: absolute` without a scoped containing block that clips it, the banner overlaps and hides the content directly beneath it — users cannot interact with those elements while the banner is open.

**Root cause:** `.ntm-banner` is `position: absolute` with no `overflow: hidden` on the parent or `pointer-events: none` when hidden. When hidden (slid above view via `translateY(-110%) translateY(-9rem)`), the element is still in the DOM and technically positioned; when visible, it covers the underlying page content.

**Fix:** Add `pointer-events: none` to `.ntm-banner` by default, and `pointer-events: auto` only on `.is-visible`. This ensures the banner can only receive interactions when it is actually visible and covering the content intentionally.

**Files involved:**
- `ntm-frontend/src/app/shared/components/banner/banner.component.scss`

---

## Implementation Plan

### Phase 1: Fix pointer-events on banner
Add `pointer-events: none` to `.ntm-banner` base styles and `pointer-events: auto` in `.is-visible` modifier. This is a pure CSS fix — one file, no logic changes needed.
