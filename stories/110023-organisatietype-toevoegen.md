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

**Backend status:** Not implemented yet — mock all backend responses on the frontend side.

**What needs to happen on the frontend:**
- Add an `OrganizationType` enum with the 7 values
- Extend `IOrganization` interface with `organizationType`
- Add a required dropdown to the organization details page (where Moderator/hoofdpublicist can edit)
- Display the type in the organization info card
- Mock the field so development works without a real backend

**Key existing code to build on (NTM paths):**
- Organization model: `src/app/core/data-access/organizations/types/organization.interface.ts`
- Organization repository: `src/app/core/data-access/organizations/organization.repository.ts` — has `find()`, `list()`, `delete()` etc.
- Organization service: `src/app/core/data-access/organizations/organization.service.ts`
- Organization details page: `src/app/modules/organization/pages/organization-details/organization-details.component.ts` — loads org via `OrganizationRepository.find()`
- Organization info card: `src/app/shared/components/list-card/list-cards/list-card-organization-info/list-card-organization-info.component.ts` — displays org fields
- Organization overview: `src/app/modules/organization/pages/organization-overview/organization-overview.component.ts`
- Design system components: NTM uses its own design system (`@shared/components`), no `ndwInput`/`ndw-form-field` — check existing form patterns in publications or standards edit for the correct select/dropdown pattern
- No Zod schemas in NTM — plain TypeScript interfaces only

**Agreed:** Field is required. Existing orgs without a type will show an empty dropdown — user must pick before saving.

---

## Implementation Plan

### Phase 1: Model + enum
- Add `OrganizationTypeEnum` (7 values) to `src/app/core/data-access/organizations/types/`
- Extend `IOrganization` interface with `organizationType: OrganizationTypeEnum`
- Add translation keys for all 7 type labels (nl.json + en.json)

### Phase 2: Mock service
- Mock `OrganizationRepository` responses to include `organizationType` on `find()` and `list()`
- Enables all subsequent phases to be testable immediately

### Phase 3: Form UI
- Add required `organizationType` form control to the organization details page
- Add a dropdown using NTM design system select pattern (reference publications or standards edit form for correct component usage)

### Phase 4: Display
- Show the type label in `list-card-organization-info` component
