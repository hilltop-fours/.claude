# feat(organizations): #110023 organisatietype toevoegen aan organisatiebeheerscherm

**Story:** #110023 / **Task:** #[task-id TBD]
**Branch:** `feat/110023/[task-id]/organisatietype-toevoegen`
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

This story adds a required `organisatietype` field to every organization. The type is chosen from a fixed list of 7 values (4 public, 3 private) and exactly one must be selected per organization.

**Backend status:** Not implemented yet. Standard assumption for BE/FE combined stories — always mock the backend on the frontend side unless explicitly told the backend is merged.

**What needs to happen on the frontend:**
- Add an `OrganizationType` enum with the 7 values
- Extend the `Organization` model with `organizationType`
- Add a required dropdown to the organization edit form
- Display the type on the organization card in the overview
- Mock the field so development works without a real backend

**Key existing code to build on:**
- Organization model: `src/app/modules/user/models/organization.interface.ts` (Zod schema)
- Organization form: `src/app/modules/user/components/organization-form/organization-form.component` — has a "Organisatiedetails" card, dropdown goes here
- Edit page: `src/app/modules/user/pages/organization-edit/organization-edit.component` — owns the FormGroup
- Card: `src/app/modules/user/components/organization-card/organization-card.component` — shows org in overview list
- Existing enum+dropdown pattern: `<select ndwInput>` inside `<ndw-form-field>`, with a `BasePipeTransform` pipe for Dutch labels (same pattern as e.g. `EnvironmentalZoneType`)
- Organization service: already has `find()`, `create()`, `update()` — mock responses need to include `organizationType`

**Agreed:** Field is required. Existing orgs without a type will show an empty dropdown — user must pick before saving.

---

## Implementation Plan

### Phase 1: Model + enum
- Add `OrganizationType` enum (7 values) to the organization model
- Extend `Organization` Zod schema with `organizationType` (optional for now, required once backend is live)
- Add a `BasePipeTransform` pipe for Dutch labels

### Phase 2: Mock service
- Mock `organization.service` responses to include `organizationType` on `find()` and `getAll()`
- Enables all subsequent phases to be testable immediately

### Phase 3: Form UI
- Add required `organizationType` form control to the edit page
- Add `<select ndwInput>` dropdown to the organization form

### Phase 4: Display
- Show the type label on the organization card in the overview
