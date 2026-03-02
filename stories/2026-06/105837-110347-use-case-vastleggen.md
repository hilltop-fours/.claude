# feat(use-cases): #105837 use-case met databehoefte vastleggen

**Story:** #105837 / **Task:** #110347
**Branch:** `feature/105837/110347/use-case-vastleggen`
**Date:** 2026-02-18

---

## Story — Original Text

### Description

Als geregistreerde gebruiker binnen het NTM-netwerk
wil ik een use-case met bijbehorende databehoefte gestructureerd kunnen vastleggen
zodat zichtbaar wordt welke informatie in het ecosysteem nodig is en waar vraagpatronen ontstaan.

**Waarom doen we dit**
Datavragen worden nu niet centraal vastgelegd. Ze blijven hangen in gesprekken, mails of losse documenten. Daardoor:
- is niet zichtbaar waar meerdere partijen dezelfde behoefte hebben;
- is niet duidelijk of bestaande datasets aansluiten;
- ontbreekt onderbouwde input voor prioritering;
- blijft kennis persoonsafhankelijk.

Door use-cases publiek en gestructureerd vast te leggen ontstaat:
- inzicht in actuele informatiebehoefte;
- clustering van vergelijkbare vragen;
- input voor beleidskeuzes en doorontwikkeling van het register.

Dit is nadrukkelijk geen ideeënbox, maar een instrument voor datavraaginventarisatie binnen een netwerk van bekende partijen.

**Organisatiecontext**
De bestaande accountregistratie blijft laagdrempelig en generiek.
Organisatiegegevens worden niet verplicht bij registratie.
Organisatiecontext wordt verplicht zodra een gebruiker een use-case wil indienen.
Hiermee wordt:
- de instapdrempel voor registratie laag gehouden;
- datakwaliteit voor use-cases geborgd;
- dubbele opslag per use-case voorkomen;
- latere analyse per organisatietype mogelijk gemaakt.

Organisatiegegevens worden opgeslagen in het gebruikersprofiel en niet per use-case.

**Voor wie doen we dit**
Primair:
- Geregistreerde gebruikers (zonder vastgelegde organisatie en organisatietype)
- Publicisten (met vastgelegde organisatie) binnen NTM

Secundair:
- Communitymanagers en Moderators (zicht op vraagpatronen)

Indirect:
- Data-eigenaren (inzicht in waar behoefte ligt)

**Wat is functioneel wenselijk**
- Voor de invoer wordt gebruik gemaakt van dezelfde opzet die ook gebruikt wordt bij het invoeren van datapublicaties.
- Alleen ingelogde geregistreerde gebruikers kunnen een use-case aanmaken.
- Publieke bezoekers kunnen use-cases bekijken, zoeken en filteren.
- Bij het starten van "Nieuwe use-case" controleert het systeem of het profiel compleet is.
- Indien niet compleet moet de gebruiker eerst vastleggen:
  - Organisatietype (verplicht, keuzelijst) — opslaan bij de use-case
  - Organisatienaam (verplicht, intern) — opslaan bij de use-case
  - Organisatienaam is standaard niet publiek zichtbaar
  - Er is een checkbox om aan te geven of de Organisatienaam publiek zichtbaar mag zijn
  - Organisatietype is publiek zichtbaar

Volledige C(RUD) — RUD alleen BE. UD voor Moderator en vastlegger van de Use Case.

**Invoer use-case (minimaal)**

Verplicht:
1. Achteraan de flow, na databehoefte:
   - Organisatienaam
   - Organisatietype
   - Checkbox Organisatienaam Publiek zichtbaar
2. Titel
3. Beschrijving (wat wil je bereiken met de use case?)
4. Doelgroep (vrij tekstveld — mogelijk later normaliseren)
5. Thema/Community (overeenkomend met thema's in het NTM-register, meerkeuze, zonder uitsplitsing naar categorieën)

**Invoer databehoefte (minimaal 1, meerdere keren per use-case mogelijk)**

Per databehoefte:
- Welke informatie is nodig? (vrij tekstveld)
- Moet de data realtime zijn of historisch? (multiselect: Real time data / Historische data)
- "+ Databehoefte" knop om extra toe te voegen
- "— Verwijder" knop om een databehoefte te verwijderen

**Na opslaan zichtbaar:**
- Titel
- Beschrijving
- Doelgroep
- Organisatietype
- Organisatienaam (afhankelijk van checkbox-keuze)
- Overzicht van databehoeften
- Persoonsgegevens zijn NIET zichtbaar

**Resultaat**
Er ontstaat een publiek overzicht van:
- welke problemen worden benoemd;
- welke informatie nodig is;
- hoe kritisch die informatie is;
- bij welk type organisatie deze vraag leeft.

Dit vormt een analysebasis voor prioritering binnen NTM.

**Doorkijk naar fase 2**
In een volgende fase wordt het mogelijk om:
- datasets in het register te koppelen aan specifieke databehoeften;
- zichtbaar te maken of een databehoefte al wordt ingevuld;
- een status per use-case te tonen (bijv. Nieuw / Gekoppeld / Afgesloten).

Deze fase richt zich uitsluitend op het zichtbaar maken van vraag.

### Acceptance Criteria

- We doen het met een stepper

**Toegang en autorisatie**
- Alleen ingelogde geregistreerde gebruikers kunnen een use-case aanmaken.

**Profielverrijking (organisatiecontext)**
- Bij het starten van "Nieuwe use-case" controleert het systeem of organisatietype en organisatienaam aanwezig zijn in het profiel.
- Indien deze ontbreken, wordt de gebruiker verplicht dit aan te vullen.
- Organisatietype is een verplichte keuzelijst.
- Organisatienaam is verplicht en wordt intern opgeslagen.
- Organisatienaam is niet standaard publiek zichtbaar.
- Organisatietype is publiek zichtbaar bij de use-case.
- Organisatiegegevens worden opgeslagen per use-case gedupliceerd.

**Invoer use-case**
- Het systeem verhindert opslaan indien één van de volgende verplichte velden ontbreekt.
- Het systeem verhindert opslaan indien geen databehoefte is toegevoegd.
- Foutmeldingen worden direct bij het betreffende veld getoond in begrijpelijke taal.

### Discussion

Story 1: elke organisatie moet een organisatietype hebben.
→ 110023 UCS - [BE/FE] Als Moderator van NTM wil ik kunnen zien of een organisatie een publieke, dan wel private organisatie is — Committed

Story 2: invoerformulier voor ingelogde gebruikers (deze story)

Story points: BE: 2,5 / FE: 2,5

---

## UX Reference

**Step 1 (scherm 1):** Stepper met 3 stappen
- Naam van de use case (verplicht tekstveld)
- Omschrijving (rich text editor: B/I/U, lijsten)
- Doelgroep (rich text editor: B/I/U, lijsten)
- Op welk thema heeft de use case betrekking? (checkboxes, 9 thema's in 3 kolommen)
- Knop "Volgende"

**Step 2 (scherm 2):** Databehoefte invullen
- Omschrijving Databehoefte (rich text editor)
- Aan welke soort data is er behoefte? (multiselect: Real time data / Historische data)
- "+ Databehoefte" knop (voegt nieuw blok toe)
- "— Verwijder" knop per blok
- Stepper toont: stap 1 voltooid (✓), stap 2 actief, stap 3 nog te doen

**Step 3 (scherm 3):** Organisatiegegevens
- Organisatienaam (verplicht)
- Organisatietype (verplicht, keuzelijst)
- Checkbox: Organisatienaam publiek zichtbaar
- Finale opslaan actie

*Note: rough mockups only — exact visual details to be confirmed during implementation*

---

## Analysis

**What this story builds:**
A 3-step stepper form for creating a use-case, following the same pattern as publications edit.

**Step breakdown:**
- Step 1: Naam (text), Omschrijving (rich text), Doelgroep (rich text), Thema's (9 checkboxes, top-level only)
- Step 2: Databehoefte — one or more blocks, each with rich text description + multiselect (Real time / Historisch). Blocks can be added/removed dynamically.
- Step 3: Organisatienaam (text, required), Organisatietype (select, required), Checkbox: Organisatienaam publiek zichtbaar. Pre-filled from user profile if available.

**Agreed decisions:**
- Themes: build a simple custom checkbox list (9 ThemeTypeEnum values) — no categories/subcategories
- Step 3 organisation fields: always shown, pre-filled from user profile if data available
- Backend: NOT merged — mock all service responses for now
- OrganisatieType enum: define a temporary placeholder enum (e.g. Publiek / Privaat) — streamline with 110023 later

**Reused from existing code:**
- `StepperComponent`, `StepHeaderComponent`, `StepPanelComponent` — identical stepper pattern
- `ntm-text-editor` (ngx-quill) — for Omschrijving, Doelgroep, and each Databehoefte description
- Publications edit form pattern — FormGroup per step, `FormUtils.triggerValidation()`, `[finished]="stepFormGroup.valid"`
- Routing + lazy-loaded module pattern from existing modules

**New things to build:**
- `use-cases` module with routing, overview page, new/create page
- `use-case-new` stepper form (3 steps, following publications-edit pattern)
- `use-case-edit-form-general` component (Step 1)
- `use-case-edit-form-data-needs` component (Step 2, dynamic FormArray)
- `use-case-edit-form-organisation` component (Step 3)
- Simple theme checkbox component (just ThemeTypeEnum checkboxes)
- `IUseCase` model interface
- `OrganisationTypeEnum` placeholder
- `UseCaseService` + `UseCaseRepository` (mocked)
- Dev tools mock returning fake use-case data

---

## Implementation Plan

### Phase 1: Module scaffold + models + routing
- Create `use-cases` module folder structure
- Define `IUseCase` interface, `OrganisationTypeEnum`, `IDataNeed` interface
- Set up lazy-loaded route (overview page shell + new page shell)
- Add route to `app.routes.ts` and navigation if applicable
- Add translation keys (nl.json + en.json)
- Result: `/use-cases` route loads, empty page renders

### Phase 2: Dev tools + mock service
- Create `UseCaseRepository` + `UseCaseService` with stubbed methods (create, getAll, getById)
- Add dev tools mock that returns hardcoded use-case list and create success response
- Result: service layer in place, mockable from day one, all subsequent phases testable

### Phase 3: Stepper shell + Step 1 (General info)
- Build `use-case-new` page component with 3-step stepper
- Build `use-case-edit-form-general` (Step 1): Naam, Omschrijving, Doelgroep, Thema's
- Build simple theme checkbox list component (9 ThemeTypeEnum values, no categories)
- Step 1 validation + "Volgende" button working
- Result: Step 1 fully functional and navigates to Step 2

### Phase 4: Step 2 (Databehoefte)
- Build `use-case-edit-form-data-needs` with dynamic FormArray
- Each block: rich text description + two checkboxes (Real time / Historisch)
- "+ Databehoefte" adds a new block; "— Verwijder" removes it (min 1 required)
- Validation: at least 1 databehoefte must be present and have content
- Result: Step 2 fully functional and navigates to Step 3

### Phase 5: Step 3 (Organisation) + submit
- Build `use-case-edit-form-organisation` (Step 3): Organisatienaam, Organisatietype select, checkbox publiek zichtbaar
- Pre-fill from current user's profile if org data available
- Submit calls mock UseCaseService.create(), navigates to overview on success
- Result: full 3-step flow submittable end-to-end
