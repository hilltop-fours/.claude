# GRG WEGKENMERKEN VERKEERSBORDEN - PROJECT INSTRUCTIONS

## PROJECT IDENTIFICATION

Working directory path contains: `/GRG-Wegkenmerken-verkeersborden`

## REPOSITORY LOCATIONS

### Frontend
- **Path**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-frontend/`
- **Git operations**: ALL git commands (checkout, add, commit, push, status, branch, etc.) MUST execute from this directory
- **Editable**: YES - Only edit files in `/traffic-sign-frontend/src/**`

### Backend Services (Reference Only - Never Edit)
- **traffic-sign-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-backend/`
- **traffic-sign-area-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-area-backend/`
- **traffic-sign-wkd-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-wkd-backend/`
- **traffic-sign-inspection-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-inspection-backend/`
- **traffic-sign-wkd-derivation-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-wkd-derivation-backend/`
- **traffic-sign-feedback-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-feedback-backend/`
- **traffic-sign-hgv-charge-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-hgv-charge-backend/`
- **traffic-sign-profile-backend**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-profile-backend/`

### Design System (Reference Only - Never Edit)
- **Path**: `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/ndw-design/`

**CRITICAL**: Project root `/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden` is NOT a git repository. Git commands will fail if executed there.

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

**Location**: `/ndw-design/` (reference only, never edit)

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
- Follow rules in `.claude/global/git-instructions.md`

**UI Text**: Dutch only
- All user-facing text must be in Dutch

**CRITICAL: NO TRANSLATION SYSTEM**
- GRG does NOT use ngx-translate or any i18n framework
- There are NO translation files (no `nl.json`, no `en.json`)
- UI text is hardcoded as Dutch strings directly in templates

**Example**:
```typescript
// ✅ CORRECT for GRG - hardcoded Dutch
<h1>Verkeersborden</h1>
<button>Opslaan</button>

// ❌ WRONG for GRG - do NOT use translation keys
<h1>{{ 'TRAFFIC_SIGNS.TITLE' | translate }}</h1>
```

---

## FRONTEND PATTERNS

Project-specific patterns and conventions are documented in the `patterns/` folder.

**Styling Guidelines**:
→ Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/styling-guidelines.md`

When to read:
- Before writing any CSS classes or styles
- When adding inline styles to components
- When unsure about which CSS classes to use

Critical rule: NEVER use Bootstrap classes. Only use classes from `/traffic-sign-frontend/src/assets/styles/`.

**Service Patterns**:
→ Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/service-patterns.md`

When to read:
- Before creating a new `*.service.ts` file
- Before adding methods to an existing service
- When unsure whether code belongs in a service or a repository

**Repository Patterns**:
→ Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/repository-patterns.md`

When to read:
- Before creating a new `*.repository.ts` file
- Before adding methods to an existing repository
- When unsure whether code belongs in a repository or a service
- When working with Elf stores or state management

**Dev Auth Panel**:
→ Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/dev-auth-panel-instructions.md`

When to read:
- When user asks to load, set up, add, or remove the dev panel
- When testing org/persona context locally during development

---

## BACKEND API MAPPING

*Last crawled: 2026-02-03*

### By Feature Domain

When implementing features related to:

- **Traffic Signs (CRUD, search, management)** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Create, read, update, delete traffic signs (`traffic-signs/**`)
  - Traffic sign search, filtering, map updates
  - Traffic sign history (`traffic-signs/{id}/history`)
  - Traffic sign validation, road-section assignment, removal
  - RVV code upload (`traffic-signs/rvv-codes`)
  - Traffic sign import (`traffic-signs/import`)
  - Main signs CRUD (`rest/static-road-data/traffic-signs/v5/main-signs`)

- **Mutation Proposals** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Mutation listing and road-section authority jobs (`mutations/**`)

- **Findings / Inspection Results** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Traffic sign findings CRUD, map view, per-sign findings (`findings/**`)

- **Organizations & Users** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Organization CRUD, search, authority checks, logo upload (`organizations/**`)
  - User CRUD, current user, password reset (`users/**`)
  - Road authority listing and search (`road-authorities/**`)

- **Images & Blobs** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Traffic sign images upload and retrieval (`images/**`)
  - Generic blob/PDF retrieval (`blobs/**`)

- **Black Codes** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Black code file upload and upload history (`black-codes/**`)

- **Connected Roads** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Road connectivity lookup (`connected-roads/**`)

- **Opening Hours** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Opening hours validation (`opening-hours/check-valid`)

- **Info Messages** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - System info messages CRUD (`info-messages/**`)

- **Usage Statistics** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Usage stats JSON and CSV export (`usage-statistics`)

- **Current State / Static Road Data** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Public read-only current state exports v4/v5 (`rest/static-road-data/traffic-signs/v4/current-state`, `v5/current-state`, `v5/main-signs`)
  - Event history v4 (`rest/static-road-data/traffic-signs/v4/events`)

- **OGC Features** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - OGC collections endpoint (`rest/static-road-data/traffic-signs/v4/collections`, `v5/collections`)

- **Event Processors (Admin)** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Start/stop/replay event processors, state (`event-processors/**`)

- **Current State Admin** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - Trigger current-state rebuild (`traffic-signs/current-state/v4`)

- **GraphQL** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
  - GraphQL query endpoint (`/graphql`)

- **Environmental Zones / Emission Zones** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - Zone CRUD, GeoJSON map, shapefile upload (`environmental-zones/**` / `emission-zones/**`)

- **Areas** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - Generic area CRUD (`areas/**`)

- **Parking Bans** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - Parking ban CRUD, GeoJSON map (`parking-bans/**`)

- **Traffic Regulations** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - Traffic regulation CRUD (`traffic-regulations/**`)

- **Hazardous Substance Routes** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - Hazardous substance route CRUD, map (`routes/hazardous-substances/**`)

- **Counties & Towns** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - County listing (`counties/**`)
  - Town listing (`towns`)

- **IBBM Emission Zones** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - IBBM emission zones v1 read (`ibbm/emission-zones/v1`)

- **Coordinate Conversion** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
  - WGS84 coordinate conversion (`conversion/wgs84`)

- **WKD Restrictions (per road section)** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - Axle load restrictions (`axle-load-restrictions/**`)
  - Height restrictions (`height-restrictions/**`)
  - Length restrictions (`length-restrictions/**`)
  - Load restrictions (`load-restrictions/**`)
  - Speed limits (`speeds/**`)
  - Driving directions (`driving-directions/**`)
  - Carriageway types (`carriageway-types/**`)
  - Road categories (`road-categories/**`)
  - Road narrowings (`road-narrowings/**`)
  - RVM types (`rvm-types/**`)
  - Traffic types (`traffic-types/**`)
  - School zones (`schoolzones/**`)
  - Road authorities in WKD context (`road-authorities/**`)

- **WKD Joint Mutations** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - Joint mutation listing and creation per road section (`joint-mutations/**`)

- **WKD Export** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - Export start, file listing, reprocess, migrate (`export/**`)

- **WKD File Uploads** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - File upload listing and retrieval (`file-uploads/**`)

- **WKD Blob Files** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - Blob file retrieval (`blob-files/**`)

- **WKD SFTP** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - SFTP list, test, write (`sftp/**`)

- **WKD NLS Proxies** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - NLS NWB road section data (`nls/nwb/**`)
  - NLS routing nearest-point (`nls/routing/**`)
  - NLS WKD restriction exports (`nls/wkd/**`)

- **WKD Usage Statistics** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
  - WKD usage stats JSON and CSV (`usage-statistics`)

- **Speed Mutation Proposals (WKD Derivation)** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-derivation-backend.md`
  - Speed mutation proposals per road section, CRUD (`speeds/road-section/**`)

- **Automated Inspections** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-inspection-backend.md`
  - Trigger inspection jobs: invalid black codes, road sections, unknown traffic orders, WKD checks (axle-load, height, length, load, width, speed), missing direction, NLS issues (`jobs/inspections/**`)

- **Inspection Feedback** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-inspection-backend.md`
  - Submit inspection feedback (`feedback`)

- **Feedback / Corrections** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-feedback-backend.md`
  - Correction listing, creation, GeoJSON map (`corrections/**`)

- **HGV Charges (TSV Export)** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-hgv-charge-backend.md`
  - HGV mutation TSV export by version (`mutations/{version}`)

- **Profile Backend** → Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-profile-backend.md`
  - No controllers found in source — may be a config-only or proxy service

### By Endpoint Pattern

When working with specific endpoints:

**traffic-sign-backend:**
- `/traffic-signs/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/traffic-signs/import` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/traffic-signs/{id}/history` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/traffic-signs/current-state/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/mutations/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/findings/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/organizations/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/users/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/road-authorities/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/images/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/blobs/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/black-codes/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/connected-roads/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/opening-hours/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/info-messages/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/usage-statistics` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/event-processors/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/rest/static-road-data/traffic-signs/v4/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/rest/static-road-data/traffic-signs/v5/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`
- `/graphql` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-backend.md`

**traffic-sign-area-backend:**
- `/environmental-zones/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/emission-zones/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/areas/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/parking-bans/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/traffic-regulations/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/routes/hazardous-substances/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/counties/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/towns` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/ibbm/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`
- `/conversion/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-area-backend.md`

**traffic-sign-wkd-backend:**
- `/axle-load-restrictions/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/height-restrictions/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/length-restrictions/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/load-restrictions/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/speeds/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/driving-directions/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/carriageway-types/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/road-categories/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/road-narrowings/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/rvm-types/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/traffic-types/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/schoolzones/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/road-authorities/**` (WKD context) → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/joint-mutations/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/export/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/file-uploads/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/blob-files/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/sftp/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/nls/nwb/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/nls/routing/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/nls/wkd/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`
- `/usage-statistics` (WKD context) → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-backend.md`

**traffic-sign-wkd-derivation-backend:**
- `/speeds/road-section/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-wkd-derivation-backend.md`

**traffic-sign-inspection-backend:**
- `/jobs/inspections/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-inspection-backend.md`
- `/feedback` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-inspection-backend.md`

**traffic-sign-feedback-backend:**
- `/corrections/**` → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-feedback-backend.md`

**traffic-sign-hgv-charge-backend:**
- `/mutations/{version}` (TSV) → `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/backend/traffic-sign-hgv-charge-backend.md`

**Ambiguous paths**: `/road-authorities/**` exists in both traffic-sign-backend and traffic-sign-wkd-backend. `/speeds/**` exists in both traffic-sign-wkd-backend and traffic-sign-wkd-derivation-backend (derivation uses `/speeds/road-section/`). `/usage-statistics` exists in both traffic-sign-backend and traffic-sign-wkd-backend — context determines which service is called.

---

## MONOREPO STRUCTURE

```
GRG-Wegkenmerken-verkeersborden/
├── traffic-sign-frontend/             ← EDIT ONLY THIS (in /src/ subdirectory)
│   └── src/                           ← All edits happen here
├── traffic-sign-backend/              ← Reference only
├── traffic-sign-area-backend/         ← Reference only
├── traffic-sign-wkd-backend/          ← Reference only
├── traffic-sign-inspection-backend/   ← Reference only
├── traffic-sign-wkd-derivation-backend/ ← Reference only
├── traffic-sign-feedback-backend/     ← Reference only
├── traffic-sign-hgv-charge-backend/   ← Reference only
├── traffic-sign-profile-backend/      ← Reference only
├── ndw-design/                        ← Reference only
└── .claude/                       ← Editable (documentation only)
    └── projects/GRG-Wegkenmerken-verkeersborden/
        ├── project-instructions.md    ← You are here
        ├── patterns/
        │   ├── styling-guidelines.md  ← CSS class usage rules
        │   ├── service-patterns.md    ← What belongs in *.service.ts
        │   └── repository-patterns.md ← What belongs in *.repository.ts
        └── backend/
            ├── traffic-sign-backend.md
            ├── traffic-sign-area-backend.md
            ├── traffic-sign-wkd-backend.md
            ├── traffic-sign-inspection-backend.md
            ├── traffic-sign-wkd-derivation-backend.md
            ├── traffic-sign-feedback-backend.md
            ├── traffic-sign-hgv-charge-backend.md
            └── traffic-sign-profile-backend.md
```

---

## WHEN TO READ OTHER FILES

**For styling and CSS classes**: Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/styling-guidelines.md`

**For services (creating/editing *.service.ts)**: Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/service-patterns.md`

**For repositories (creating/editing *.repository.ts)**: Read `$CLAUDE_ROOT/projects/GRG-Wegkenmerken-verkeersborden/patterns/repository-patterns.md`

**For backend API details**: Read the appropriate backend markdown file based on the mapping above

**For updating backend API docs**: Read `.claude/global/update-backend-api-instructions.md`

**For code validation**: See `$CLAUDE_ROOT/validation/checklists/` for file-type-specific validation checklists. Each checklist consolidates ALL rules from the 6 validation rule files (angular-instructions, code-simplicity, angular-style, angular-class-structure, dead-code-detection, sonarqube-rules).
