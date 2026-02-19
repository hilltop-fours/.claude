# fix(publications): #106009 #110091 fix data standard selection in English language

**Story:** #106009 / **Bug:** #110091
**Branch:** `fix/106009/110091/data-standard-selection-english-language`
**Date:** 2026-02-19

---

## Story — Original Text

### Description
See bug.

### Acceptance Criteria
None listed.

### Discussion
None

---

## Bug — Original Text

### Description
Wanneer er een publicatie wordt aangemaakt in het Engels, worden er bij het kiezen van een data-exchange method geen data-standaard opties weergegeven. Pas na een paar keer op en af klikken wordt het weergegeven. Dit gebeurt niet wanneer het register ingesteld is op "Nederlands".

(Translation: When a publication is created in English, no data-standard options are shown when selecting a data-exchange method. Only after clicking back and forth a few times does it appear. This does not happen when the register is set to "Dutch".)

### Discussion
None

---

## Analysis

### Root Cause

The bug is in `data-exchange-form.component.ts` — specifically in `#retrieveDataStandards()` at line 116–135.

The "Other" option label is built using `this.#translate.instant('STANDARDS.MOBILITY_DCAT_TYPES.OTHER')`.

`translate.instant()` is synchronous and reads the current translation at the moment it is called. The component is created in the **constructor** (`this.#retrieveDataStandards()` is called at line 63). If the language is English and the translation file hasn't finished loading yet at construction time, `instant()` returns the raw key string instead of the translated label.

Additionally, the `StandardsRepository.getAll()` call happens in the constructor too. The autosuggest component receives options and filters them based on the input value. The `ntmAutosuggest` directive likely filters options by matching input text against option labels. When the "Other" option label is the raw key (not translated yet), the autosuggest panel can't match it and may show "Geen resultaten gevonden".

The intermittent nature (works after clicking back and forth) is consistent with a timing issue: once the language file loads, subsequent opens of the panel work correctly.

### Other components with this issue

The same pattern exists in `publication-filter-data-standard.component.ts` — it uses `this.#translate.instant(...)` inside a subscribe callback too, but it re-calls `getFilterOptions()` on each open, which acts as a natural retry. This is why the filter panel (in the overview) may not exhibit the same bug as severely.

### Fix approach

Replace `this.#translate.instant(...)` with `this.#translate.stream(...)` and combine it with the standards observable so the "Other" label is reactive to language changes. When the language changes, the options need to be rebuilt. The cleanest fix is to subscribe to `onLangChange` or use `stream()` in combination with `combineLatest`.

**Specific fix:** In `#retrieveDataStandards()`, replace the `instant()` call with a reactive approach that combines the standards API result with the translate stream for the "Other" label, so options are rebuilt on language change.

---

## Implementation Plan

### Phase 1: Fix the reactive translation in data-exchange-form

In `data-exchange-form.component.ts`, update `#retrieveDataStandards()` to:
- Use `combineLatest` with `this.#translate.stream('STANDARDS.MOBILITY_DCAT_TYPES.OTHER')` so the options are rebuilt whenever the language changes
- This ensures the "Other" label is always correctly translated, even when the language file loads after component construction

This is a pure bug fix — no new components, no UI changes, no structural changes.
