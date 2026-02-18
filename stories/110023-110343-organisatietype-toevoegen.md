# feat(organizations): #110023 organisatietype toevoegen aan organisatiebeheerscherm

**Story:** #110023 / **Task:** #110343
**Branch:** `feature/110023/110343/organisatietype-toevoegen`
**Date:** 2026-02-18

---

## Story — Original Text

### Description

**Als** Moderator van NTM
**wil ik** kunnen zien of een organisatie een publieke, dan wel private organisatie is,
**zodat ik** gerichte analyses kan maken over het gebruik van het register

**Waarom doen we dit?**
Voor analyses, maar ook voor het vastleggen van use cases, is het handig om te weten wat voor soort organisaties aanwezig zijn in het register. Dit helpt om vraagstukken beter te beantwoorden.

**Wat is functioneel wenselijk?**
Aan elke organisatie binnen het dataregister wordt een veld toegevoegd wat duiding geeft over het type organisatie.
Het organisatietype is een voorgedefinieerde lijst:

- Publiek - Rijkswaterstaat
- Publiek - Provincie
- Publiek - Gemeente
- Publiek - Overig
- Privaat - Data-eigenaar
- Privaat - Serviceprovider
- Privaat - Overig

Er moet voor elke Organisatie één organisatietype geselecteerd worden.

### Acceptance Criteria

- De hoofdpublicist of de Moderator kan een Organisatietype toevoegen in het Organisatiebeheerscherm. (Aanpassen van rechten is niet nodig)
- Elke Organisatie heeft verplicht één Organisatietype, passend bij de registratie in het register.

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

**What this story builds:**
A single required dropdown field `organisatietype` added to every organization. The Moderator or hoofdpublicist can set it via the existing organization edit drawer. The type comes from a fixed list of 7 values.

**Backend status:** Not merged — mock all service responses on the frontend.

**How editing organizations works in NTM:**
The edit flow lives entirely inside `list-card-organization-info` component — it is NOT a separate edit page. It has its own `FormGroup`, an "Edit" button that opens an `<ntm-drawer>`, and calls `OrganizationRepository.update()` on submit. The `organization-details` page just renders this card as a child.

**Key files:**
- Model: `src/app/core/data-access/organizations/types/organization.interface.ts` — add `organisatietype` field here
- Form interface: `src/app/modules/account/types/account-update-form.interface.ts` — `IUserUpdateOrganizationForm` needs a new `organisatietype` FormControl
- Edit drawer: `src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts` + `.html` — this is where the FormControl is initialized and the dropdown is rendered
- Org repository: `src/app/core/data-access/organizations/organization.repository.ts` — mock `find()` and `list()` responses to include `organisatietype`

**Dropdown pattern to use:**
NTM has `ntm-single-select-dropdown` (`src/app/shared/components/single-select-dropdown/`) — takes `[options]` as `DropdownOption[]` (`{ label, value }`), works with `formControlName`. This is the right fit for a fixed enum list.

**Enum values (7 total, matching story description exactly):**
```
PUBLIEK_RIJKSWATERSTAAT
PUBLIEK_PROVINCIE
PUBLIEK_GEMEENTE
PUBLIEK_OVERIG
PRIVAAT_DATA_EIGENAAR
PRIVAAT_SERVICEPROVIDER
PRIVAAT_OVERIG
```

---

## Implementation Plan

### Phase 1: Enum + model + translations
- Create `src/app/core/data-access/organizations/types/organisation-type.enum.ts` with 7 values
- Add `organisatietype?: OrganisatietypeEnum` to `IOrganization` interface
- Add `organisatietype: FormControl<OrganisatietypeEnum | null>` to `IUserUpdateOrganizationForm`
- Add all 7 Dutch label translation keys to `nl.json` + `en.json`
- Result: types in place, no visible UI yet

### Phase 2: Mock service
- Patch `OrganizationRepository` mock so `find()` and `list()` responses include `organisatietype`
- Result: all subsequent phases have real-looking data to work with

### Phase 3: Dropdown in edit drawer
- Add `organisatietype` FormControl (required) to the form in `list-card-organization-info.component.ts`
- Build `organisatietypeOptions` array from enum values + translation labels
- Add `ntm-single-select-dropdown` to the drawer template in `list-card-organization-info.component.html`
- Patch value on `openDrawer()`, include in `submit()` payload
- Add `ntm-form-control-validation` for required error
- Result: dropdown visible and functional in the edit drawer

### Phase 4: Display
- Show the selected `organisatietype` label (read-only) on the organization info card when not in edit mode
- Result: type is visible on the organization details page
