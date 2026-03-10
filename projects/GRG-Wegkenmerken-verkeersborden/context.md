# GRG Wegkenmerken Verkeersborden — Project Context

Machine-optimized. Claude-facing only.

**Frontend**: `traffic-sign-frontend/src/` (edit only here)
**Git**: all git commands from `traffic-sign-frontend/`
**Backends**: see registry below (reference only, never edit)
**Design system**: `ndw-design/` (reference only, never edit)

**CRITICAL**: Project root is NOT a git repo. Git commands from root will fail.

---

## Language Rules

- Code & comments: English
- Commit messages: English (see `$CLAUDE_ROOT/global/git.md`)
- UI text: Dutch — hardcoded directly in templates
- **NO translation system** — no ngx-translate, no i18n files, no translation keys

```html
<!-- ✅ CORRECT for GRG -->
<h1>Verkeersborden</h1>
<!-- ❌ WRONG for GRG -->
<h1>{{ 'TRAFFIC_SIGNS.TITLE' | translate }}</h1>
```

---

## Design System

Location: `/ndw-design/` — import: `@shared/components/component-name`
Rules: same as NTM — default to design system, never hardcode component model values.

---

## Pattern Documentation

| Context | Read |
|---------|------|
| Styling / CSS classes (never Bootstrap) | `patterns/styling-guidelines.md` |
| `*.service.ts` files | `patterns/service-patterns.md` |
| `*.repository.ts` files | `patterns/repository-patterns.md` |
| Dev auth panel | `patterns/dev-auth-panel-instructions.md` |

---

## Backend API Mapping

Backend docs are 100% authoritative ground truth.

| Feature | Backend doc |
|---------|------------|
| Traffic Signs (CRUD, search, history, import, map, RVV codes) | `backend/traffic-sign-backend.md` |
| Mutation Proposals | `backend/traffic-sign-backend.md` |
| Findings / Inspection Results | `backend/traffic-sign-backend.md` |
| Organizations & Users & Road Authorities | `backend/traffic-sign-backend.md` |
| Images & Blobs | `backend/traffic-sign-backend.md` |
| Black Codes | `backend/traffic-sign-backend.md` |
| Connected Roads | `backend/traffic-sign-backend.md` |
| Opening Hours | `backend/traffic-sign-backend.md` |
| Info Messages | `backend/traffic-sign-backend.md` |
| Usage Statistics | `backend/traffic-sign-backend.md` |
| Current State / Static Road Data | `backend/traffic-sign-backend.md` |
| OGC Features | `backend/traffic-sign-backend.md` |
| Event Processors (Admin) | `backend/traffic-sign-backend.md` |
| GraphQL | `backend/traffic-sign-backend.md` |
| Environmental / Emission Zones | `backend/traffic-sign-area-backend.md` |
| Areas | `backend/traffic-sign-area-backend.md` |
| Parking Bans | `backend/traffic-sign-area-backend.md` |
| Traffic Regulations | `backend/traffic-sign-area-backend.md` |
| Hazardous Substance Routes | `backend/traffic-sign-area-backend.md` |
| Counties & Towns | `backend/traffic-sign-area-backend.md` |
| IBBM Emission Zones | `backend/traffic-sign-area-backend.md` |
| Coordinate Conversion | `backend/traffic-sign-area-backend.md` |
| WKD Restrictions (all types) | `backend/traffic-sign-wkd-backend.md` |
| WKD Joint Mutations | `backend/traffic-sign-wkd-backend.md` |
| WKD Export | `backend/traffic-sign-wkd-backend.md` |
| WKD File Uploads & Blobs | `backend/traffic-sign-wkd-backend.md` |
| WKD SFTP | `backend/traffic-sign-wkd-backend.md` |
| WKD NLS Proxies | `backend/traffic-sign-wkd-backend.md` |
| WKD Usage Statistics | `backend/traffic-sign-wkd-backend.md` |
| Speed Mutation Proposals (Derivation) | `backend/traffic-sign-wkd-derivation-backend.md` |
| Automated Inspections | `backend/traffic-sign-inspection-backend.md` |
| Inspection Feedback | `backend/traffic-sign-inspection-backend.md` |
| Feedback / Corrections | `backend/traffic-sign-feedback-backend.md` |
| HGV Charges (TSV Export) | `backend/traffic-sign-hgv-charge-backend.md` |
| Profile Backend | `backend/traffic-sign-profile-backend.md` |

**Ambiguous paths**: `/road-authorities/**` exists in traffic-sign-backend and traffic-sign-wkd-backend. `/speeds/**` exists in wkd-backend and wkd-derivation-backend (derivation uses `/speeds/road-section/`). `/usage-statistics` in both traffic-sign-backend and wkd-backend.

---

## Backend Service Registry (for backend-update workflow)

| Backend | Repo path |
|---------|-----------|
| traffic-sign-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-backend/` |
| traffic-sign-area-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-area-backend/` |
| traffic-sign-wkd-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-wkd-backend/` |
| traffic-sign-inspection-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-inspection-backend/` |
| traffic-sign-wkd-derivation-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-wkd-derivation-backend/` |
| traffic-sign-feedback-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-feedback-backend/` |
| traffic-sign-hgv-charge-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-hgv-charge-backend/` |
| traffic-sign-profile-backend | `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-profile-backend/` |
