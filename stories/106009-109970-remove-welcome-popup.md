# chore(welcome-popup): #106009 #109970 remove welcome popup

**Story:** #106009 / **Task:** #109970
**Branch:** `feature/106009/109970/remove-welcome-popup`
**Date:** 2026-02-19

---

## Story — Original Text

### Description
None listed.

### Acceptance Criteria
None listed.

### Discussion
None

---

## Task — Original Text

### Description
"Register is vernieuwd" popup weghalen

### Discussion
None

---

## Analysis

Straightforward removal task. The welcome popup ("Het register is vernieuwd!") was a one-time notification shown to users on first visit, stored in localStorage. The PO confirmed it can be fully removed as the feature may return later in a different form.

### What was removed

- `WelcomePopupComponent` — deleted entire component folder (`welcome-popup/`)
- `app.component.html` — removed `<ntm-welcome-popup>` tag
- `app.component.ts` — removed import, from `imports[]`, `showWelcomePopup` property, and `closeWelcomePopup()` method
- `visit.service.ts` — removed `#WELCOME_MESSAGE_KEY`, `showWelcomeMessage()`, and `markWelcomeMessageRead()`

Translation keys in `nl.json` and `en.json` were intentionally kept for future reference.

---

## Implementation Plan

Single phase — removal only, no new functionality.

### Phase 1: Remove welcome popup
Remove all traces of the welcome popup from the app: component files, template usage, component class wiring, and service logic.
