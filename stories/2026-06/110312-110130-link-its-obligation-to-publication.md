# feat(use-cases): #110312 #110130 link ITS obligation to publication

**Story:** #110312 / **Task:** #110130
**Branch:** `feat/110312/110130/link-its-obligation-to-publication`
**Date:** 2026-02-23

---

## Story — Original Text

### Description

Als **Moderator**
wil ik bij een publicatie de ITS-duiding kunnen **toevoegen, aanpassen, verwijderen en inzien** (gegevenstype + scope),
zodat de registratie klopt en actueel blijft.

**Voor wie doen we dit**
- Voor Moderators (werkbaar proces)
- Voor dashboards (betrouwbare bron)
- Indirect voor publicisten (actueel inzicht)

**Wat is wenselijk (functioneel)**
- De Moderator kan ITS-duiding vastleggen op publicatieniveau
- De invoer is gestuurd via referenties (gegevenstype en scope)
- De Moderator kan fouten corrigeren (wijzigen/verwijderen)
- Alleen Moderator ziet en kan wijzigen
- Keuzes zijn gestuurd (dropdowns, geen vrije tekst)
- Meerdere verplichtingen per publicatie toegestaan
- Geen verplicht veld (publicatie zonder duiding mag bestaan)
- Opslaan = direct meetellen voor dashboard

### Acceptance Criteria

Een Moderator kan bij een bestaande publicatie:
- één of meerdere ITS-gegevenstypen selecteren
- per gegevenstype een scope vastleggen
- Of dit gecombineerd doen

De Moderator kan een eerder vastgelegde ITS-duiding:
- inzien
- wijzigen
- verwijderen

De invoer voor gegevenstype en scope is:
- volledig gestuurd via referentielijsten
- niet mogelijk via vrije tekst

Per vastgelegde ITS-duiding wordt opgeslagen:
- welke publicatie het betreft

Publicaties zonder ITS-duiding blijven bestaan en zijn geldig,
maar **tellen niet mee** voor wettelijke compliance.

### Discussion

None

---

## Task — Original Text

### Description

See story

### Discussion

None

---

## Analysis

Taking over from a previous developer. The skeleton of the obligations feature is already built:
- 3 cascading dropdowns: Regulation Type → Data Network → Obligation (autosuggest)
- ObligationRepository loads all obligations from API, computes unique regulations/networkTypes
- Add/remove multiple obligations per publication works
- Parent component (publication-edit-form-obligation) manages the FormArray

### Issues to fix

1. **2nd dropdown bug**: After selecting regulation, then selecting network type, going back breaks the options. Root cause: `ngOnInit` resets `selectedNetwork` signal to `undefined` when regulation changes, but the form control value is not cleared — causes mismatch between signal and form state.

2. **Cascading disable**: First 2 dropdowns are filter fields for the 3rd (the actual obligation). Should cascade: field 1 enabled → field 2 disabled → field 3 disabled. Unlock sequentially as values are selected. The `SingleSelectDropdown` already has a `disabled` input.

3. **Submit payload broken**: `#mapObligationFormGroup` is stubbed (returns `''`), mapping line is commented out. API expects `obligationIds: string[]` but raw FormGroup objects are sent.

4. **"Hello World" TODO**: When loading existing publications, obligation description is hardcoded. Should look up real description from ObligationRepository data.

### Decisions made
- Changing regulation type clears both network type and autosuggest
- Fix the Hello World placeholder with real obligation descriptions

---

## Implementation Plan

### Phase 1: Fix cascading disable + 2nd dropdown bug
- Add `disabled` binding to 2nd and 3rd fields based on selected values
- Fix the reset logic: when regulation changes, clear network type form control + autosuggest
- When network type changes, clear autosuggest
- Ensure signals and form controls stay in sync

### Phase 2: Fix submit payload + existing data loading
- Uncomment and fix `#mapObligationFormGroup` to extract `id` from each FormGroup
- Fix the submit mapping to send `obligationIds: string[]`
- Fix `#fillObligationsArray` to look up real description from ObligationRepository
