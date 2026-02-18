# feat(change-owner): #108756 #109821 change traffic sign ownership modal

**Story:** #108756 / **Task:** #109821
**Branch:** `feature/108756/109821/change-traffic-sign-ownership-modal`
**Date:** 2026-02-14

---

## Story — Original Text

### Description

FE/BE Stap 2; wisselen ownercode (dit wordt een bevinding)

ownercode zijn de de codes die we gebruiken voor wegbeheerders; GM0344, PFL, R , W123.

we kijken wat je wegbeheerdercode is van de ingelogde gebruiker. Die mag dan alle verkeersborden beheren van verkeersborden met dezelfde ownercode.

R mag alle borden van Rijk beheren.
GM0344 van alle gemeente Utrecht

eerste instantie invulling is op basis van plek, wegvak waaraan die gekoppeld is. Uitzondering zijn verkeersborden die Prive staan. die blijven leeg

Lege owner code mag door iedereen gewijzigd worden.

vervolgstory:
bevindingen weergeven en accorderen/weigeren

### Acceptance Criteria

- je mag een verkeersbord aanvragen van een andere wegbeheerder, dit wordt een bevinding (wijzigen eigenaar bord)
- weggeven geeft modal met daarin dropdown met wegbeheerders, akkoord is invullen van nieuwe ownercode obv wegbeheerdercode
- modal verkeersbord is via bitterballen menu, met uitleg en akkoord.
- lege ownercode mag door iedereen gewijzigd worden.
- als je admin bent of landelijke beheerder, mag je vrij invullen wie de ownercode is.

- modal: geeft twee opties: verkeersbord is van [[naam wegbeheerder]] of veld met dropdown waar je code kan opzoeken

### Discussion

- Daniel Wildschut (Tuesday): /traffic-signs/id/owner nieuwe PUT endpoint
- Daniel Wildschut (Tuesday): als iemand een wijziging wou doen dat een bevinding heeft gemaakt, en vervolgens iemand langs komt die dat wel mag wijzigen, dan wanneer dat aangepast wordt wordt die bevinding ook automatisch op opgelost gezet.
- Daniel Wildschut (Tuesday): als je geen rechten hebt dan zie je in het modal de beheerders die enkel onder jouzelf vallen, en als je wel rechten hebt dan zie je alle wegbeheerders. uitzondering een bord zonder ownercode, dan zie je enkel de wegbeheerders die onder jou vallen.
- Mehmet Yenel (Jan 26): Copied with all links from 108600 GRG BE/FE Ownercode en operator code opvoeren voor verkeersborden stap 1 - Committed

---

## Task — Original Text

### Description

See story

### Discussion

None

---

## Analysis

Add a "Wijzig eigenaar" (change owner) option to the three-dot menu on the traffic sign detail panel. This opens a modal where the user can reassign ownership of a traffic sign to a different road authority.

The modal presents two radio options:
1. Keep current owner — "Verkeersbord is van [naam wegbeheerder]"
2. Search for a different road authority via autosuggest dropdown

Permission rules determine which road authorities appear in the dropdown:
- Regular user: only road authorities within their own organization
- Admin / landelijke beheerder: all road authorities
- Exception: signs with empty ownercode — only road authorities under the user's scope

Submitting calls `PUT /traffic-signs/{id}/owner` which creates a bevinding (finding), not an instant change. The backend is not merged yet, so we mock the endpoint.

**Existing code to reuse:**
- `RoadAuthorityService` (`shared/services/road-authority.service.ts`) — fetches all road authorities
- `RoadAuthorityAutocompleteComponent` (`shared/components/road-authority-autocomplete/`) — autosuggest for road authorities
- `ModalService` — for opening/closing modals
- `AuthService` — `isAdmin` signal for permission checks
- `UserRepository` — `organization()?.roadAuthorities` for user's own road authorities
- Bitterballen menu at `traffic-sign-side-panel-context-menu` component

**Needs to be built:**
- Owner fields on TrafficSign model (backend will add, we mock)
- Change owner modal component with radio buttons
- Menu item in bitterballen menu
- Mock service for `PUT /traffic-signs/{id}/owner`
- Permission-based filtering of road authorities

---

## Implementation Plan

### Phase 1: Models & Menu Item
- Add owner fields to TrafficSign interface (mocked for now)
- Add "Wijzig eigenaar" menu item to the bitterballen menu
- Create a basic shell modal that opens when the menu item is clicked
- **Testable:** Click the menu item, see an empty modal open and close

### Phase 2: Dev Tools & Mock Data
- Mock owner data on traffic signs so the modal has something to display
- Mock service for `PUT /traffic-signs/{id}/owner` endpoint
- Small dev tools component to toggle scenarios (has owner, empty owner, different roles)
- **Testable:** Use dev tools to switch between scenarios, verify mock data flows through

### Phase 3: Modal Content
- Add radio buttons (keep current owner vs. search new)
- Show current owner name in first radio option (using mock data from Phase 2)
- Add road authority autosuggest in second radio option (reuse existing `RoadAuthorityAutocompleteComponent`)
- Add confirm/cancel buttons in modal footer
- **Testable:** Open modal, see radio buttons with real-looking data, search for road authorities

### Phase 4: Submit Logic
- Wire up the confirm button to submit the selected road authority via mock service
- Show success/error toast after submission
- **Testable:** Select a new owner, click confirm, see success toast

### Phase 5: Permission Logic
- Filter road authorities based on user role (admin sees all, regular user sees own)
- Handle empty ownercode case (everyone can edit, but dropdown scoped to own)
- Show/hide the menu item based on whether user is allowed to change owner
- **Testable:** Use dev tools to switch roles, verify correct road authorities appear
