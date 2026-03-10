# BER Bereikbaarheidskaart — Project Context

Machine-optimized. Claude-facing only.

**Frontend**: `accessibility-map-frontend/src/` (edit only here)
**Git**: all git commands from `accessibility-map-frontend/`
**Backends**: shared copies from GRG project (reference only, never edit)
**Design system**: `ndw-design/` (shared GRG design system, reference only)

**CRITICAL**: Project root is NOT a git repo. Git commands from root will fail.

---

## Language Rules

- Code & comments: English
- Commit messages: English (see `$CLAUDE_ROOT/global/git.md`)
- UI text: Dutch — hardcoded directly in templates
- **NO translation system** — no ngx-translate, no i18n files, no translation keys

```html
<!-- ✅ CORRECT for BER -->
<h1>Bereikbaarheidskaart</h1>
<!-- ❌ WRONG for BER -->
<h1>{{ 'MAP.TITLE' | translate }}</h1>
```

---

## Design System

Location: `/ndw-design/` — shared GRG design system
Rules: same as GRG — default to design system, never hardcode component model values.

---

## Backend API Mapping

Backend docs are 100% authoritative ground truth.
All 4 backends are shared copies from the GRG project.

| Feature | Backend doc |
|---------|------------|
| Traffic Signs (maps, CRUD, images, history) | `backend/traffic-sign-backend.md` |
| Organizations & Users & Road Authorities | `backend/traffic-sign-backend.md` |
| Findings / Issues | `backend/traffic-sign-backend.md` |
| Black Codes | `backend/traffic-sign-backend.md` |
| Info Messages | `backend/traffic-sign-backend.md` |
| Vehicle Restrictions / WKD (speeds, heights, loads, etc.) | `backend/traffic-sign-wkd-backend.md` |
| Environmental & Emission Zones | `backend/traffic-sign-area-backend.md` |
| Parking Bans | `backend/traffic-sign-area-backend.md` |
| Traffic Regulations | `backend/traffic-sign-area-backend.md` |
| Hazardous Substance Routes | `backend/traffic-sign-area-backend.md` |
| Areas, Counties, Towns | `backend/traffic-sign-area-backend.md` |
| User Feedback / Corrections | `backend/traffic-sign-feedback-backend.md` |

**Endpoint quick reference:**
- `/traffic-signs/**`, `/images/**`, `/organizations/**`, `/users/**`, `/findings/**`, `/black-codes/**`, `/info-messages/**`, `/road-authorities/**` → `traffic-sign-backend.md`
- `/speeds/**`, `/traffic-types/**`, `/height-restrictions/**`, `/length-restrictions/**`, `/load-restrictions/**`, `/axle-load-restrictions/**`, `/schoolzones/**`, `/road-narrowings/**`, `/driving-directions/**`, `/export/**` → `traffic-sign-wkd-backend.md`
- `/environmental-zones/**`, `/emission-zones/**`, `/parking-bans/**`, `/traffic-regulations/**`, `/routes/hazardous-substances/**`, `/areas/**`, `/counties/**` → `traffic-sign-area-backend.md`
- `/corrections/**` → `traffic-sign-feedback-backend.md`

---

## Backend Service Registry (for backend-update workflow)

| Backend | Repo path |
|---------|-----------|
| traffic-sign-backend | `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-backend/` |
| traffic-sign-wkd-backend | `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-wkd-backend/` |
| traffic-sign-area-backend | `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-area-backend/` |
| traffic-sign-feedback-backend | `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-feedback-backend/` |
