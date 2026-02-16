# BER BEREIKBAARHEIDSKAART - PROJECT INSTRUCTIONS

## PROJECT IDENTIFICATION

Working directory path contains: `/BER-Bereikbaarheidskaart`

## REPOSITORY LOCATIONS

### Frontend
- **Path**: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/accessibility-map-frontend/`
- **Git operations**: ALL git commands (checkout, add, commit, push, status, branch, etc.) MUST execute from this directory
- **Editable**: YES - Only edit files in `/accessibility-map-frontend/src/**`

### Backend Services (Reference Only - Never Edit)
All 4 backends are shared copies from the GRG project, used here for accessibility mapping.

- **traffic-sign-backend**: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-backend/`
- **traffic-sign-wkd-backend**: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-wkd-backend/`
- **traffic-sign-area-backend**: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-area-backend/`
- **traffic-sign-feedback-backend**: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/traffic-sign-feedback-backend/`

### Design System (Reference Only - Never Edit)
- **Path**: `/Users/daniel/Developer/BER-Bereikbaarheidskaart/ndw-design/`
- Shared GRG design system

**CRITICAL**: Project root `/Users/daniel/Developer/BER-Bereikbaarheidskaart` is NOT a git repository. Git commands will fail if executed there.

---

## FRONTEND CODING RULES

### File Type Restrictions

This project uses ONLY:
- TypeScript: `.ts` files
- HTML templates: `.html` files
- SCSS styles: `.scss` files

When using Glob tool, use pattern: `**/*.{ts,html,scss}`

NEVER search for or work with: `.js`, `.jsx`, `.tsx`, `.css`, `.less`, `.vue` files

### Design System

**Location**: `/ndw-design/` (reference only, never edit — shared GRG design system)

**Usage Rules**:
- Most common components available: cards, tabs, buttons, forms, modals, drawers, inputs, selects, etc.
- Design system components have associated models/interfaces
- NEVER hardcode strings/values that exist in component models
- Default to design system components when creating UI elements
- Assume components exist unless explicitly told otherwise
- If unsure about a component, search design system first before creating custom components

### Language Rules

**Code & Comments**: English only
- Variable names: English
- Function names: English
- Class names: English
- Comments: English

**Commit Messages**: English only
- Follow rules in `.clinerules/global/git-instructions.md`

**UI Text**: Dutch only
- All user-facing text must be in Dutch
- **CRITICAL**: BER has NO translation system (no ngx-translate, no i18n files)
- UI text is hardcoded Dutch strings directly in templates
- Do NOT introduce translation keys or translation pipes

**Example**:
```html
<!-- ✅ CORRECT for BER - hardcoded Dutch -->
<h1>Bereikbaarheidskaart</h1>
<button>Opslaan</button>

<!-- ❌ WRONG - do NOT use translation keys in BER -->
<h1>{{ 'MAP.TITLE' | translate }}</h1>
<button>{{ 'GENERAL.SAVE' | translate }}</button>
```

---

## BACKEND API MAPPING

### By Feature Domain

When implementing features related to:

- **Traffic Signs (for maps)** → Read `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
  - Traffic sign CRUD, validation, removal
  - Traffic sign images and history
  - Map updates (GeoJSON)

- **Organizations & Users** → Read `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
  - Organization management
  - User management and roles (Keycloak)
  - Road authority lookups

- **Findings / Issues** → Read `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
  - Traffic sign findings and issue tracking
  - Black code uploads and validation

- **Vehicle Restrictions (WKD)** → Read `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
  - Speed limits, height/length/load/axle-load restrictions
  - Traffic type and driving direction mutations
  - School zones, road narrowings, road categories
  - NWB version-based mutations and exports

- **Environmental & Emission Zones** → Read `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
  - Environmental zones and emission zones
  - Parking bans and traffic regulations
  - Hazardous substance routes
  - Geographic areas, counties, towns

- **User Feedback / Corrections** → Read `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-feedback-backend.md`
  - User-submitted corrections about road features
  - Location-based feedback (GeoJSON points)

### By Endpoint Pattern

When working with specific endpoints:

- `/traffic-signs/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/images/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/organizations/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/users/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/findings/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/black-codes/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/info-messages/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/road-authorities/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-backend.md`
- `/speeds/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/traffic-types/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/height-restrictions/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/length-restrictions/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/load-restrictions/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/axle-load-restrictions/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/schoolzones/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/road-narrowings/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/driving-directions/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/export/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-wkd-backend.md`
- `/environmental-zones/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/emission-zones/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/parking-bans/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/traffic-regulations/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/routes/hazardous-substances/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/areas/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/counties/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-area-backend.md`
- `/corrections/**` → `$CLINERULES_ROOT/projects/BER-Bereikbaarheidskaart/backend/traffic-sign-feedback-backend.md`

**Note**: This mapping is incomplete. If you need comprehensive endpoint mapping, use the backend crawl prompt provided separately.

---

## MONOREPO STRUCTURE

```
BER-Bereikbaarheidskaart/
├── accessibility-map-frontend/       ← EDIT ONLY THIS (in /src/ subdirectory)
│   └── src/                          ← All edits happen here
├── traffic-sign-backend/             ← Reference only (shared from GRG)
├── traffic-sign-wkd-backend/         ← Reference only (shared from GRG)
├── traffic-sign-area-backend/        ← Reference only (shared from GRG)
├── traffic-sign-feedback-backend/    ← Reference only (shared from GRG)
├── ndw-design/                       ← Reference only (shared GRG design system)
└── .clinerules/                      ← Editable (documentation only)
    └── projects/BER-Bereikbaarheidskaart/
        ├── project-instructions.md   ← You are here
        └── backend/
            ├── traffic-sign-backend.md
            ├── traffic-sign-wkd-backend.md
            ├── traffic-sign-area-backend.md
            └── traffic-sign-feedback-backend.md
```

---

## WHEN TO READ OTHER FILES

**For backend API details**: Read the appropriate backend markdown file based on the mapping above

**For updating backend API docs**: Read `$CLINERULES_ROOT/global/update-backend-api-instructions.md`

**For code validation**: See `$CLINERULES_ROOT/validation/checklists/` for file-type-specific validation checklists. Each checklist consolidates ALL rules from the 6 validation rule files (angular-instructions, code-simplicity, angular-style, angular-class-structure, dead-code-detection, sonarqube-rules).
