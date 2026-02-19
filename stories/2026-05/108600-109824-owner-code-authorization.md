# feat(authorization): #108600 #109824 add owner-based authorization for traffic sign editing

**Story:** #108600 / **Task:** #109824
**Branch:** `feature/108600/109824/owner-code-authorization-setup`
**Date:** 2026-02-16

---

## Story — Original Text

### Description

BE/FE Stap 1: autorisatie wijziging van wegvak naar ownercode

ownercode zijn de de codes die we gebruiken voor wegbeheerders; GM0344, PFL, R , W123.

we kijken wat je wegbeheerdercode is van de ingelogde gebruiker. Die mag dan alle verkeersborden beheren van verkeersborden met dezelfde ownercode.

R mag alle borden van Rijk beheren.
GM0344 van alle gemeente Utrecht

eerste instantie invulling is op basis van plek, wegvak waaraan die gekoppeld is. Uitzondering zijn verkeersborden die Prive staan. die blijven leeg

De inhoud van een bord zonder owner code mag door iedereen gewijzigd worden. (niet de owner code zelf, dat kan later in stap 2)

### Acceptance Criteria

initiele vulling leeg (als owner code leeg is, wegbeheerdercode mee sturen)
formulier voor verkeersbord mag alleen door de wegbeheerder die matched met ownercode gewijzigd worden
prive en lege wegvak ID mag door iedereen
autorisatie van bord op is op basis van wegbeheerdercode tenzij ownercode ingevuld is

### Discussion

None visible in screenshots

---

## Task — Original Text

### Description

[FE] Ownercode en operator code opvoeren voor verkeersborden

### Discussion

None

---

## Analysis

This task is about changing the authorization model for traffic sign editing. Previously authorization was based on the road section (wegvak) the sign is on. Now it switches to owner-based authorization using an `ownercode` on the traffic sign itself.

**What's already implemented on the branch (5 WIP commits + 1 feature commit):**

1. **Data model**: `owner?: RoadAuthority` (with `type` and `code`) added to `TrafficSign` and `TrafficSignRequest` interfaces
2. **Authorization service**: `RoadSectionAuthService.canEditTrafficSignSignal()` — signal-based method that checks:
   - No owner code → anyone can edit
   - User is admin → can edit all
   - User's org has matching road authority (same type + code) → can edit
   - Otherwise → cannot edit
3. **UI integration**: Edit side panel passes `formDisabled` signal to general form and location form components, which disable all inputs and show an info alert ("U heeft geen bevoegdheid om dit verkeersbord te wijzigen.")
4. **Action buttons** (Next, Save) are disabled when unauthorized

**Current state**: The feature appears to be functionally complete. The branch has gone through several WIP refactors (removing Observable-based approach, switching to signals, cleaning up unused methods, adding comments).

**PR #117208** is already open and active, targeting main.

---

## Implementation Plan

Implementation is already done. The branch contains the complete feature:

### Completed
- Owner field on TrafficSign model
- Signal-based authorization check in RoadSectionAuthService
- Form disabling when unauthorized (both general and location forms)
- Info alert when user lacks permissions
- Action button disabling
- Cleanup of old Observable-based method
