# feat(required-publications): #108265 ITS-duiding coverage per data type

**Story:** #108265 / **Task:** (none yet — story-only, task to be created)
**Branch:** `feat/108265/its-duiding-coverage-per-data-type`
**Date:** 2026-02-19

---

## Story — Original Text

### Description

Als **dashboardgebruiker**
wil ik de vastgelegde ITS-duiding kunnen raadplegen per gegevenstype,
zodat ik zie wat al afgedekt is en wat ontbreekt.

**Voor wie doen we dit**
- Voor dashboardgebruikers (bronhouders/wegbeheerders)

**Wat is wenselijk (functioneel)**
- Overzichten zijn herleidbaar naar concrete publicaties
- Alleen door Moderator vastgelegde duiding telt mee (geen aannames)
- Het dashboard kan per verordening het **totaal aantal wettelijke verplichtingen** bepalen
- Het dashboard kan per verplichting bepalen of deze is **afgedekt door één of meer publicaties**
- De bestaande dashboardstructuur (ITS/MMTIS / RTTI / SRTI / SSTP + voortgangsbalken) kan ongewijzigd blijven

### Acceptance Criteria

Het register kan per verordening bepalen:
- het totaal aantal wettelijke verplichtingen
- het aantal verplichtingen dat is **afgedekt** (ja/nee)

Een wettelijke verplichting geldt als **afgedekt** wanneer:
- minimaal één publicatie is gekoppeld aan het juiste gegevenstype
- de vastgelegde scope overeenkomt met de verplichting
- de koppeling met de publicatie is vastgelegd door een Moderator

Wettelijke verplichtingen zonder bijbehorende publicatie gelden als **niet afgedekt**.

De berekening van percentages sluit aan op de bestaande dashboardopzet en is volledig herleidbaar naar concrete publicaties.

### Discussion

None

---

## Task — Original Text

### Description

(Task not yet created — see story description above)

### Discussion

None

---

## Analysis

### What already exists

The "Overzicht verplichte publicaties" module already exists at:
- `ntm-frontend/src/app/modules/required-publications/`
- Routes: `/verplichte-publicaties` (overview) + `/verplichte-publicaties/:type` (detail)
- Currently uses the **deprecated** `/data-regulations` endpoint
- Current model: `IRequiredPublicationDataItem { id, dataItemCategory, hasPublications: boolean }`

### What the backend provides

**Old endpoint (deprecated)**: `GET /data-regulations` → `DataRegulationDto`
- Returns grouped obligations with simple `hasPublications: boolean` per data item
- Deprecated, moving to `/obligations`

**New endpoint**: `GET /obligations` → `ObligationDto[]`
- Richer model: includes `networkType`, `modality`, `obligationType`, `dataItem` (with description, source, `regulationType: ITS`)
- Does NOT include which publications cover an obligation
- The link exists the other way: `DataPublicationDto.obligationIds` points from publication → obligation

**The "ITS-duiding" context**: The story refers to ITS 2023/2661 (`regulationType: ITS`). This is a regulation type that exists in the new `/obligations` endpoint data.

### Key findings

1. **Migration needed**: Frontend must migrate from `/data-regulations` to `/obligations`
2. **New model structure**: `ObligationDto` is grouped differently — each obligation has a `dataItem` with its own `regulationType`
3. **Coverage ("afgedekt") logic**: The backend currently only has `hasPublications` on the old model. The new `/obligations` model does NOT include coverage status yet.
4. **Traceability gap**: To show WHICH publication covers an obligation, the backend would need to either:
   - Add `coveredBy: [{id, name}]` to `ObligationDto`, OR
   - Allow filtering publications by `obligationId`
   - This requires a separate BE story

### What this FE story can deliver

- Migrate from deprecated `/data-regulations` to `/obligations`
- Update the interface model to match `ObligationDto` structure
- Group obligations by `regulationType` (ITS, MULTIMODAL, REALTIME, etc.) for the dashboard cards
- Calculate coverage percentage based on `hasPublications` — but note: the new `/obligations` endpoint doesn't have this field yet. **This may require clarification with the backend team.**

### Open question requiring discussion

⚠️ **Backend clarification needed**: The new `/obligations` endpoint does not include a `hasPublications` or `covered` field. Either:
1. The backend needs to add coverage status to the obligations API (separate BE story needed)
2. Or the frontend needs to cross-reference with `/data-publications?obligationId=...` to calculate coverage

This should be discussed with the backend team / Ed Ooms before implementation begins.

---

## Implementation Plan

[To be filled in after open questions are resolved]
