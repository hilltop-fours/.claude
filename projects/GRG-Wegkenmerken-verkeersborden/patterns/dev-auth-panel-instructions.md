# DEV AUTH PANEL PATTERN — GRG

## Purpose

A floating dev panel (top-left pill) for switching org/persona context during local testing — without needing separate Keycloak accounts or manually editing config files.

**Use cases:**
- Testing org-specific UI behavior (which road sections a user can edit)
- Switching between a limited municipality user and a full admin org
- Toggling the mock on/off to test with the real Keycloak token

**Not committed to the branch.** Add when needed, remove when done.

---

## What It Does

Four files in `core/dev/`:

1. **`dev-auth-mock.config.ts`** — defines personas (role + org data), reads active persona from localStorage
2. **`dev-auth-mock.interceptor.ts`** — HTTP interceptor, fakes the `/api/organizations/{id}` response
3. **`dev-auth-panel.component.ts/html/scss`** — floating UI panel to switch personas at runtime

The interceptor replaces the org API response with the active persona's org data. The panel writes to localStorage and reloads to apply changes. Role checks in `auth.service.ts` are also overridden to use the persona's roles instead of the real Keycloak JWT token.

---

## Scope: What the mock controls

| Concern | Mocked? | How |
|---------|---------|-----|
| Organization name | ✅ | Interceptor replaces `/api/organizations/{id}` response |
| Road authorities (what roads user can edit) | ✅ | Part of org response |
| `hasGlobalMutationPermissions` | ✅ | Part of org response |
| Route-level access (AuthGuard) | ✅ | `hasRoles()` override uses persona roles |
| Feature visibility (isAdmin, isTrafficSignEditor) | ✅ | `hasRoles()` override uses persona roles |

---

## Step 1 — Copy the dev folder

Copy the entire `patterns/dev/` folder from `.clinerules` into the frontend:

**Source**: `.clinerules/projects/GRG-Wegkenmerken-verkeersborden/patterns/dev/`
**Destination**: `traffic-sign-frontend/src/app/core/dev/`

That's it — all 5 files land in place in one operation:
- `dev-auth-mock.config.ts`
- `dev-auth-mock.interceptor.ts`
- `dev-auth-panel.component.ts`
- `dev-auth-panel.component.html`
- `dev-auth-panel.component.scss`

---

## Step 2 — Register the interceptor in main.ts

Add one import and one provider to `traffic-sign-frontend/src/main.ts`:

```typescript
// Import (with other interceptor imports at the top):
import { DevAuthMockInterceptor } from '@core/dev/dev-auth-mock.interceptor';

// Provider (after ErrorIdLogInterceptor):
{ provide: HTTP_INTERCEPTORS, useClass: DevAuthMockInterceptor, multi: true },
```

The interceptor self-disables when `DEV_AUTH_MOCK_ENABLED = false` (localStorage), so it is safe to register unconditionally in non-production.

---

## Step 3 — Override hasRoles() in auth.service.ts

Add the role mock to `traffic-sign-frontend/src/app/core/auth/auth.service.ts`:

```typescript
// Add import at the top (line 17, after AuthRoleEnum import):
import { DEV_ACTIVE_PERSONA, DEV_AUTH_MOCK_ENABLED } from '@core/dev/dev-auth-mock.config';

// Replace hasRoles():
hasRoles(roles: AuthRoleEnum[], oneOfRole = true): boolean {
  if (DEV_AUTH_MOCK_ENABLED) {
    const mockRoles = DEV_ACTIVE_PERSONA.roles;
    return oneOfRole ? roles.some((r) => mockRoles.includes(r)) : roles.every((r) => mockRoles.includes(r));
  }
  return this.#ndwAuthService.hasRoles(roles, oneOfRole ? 'any' : 'all');
}
```

---

## Step 4 — Add the panel to app.component

In `traffic-sign-frontend/src/app/app.component.ts`:
```typescript
import { DevAuthPanelComponent } from '@core/dev/dev-auth-panel.component';

// Add to @Component imports array:
imports: [HotkeyModule, RouterOutlet, DevAuthPanelComponent],
```

In `traffic-sign-frontend/src/app/app.component.html`:
```html
<hotkeys-cheatsheet [title]="'Toetsenbord shortcuts'"></hotkeys-cheatsheet>
<router-outlet />
<tsf-dev-auth-panel />
```

---

## Step 5 — Use the panel

1. Run `npm start`
2. A **DEV** pill appears in the top-left corner
3. Click it to expand — shows current org, road authority, active persona, roles
4. Click a persona button → page reloads → mock applies the new persona's org
5. "Mock uitschakelen" → page reloads → app uses real Keycloak org data
6. Road authority switching (if persona has multiple) → no reload, instant

---

## Step 6 — Remove when done

Delete the entire folder:
- `traffic-sign-frontend/src/app/core/dev/`

Revert these files:
- `traffic-sign-frontend/src/main.ts` — remove the `DevAuthMockInterceptor` import and provider line
- `traffic-sign-frontend/src/app/app.component.ts` — remove `DevAuthPanelComponent` import and from `imports` array
- `traffic-sign-frontend/src/app/app.component.html` — remove `<tsf-dev-auth-panel />`
- `traffic-sign-frontend/src/app/core/auth/auth.service.ts` — remove the `DEV_ACTIVE_PERSONA`/`DEV_AUTH_MOCK_ENABLED` import and restore original `hasRoles()`:
  ```typescript
  hasRoles(roles: AuthRoleEnum[], oneOfRole = true): boolean {
    return this.#ndwAuthService.hasRoles(roles, oneOfRole ? 'any' : 'all');
  }
  ```

Also clear localStorage keys if needed:
```javascript
localStorage.removeItem('dev-mock-enabled');
localStorage.removeItem('dev-mock-persona');
```

---

## How It Works — Technical Notes

### Why localStorage + reload instead of reactive signals?

`dev-auth-mock.config.ts` is a plain TypeScript module — its exports are evaluated once at Angular bootstrap. `DEV_ACTIVE_PERSONA` and `DEV_AUTH_MOCK_ENABLED` are frozen for the lifetime of the app instance. Making them reactive (signals) would require threading those signals through the interceptor and auth service, adding complexity. localStorage + reload is simpler and more reliable: next bootstrap picks up the new values cleanly.

### Why is road authority switching reactive (no reload)?

Road authority is stored in the Elf `UserRepository` store (`user-ui` localStorage key). `updateActiveRoadAuthority()` updates the store synchronously and all signals/observables react immediately. No HTTP intercept needed — the org response already contains the full list of road authorities.

### The `hasRoles()` override

`auth.service.ts` has a temporary override that checks `DEV_AUTH_MOCK_ENABLED` before delegating to the real JWT check. When the mock is enabled, it uses the active persona's roles instead of the Keycloak token. This is the only file outside `core/dev/` that needs manual changes — it cannot live in the `dev/` folder because it's a core service.

### What the org data controls (interceptor mock):
- Which road authorities the user belongs to → `roadAuthorities: [{type, code}]`
- Global edit permissions → `hasGlobalMutationPermissions: true`
- RVM mutation permissions → `hasRvmMutationPermissions: true`
- HGV charge permissions → `hasHgvChargePermissions: true`

### RoadAuthorityType codes:
| Type | Meaning | Example code |
|------|---------|--------------|
| `G`  | Gemeente (municipality) | `'796'` = Den Bosch (GM0796) |
| `P`  | Provincie (province) | `'27'` = Noord-Brabant |
| `R`  | Rijk / Rijkswaterstaat | national roads |
| `W`  | Waterschap | water authority |
| `T`  | Other | tunnels, etc. |

### Municipality codes:
Find codes via road section details in the app — check the "wegbeheerder" field or the NWB data in the network tab for `roadOperatorCode` and `roadOperatorType`.

---

## Adding New Personas

Edit `DEV_PERSONAS` in `dev-auth-mock.config.ts`:

```typescript
utrechtUser: {
  label: 'Utrecht — gemeente gebruiker',
  roles: [AuthRoleEnum.User, AuthRoleEnum.TrafficSignEdit],
  organization: {
    id: 'mock-org-utrecht',
    name: 'Gemeente Utrecht (MOCK)',
    hasGlobalMutationPermissions: false,
    hasRvmMutationPermissions: false,
    hasHgvChargePermissions: false,
    roadAuthorities: [
      {
        id: 'mock-ra-utrecht',
        name: 'Utrecht',
        type: RoadAuthorityType.G,
        code: '344',  // GM0344 = Utrecht
        rwsId: '',
      },
    ],
  },
},
```

The new persona appears automatically in the panel — no other changes needed.
