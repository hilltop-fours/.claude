# agent-browser

Sources (check these to validate any commands/behavior documented here):
- SKILL.md (intro/overview): https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/SKILL.md
- authentication.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/authentication.md
- commands.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/commands.md
- profiling.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/profiling.md
- proxy-support.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/proxy-support.md
- session-management.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/session-management.md
- snapshot-refs.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/snapshot-refs.md
- video-recording.md: https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/references/video-recording.md

---

## Critical rules

| Rule | Detail |
|------|--------|
| Global flags BEFORE command | `agent-browser --headed open <url>` ✓ never after |
| Re-snapshot after any nav/DOM change | Refs (@e1) invalidate on navigation or dynamic updates |
| `--headed` required for 2FA | Opens visible Chromium window for manual intervention |
| Chain with `&&` when no intermediate output needed | `open && wait --load networkidle && screenshot` |
| **NEVER click on the map canvas** | MapLibre GL map interactions (clicking roads, signs, zones) do NOT work via agent-browser. Always use deep-link URLs instead (see GRG URLs below). |

---

## GRG deep-link URLs (use these instead of map clicks)

### Single road section
`http://localhost:4200/kaart/wegvakken/600935682/kenmerken/maximumsnelheid?kaartlagen=SPEED_LIMIT,BRT,TRAFFIC_SIGN_DRAFT&zichtbaar-gebied=5.12256,52.07926,5.183,52.11129&maxsnelheidfilter=1f5451a0.________Dw`

- Road section 600935682 = Archimedeslaan, Utrecht, 30 km/h
- Change feature type via the "Wegkenmerk" dropdown in the left panel (Maximumsnelheden, Wegcategorieën, Rijrichtingen, RVM, etc.)

### Multi-select with 1 road pre-loaded (correct approach)
There is NO multi-select deep-link URL that pre-selects roads. Instead:
1. Open the single road section URL above
2. Click the mode toggle button: `agent-browser find text "Modus: Single select" click`
3. App navigates to `/kaart/wegvakken/multiselect/maximumsnelheid` with road 600935682 already in the list
4. Right panel shows: "1 snelheidssegment:", speed pill (30), "Archimedeslaan [600935682]", "van 0 tot 447 - Beide", × button
5. Bottom bar now reads "Modus: Multi-select" — confirmed in multi-select mode

No need to dismiss tour — run `agent-browser storage local set intro-tour-finished true` after open (see NDW login flow below).

More URLs (traffic signs, zones, etc.) to be added when needed.

---

## Credentials

| Profile | Email | Password | App | Port |
|---------|-------|----------|-----|------|
| grg-admin | daniel.wildschut@ndw.nu | bumpyn-hombok-3fIdwi | GRG | 4200 |
| ntm-admin | daniel.wildschut+admin@ndw.nu | bUzpos-hopdaf-jyqgo3 | NTM | 4202 |
| ntm-hoofd-publicist | daniel.wildschut+hoofd.publicist@ndw.nu | Nidvip-kodjaz-9bexqa | NTM | 4202 |
| ntm-publicist | daniel.wildschut+publicist@ndw.nu | pahdof-2Jukwe-dohhak | NTM | 4202 |

`auth login <profile>` fails on Keycloak — always use `fill` directly.

---

## NDW login flow

### Saved state (always try first):
```bash
agent-browser state load ~/.claude/agent-browser/<profile>.json
agent-browser open http://localhost:<port>
agent-browser wait --load networkidle
URL=$(agent-browser get url)
# if URL contains /login → state expired, proceed to login flow below
```

Saved states: `~/.claude/agent-browser/grg-admin.json`, `~/.claude/agent-browser/ntm-admin.json`

**After opening GRG — always set this before interacting:**
```bash
agent-browser storage local set intro-tour-finished true
```
This suppresses the "Welkom!" tour modal. Run it once after `open`, before any `snapshot` or clicks. Then `state save` will persist it automatically.

### NTM login (no 2FA — fully automated):
```bash
agent-browser open http://localhost:4202
agent-browser snapshot -i
agent-browser fill @e_email "daniel.wildschut+admin@ndw.nu"
agent-browser click @e_password && agent-browser keyboard type "bUzpos-hopdaf-jyqgo3"
agent-browser click @e_submit
agent-browser wait --load networkidle
agent-browser state save ~/.claude/agent-browser/ntm-admin.json
```
- Try max 2 times. If both fail → `agent-browser --headed open` and tell user to fix it manually in the browser.

### GRG login (has 2FA — requires user input):
```bash
# Step 1: fill credentials (try max 2 times)
agent-browser open http://localhost:4200
agent-browser snapshot -i
agent-browser fill @e_email "daniel.wildschut@ndw.nu"
agent-browser click @e_password && agent-browser keyboard type "bumpyn-hombok-3fIdwi"
agent-browser click @e_submit
agent-browser wait --load networkidle
# Step 2: ask user in chat for 6-digit 2FA code
# "Please give me your 2FA code for GRG login"
agent-browser snapshot -i   # get ref for 2FA input field
agent-browser fill @e_2fa "<code-from-user>"
agent-browser click @e_submit
agent-browser wait --load networkidle
agent-browser state save ~/.claude/agent-browser/grg-admin.json
```
- Try credentials max 2 times. Try 2FA code max 2 times.
- If either fails twice → `agent-browser --headed open http://localhost:4200` and tell user to fix it in the browser window.

State files: never commit. `~/.claude/agent-browser/` is outside all repos.

---

## Use cases

### 1. Regression check (code changed — verify still works)

Goal: confirm existing behavior is preserved after refactor/migration.

Protocol:
1. Before code change: `agent-browser screenshot --full /tmp/before.png`
2. Make code changes
3. After change: `agent-browser screenshot --full /tmp/after.png`
4. Compare: `agent-browser diff screenshot --baseline /tmp/before.png`
5. Check JS errors: `agent-browser errors` — must be empty
6. Check console: `agent-browser console` — no unexpected Angular errors

Key assertions for signal migration work:
- `agent-browser is visible @e_component` — component renders
- `agent-browser is enabled @e_button` — button states correct
- `agent-browser errors` — no runtime errors (Angular throws here on broken signals)

### 2. Feature validation (new feature — does it work as specified)

Goal: verify a newly implemented feature does what the story says.

Protocol:
1. Read story markdown to extract acceptance criteria
2. If criteria unclear → ask user to fill gaps before starting
3. Build step-by-step test plan using specific agent-browser commands
4. Present plan to user for approval
5. Execute — assert with `is visible`, `is enabled`, `get text`, `get styles` not just screenshots
6. For edge cases: mock API with `network route <url> --body '{}'` to test error/empty/loading states
7. Intercept API calls: `network requests --filter api` to verify correct endpoint + payload called

Always produce test plan before executing. Never start blind.

### 3. PR review (verify PR branch still works)

Goal: confirm PR doesn't break existing functionality and new behavior works.

Protocol:
1. Checkout PR branch locally, run dev server
2. Diff against main visually: screenshot both branches, compare with `agent-browser diff screenshot --baseline /tmp/main.png`
   (run two servers on different ports — screenshot main branch first, then PR branch)
3. Run regression assertions on affected routes
4. Check `agent-browser errors` and `agent-browser console` for runtime issues
5. If PR adds new feature: run feature validation flow (use case 2)

### 4. Exploratory debugging (something is broken — reproduce + diagnose)

Goal: reproduce a reported bug, identify root cause without manual DevTools.

Protocol:
1. Navigate to affected route
2. `agent-browser errors` — check for JS exceptions first
3. `agent-browser console` — Angular errors appear here (broken signals, null refs, etc.)
4. `agent-browser network requests --filter api` — check if API calls are failing or returning unexpected data
5. `agent-browser screenshot --annotate` — document the broken state with element labels
6. `agent-browser is visible / is enabled @e_element` — assert specific elements that should/shouldn't be there
7. Report findings: errors + network + screenshot together give full picture

This replaces: manually opening DevTools, copying network requests, copy-pasting to Claude. Do it all in one flow.

---

## Commands

### Navigation
```bash
agent-browser open <url>
agent-browser back / forward / reload
agent-browser close
```

### Snapshot
```bash
agent-browser snapshot -i              # interactive elements only (recommended)
agent-browser snapshot -i -C           # include cursor-interactive divs/spans
agent-browser snapshot @e5             # scope to specific ref (reduces noise)
agent-browser snapshot -c              # compact output
agent-browser snapshot -d 3            # limit depth
```

### Interact
```bash
agent-browser click @e1
agent-browser fill @e2 "text"              # clears then types
agent-browser type @e2 "text"              # types without clearing
agent-browser keyboard type "text"        # insert text via keyboard (best for passwords — avoids fill clearing)
agent-browser select @e1 "option"
agent-browser check @e1 / uncheck @e1
agent-browser hover @e1
agent-browser scroll down 500
agent-browser drag @e1 @e2
agent-browser upload @e1 file.pdf
agent-browser press Enter / Control+a
```

### Semantic locators (when refs unreliable)
```bash
agent-browser find text "Inloggen" click
agent-browser find text "Submit" click --exact   # exact match only
agent-browser find role button click --name "Submit"
agent-browser find label "Email" fill "user@example.com"
agent-browser find placeholder "Search" type "query"
agent-browser find alt "Logo" click
agent-browser find testid "submit-btn" click
agent-browser find nth 2 "a" hover
agent-browser find first ".item" click
agent-browser find last ".item" click
```

### Get info
```bash
agent-browser get url
agent-browser get title
agent-browser get text @e1
agent-browser get value @e1          # input field value
agent-browser get attr @e1 href
agent-browser get styles @e1         # computed CSS (font, color, bg, etc.)
agent-browser get count ".item"      # count matching elements
agent-browser get box @e1            # bounding box
```

### Assert state
```bash
agent-browser is visible @e1
agent-browser is enabled @e1
agent-browser is checked @e1
```

### Wait
```bash
agent-browser wait --load networkidle                        # best for Angular/SPA pages
agent-browser wait --url "**/dashboard"                      # URL pattern
agent-browser wait --url "**/dashboard" --timeout 120000     # with custom timeout (ms)
agent-browser wait --text "Gelukt"                           # text appears
agent-browser wait @e1                                       # element appears
agent-browser wait 2000                                      # ms (last resort)
agent-browser wait --fn "window.ready"                       # JS condition
```

### Screenshot / diff

Token cost rule: taking a screenshot costs zero tokens — it writes to disk. Tokens are only spent when Claude reads the file back using the Read tool. Therefore:
- Take screenshots freely
- Only read back when visual inspection is actually needed (e.g. broken layout, annotated debugging)
- Never loop Read on every step — one targeted read at the right moment
- Prefer `diff snapshot`, `errors`, `is visible` over reading screenshots where possible (text output is cheaper)

```bash
agent-browser screenshot /tmp/shot.png
agent-browser screenshot --full
agent-browser screenshot --annotate            # numbered labels, caches refs — read back when debugging layout
agent-browser diff snapshot                    # current vs last snapshot (text, no token cost)
agent-browser diff screenshot --baseline /tmp/before.png  # visual pixel diff — read result image back once
agent-browser pdf output.pdf
```

### Cookies and storage
```bash
agent-browser cookies                          # get all cookies
agent-browser cookies set name value           # set a cookie
agent-browser cookies clear                    # clear all cookies
agent-browser storage local                    # get all localStorage
agent-browser storage local key                # get specific key
agent-browser storage local set key value      # set a value (e.g. intro-tour-finished true)
agent-browser storage local clear              # clear all localStorage
```

### Tabs and frames
```bash
agent-browser tab                              # list tabs
agent-browser tab new [url]                    # open new tab
agent-browser tab 2                            # switch to tab by index
agent-browser tab close                        # close current tab
agent-browser frame "#iframe"                  # switch into iframe
agent-browser frame main                       # back to main frame
agent-browser dialog accept                    # accept a browser dialog/alert
agent-browser dialog dismiss                   # dismiss a dialog
```

### Mouse
```bash
agent-browser mouse move 100 200
agent-browser mouse down left
agent-browser mouse up left
agent-browser mouse wheel 100
```

### Debug
```bash
agent-browser console                          # browser console output
agent-browser errors                           # JS page errors — check after every test
agent-browser highlight @e1
agent-browser trace start / stop trace.zip
agent-browser profiler start
agent-browser profiler stop trace.json         # open in https://ui.perfetto.dev/
```

### Network (API mocking / inspection)
```bash
agent-browser network route <url> --abort      # block requests
agent-browser network route <url> --body '{}'  # mock response (test edge cases)
agent-browser network unroute [url]
agent-browser network requests --filter api    # inspect actual API calls made by app
```

### State
```bash
agent-browser state save ./auth.json
agent-browser state load ./auth.json
agent-browser state list
agent-browser state clean --older-than 7
```

### Sessions (parallel / isolated)
```bash
agent-browser --session grg open http://localhost:4200
agent-browser --session pr  open http://localhost:4201   # PR branch on different port
agent-browser --session grg snapshot -i
agent-browser session list
```

### Browser settings
```bash
agent-browser set viewport 1920 1080
agent-browser set device "iPhone 14"
agent-browser set media dark
agent-browser set offline on
```

### JavaScript eval
```bash
agent-browser eval "document.title"

# Complex JS — heredoc avoids shell escaping:
agent-browser eval --stdin <<'EOF'
Array.from(document.querySelectorAll('a')).map(a => a.href)
EOF
```

### Video recording
```bash
agent-browser record start ./session.webm
agent-browser record stop
```
Token cost: zero — recording writes to disk, never fed back to Claude. Use freely for debugging (watch .webm yourself). Do NOT read frames back as screenshots in a loop.

---

## Gotchas

| Issue | Fix |
|-------|-----|
| `--headed` not showing window | Must be BEFORE command: `agent-browser --headed open <url>` |
| Ref stops working after click | Re-snapshot — invalidated after nav/DOM change |
| Password field clears | Use `keyboard type` instead of `fill` (documented) — `keyboard inserttext` also worked in practice but is not in the official docs |
| Page still loading | `wait --load networkidle` before snapshot |
| Keycloak `auth login` fails | Use `fill` directly |
| State expired | Re-run headed 2FA flow, re-save state |
| **WebGL context creation failed** | Pre-existing in headless mode — no GPU available. Not a bug. Ignore this error. |
| **`zoomIn`/`zoomOut` on undefined** | Cascade of WebGL failure — map object is null. Pre-existing. Ignore. |
| **Map canvas clicks don't work** | MapLibre GL requires real GPU pointer events. Never attempt. Use deep-link URLs (see GRG URLs section above). To test a different road type, use the same deep-link URL and change the feature type in the dropdown (or navigate to a different road via URL). |
