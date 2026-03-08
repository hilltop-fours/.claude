# NTM PUBLICATIE OVERZICHT - PROJECT INSTRUCTIONS

**Project**: NTM Publicatie Overzicht
**Working directory path contains**: `/NTM-Publicatie-overzicht`
**Frontend repository**: `ntm-frontend/` (edit in `/src/**` only)
**Backend services**: `ntm-backend`, `ntm-tracker-backend` (reference only)
**Design system**: `ndw-design/` (reference only)

---

## FRONTEND RULES

### Design System

**Location**: `/ndw-design/libs/ntm` (reference only, never edit)

**Usage Rules**:
- Most common components available: cards, tabs, buttons, forms, modals, drawers, inputs, selects, etc.
- Design system components have associated models/interfaces
- NEVER hardcode strings/values that exist in component models
- Default to design system components when creating UI elements
- Assume components exist unless explicitly told otherwise
- If unsure about a component, search design system first before creating custom components

**Component Import Pattern**:
```typescript
import { ComponentName } from '@shared/components/component-name';
```

### Language Rules

**Code & Comments**: English only
- Variable names, function names, class names, comments: English

**Commit Messages**: English only
- Follow rules in `$CLAUDE_ROOT/global/git-instructions.md`

**UI Text**: Dutch only
- All user-facing text must be in Dutch
- Use ngx-translate (`@ngx-translate/core`) translation system
- NEVER hardcode Dutch strings in components
- Always use translation keys: `{{ 'TRANSLATION.KEY' | translate }}`

### Translation System

**System**: ngx-translate (`@ngx-translate/core`)

**Translation Files**:
- `src/i18n/nl.json` - Dutch (primary language)
- `src/i18n/en.json` - English (language toggle for non-Dutch users)

**Rules**:
- ALL new translation keys MUST be added to BOTH files
- Dutch values: user-facing text in Dutch
- English values: same text translated to English
- Keep keys synchronized between both files
- Use descriptive key names with proper namespacing

**Example**:
```typescript
// ❌ BAD - Hardcoded Dutch
<h1>Publicaties</h1>
<button>Opslaan</button>

// ✅ GOOD - Translation keys
<h1>{{ 'PUBLICATIONS.TITLE' | translate }}</h1>
<button>{{ 'GENERAL.SAVE' | translate }}</button>
```

**Translation File Example**:
```json
// nl.json
{
  "PUBLICATIONS": {
    "TITLE": "Publicaties",
    "SAVE": "Opslaan"
  }
}

// en.json
{
  "PUBLICATIONS": {
    "TITLE": "Publications",
    "SAVE": "Save"
  }
}
```

### Filter Components and Query Params

**Pattern**: Filter components MUST subscribe to `route.queryParams` and reactively update their state when query params change.

**Why**: This allows parent components (like `*-filters-aside`) to clear filters by simply updating the URL params. The filter components will automatically sync their UI state. This avoids tight coupling where parents need to manually call `deselectAll()` on child components.

**CORRECT Pattern** (reactive):
```typescript
@UntilDestroy()
@Component({
  // ...
  providers: [{ provide: BaseFilterDirective, useExisting: MyFilterComponent }],
})
export class MyFilterComponent extends BaseFilterDirective {
  constructor() {
    super();
    this.queryParamName = QUERY_PARAMS.MY_FILTER;

    // Subscribe to query param changes and update options reactively
    this.route.queryParams.pipe(untilDestroyed(this)).subscribe((params) => {
      const activeFilters = params[this.queryParamName]?.split(',') || [];
      this.#updateOptions(activeFilters);
    });
  }

  #updateOptions(activeFilters: string[]): void {
    this.options.set(
      FILTER_VALUES.map((value) => ({
        labelPath: `TRANSLATIONS.${value}`,
        value: value,
        checked: activeFilters.includes(value),
      }))
    );
    this.cdr.detectChanges();
  }
}
```

**INCORRECT Pattern** (one-time read):
```typescript
// ❌ DON'T DO THIS - Only reads params once on init, doesn't react to changes
export class MyFilterComponent extends BaseFilterDirective implements OnInit {
  ngOnInit(): void {
    const activeFilters = this.getActiveFiltersFromQueryParams(); // snapshot only!
    // ... populate options
  }
}
```

**Parent Component** (clearFilters):
```typescript
// ✅ CORRECT - Just update URL, child filters will react automatically
clearFilters() {
  this.#filtersService.updateUrlParams({
    [QUERY_PARAMS.MY_FILTER]: null,
  });
}

// ❌ INCORRECT - Manual coupling to child components
clearFilters() {
  this.#filtersService.updateUrlParams({ [QUERY_PARAMS.MY_FILTER]: null });
  this.filterComponents().forEach((f) => f.deselectAll()); // Don't do this!
}
```

**Reference Examples**:
- Reactive: `data-import-filter-date.component.ts`, `search-input.component.ts`
- Reactive: `publication-review-filter-status.component.ts` (updated)

**Note**: Some older filter components in the codebase still use the incorrect pattern. When modifying these, consider refactoring to the reactive pattern.

---

## BACKEND API MAPPING

### By Feature Domain

When implementing features related to:

- **Data Publications** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - CRUD operations on data publications
  - Search, filtering, pagination
  - Approve, reject, hold, transfer ownership
  - Favorites on data publications
  - Import via DCAT dataset (`/data-publications/import`)

- **Datasets & Imports** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend.md`
  - Dataset listing, retrieval, rejection
  - Dataset import (`/datasets/import`)

- **Datasets (listing only)** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - List all datasets (`/datasets`)

- **Organizations** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - CRUD operations on organizations
  - Role requests (create, approve, deny)
  - User listing per organization
  - Logo management
  - Permissions / moderation settings
  - Organization repair utilities (`/repair/organizations`)

- **Users** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - CRUD operations on users
  - Current user info (`/users/current`)
  - Password reset

- **Notifications & Subscriptions** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - Notification listing and count (`/notifications`)
  - Email subscription management (`/subscriptions/mine`)

- **Favorites** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - List, add, delete favorites (`/favorites`)

- **Regions** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - Region lookup by code
  - Municipality listing (`/regions/municipalities`)

- **Standards** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - CRUD operations on standards

- **Data Regulations** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - List all regulations and get by regulation type (RegulationType path param)

- **Statistics** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - User, organization, and data publication counts

- **Export** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - Export publications and users (`/export`)

- **Info Messages** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - CRUD operations on info messages
  - Current active messages and count

- **Blobs / Images** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - Upload and retrieve images (`/blobs/image`)

- **Contact Requests** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - Submit contact request (`/contact-request`)

- **Translations** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - Translation usage info (`/translations/usage`)

- **DCAT** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
  - DCAT-AP dataset endpoints (`/v1`)

- **External Organizations** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend.md`
  - List and get external organizations

- **External Categories** → Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend.md`
  - List and get external categories

### By Endpoint Pattern

When working with specific endpoints:

- `/data-publications/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/data-publications/import` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/datasets` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md` (listing only)
- `/datasets/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend.md` (import, reject, detail)
- `/organizations/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/repair/organizations/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/users/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/notifications/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/subscriptions/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/favorites/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/regions/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/standards/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/data-regulations/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/statistics/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/export/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/info-messages/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/blobs/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/contact-request` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/translations/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md`
- `/v1/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-backend.md` (DCAT-AP)
- `/external-organizations/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend.md`
- `/external-categories/**` → `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/backend/ntm-tracker-backend.md`


## PATTERN DOCUMENTATION

NTM uses specific patterns for recurring implementation scenarios. Each pattern is documented in its own focused file:

**WHEN working with services** (`*.service.ts` files):
→ Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/patterns/service-patterns.md`
- Service categories (API/HTTP, complex, auth, URL coordination, framework, utility)
- No BaseService — plain injectable classes only
- `baseUrl` field convention, `share()` usage, `Accept-Language` header pattern
- Service vs repository boundary (services return observables, repositories subscribe)
- File location rules and naming conventions

**WHEN working with repositories** (`*.repository.ts` files):
→ Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/patterns/repository-patterns.md`
- Store structure and BaseRepository lifecycle methods
- Observable field pattern (use `readonly field$`, not `get field$()` getter)
- Standard action method shape (pending → HTTP → success/error → return observable)
- Naming conventions, file location, refresh patterns, deduplication cache

**WHEN working with accessible forms (WCAG 3.3.1 compliance)**:
→ Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/patterns/form-accessibility.md`
- Error message formatting
- ARIA live regions & aria-invalid attributes
- Focus management
- Required field indicators
- Visual differentiation (non-color based)
- Form validation implementation
- Testing checklists

**WHEN working with query parameters for routing, filtering, or deep linking**:
→ Read `$CLAUDE_ROOT/projects/NTM-Publicatie-overzicht/patterns/query-params.md`
- Feature-specific deep linking
- Navigation state preservation
- Pagination patterns
- Filtering & search
- Security considerations
- Testing approaches

---

## WHEN TO READ OTHER FILES

**For backend API details**: Read the appropriate backend markdown file based on the mapping above

**For updating backend API docs**: Read `$CLAUDE_ROOT/global/update-backend-api-instructions.md`

**For code validation**: See `$CLAUDE_ROOT/validation/checklists/` for file-type-specific validation checklists. Each checklist consolidates ALL rules from the 6 validation rule files (angular-instructions, code-simplicity, angular-style, angular-class-structure, dead-code-detection, sonarqube-rules).
