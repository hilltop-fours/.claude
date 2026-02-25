# feat(change-owner): #110156 #110689 bevinding eigenaarschap bord maken en oplossen

**Story:** #110156 — GRG [BE/FE] bevinding eigenaarschap bord maken en oplossen
**Task:** #110689 — [FE] (assigned to Daniel Wildschut, Active)
**Branch to create:** `feature/110156/110689/fix-change-owner-finding-flow`
**Status:** Analysis complete, not yet implemented. Backend PR active (PRs #118847, #118857, #118858).

---

## Story — Original Text

### Description

*(No description in Azure DevOps — story is minimal)*

### Acceptance Criteria

*(No acceptance criteria filled in)*

### Discussion

None visible

---

## Task — Original Text

### Description

[FE] — task #110689, assigned to Daniel Wildschut, Active

*(No task description visible in screenshot)*

---

## Problem

The `change-owner-modal` sends a `POST /traffic-signs/{id}/owner` to change ownership of a traffic sign. The modal currently expects a JSON response body with `{ findingCreated: boolean }` — but the backend **does not return this field** in its response body. This causes Angular's `HttpClient` to fail JSON parsing on the empty 202 response, hitting the generic error toast every time.

---

## Backend Contract (verified from source code)

### Backend branch: `feature/110156_create_finding_for_transfer_ownership`

This branch is NOT yet merged to main/staging as of 2026-02-25.

### Endpoint

```
POST /traffic-signs/{id}/owner
Body: { roadAuthorityType: RoadAuthorityType, roadAuthorityCode: string }
Auth: ROLE_TRAFFIC_SIGN_WRITER
```

### Response — Two scenarios

#### Scenario A: User has direct permission (admin or org match)
- `validateTrafficSignChangePermission(authorizationService)` passes
- `OwnerPatchedEvent` is applied to the aggregate
- Controller returns **HTTP 202 Accepted** — **empty body (void)**
- Result: ownership is changed immediately

#### Scenario B: User lacks direct permission (no org match, not admin)
- `validateTrafficSignChangePermission` throws `ForbiddenOperationException`
- The aggregate **catches** it, calls `trafficSignChangeOwnerService.createFinding(...)` as a side effect
- Then **re-throws** the `ForbiddenOperationException`
- `ForbiddenExceptionHandler` maps it to **HTTP 403 Forbidden** — **empty body**
- Result: ownership NOT changed, but a `TrafficSignFinding` with `FindingReason.TRANSFER_OWNERSHIP` is created

### Key code paths

**Aggregate handler** (`TrafficSignAggregate.java` lines ~391-402):
```java
@CommandHandler
public void handle(ChangeOwnerCommand command, ...) {
    try {
        validateTrafficSignChangePermission(authorizationService);
        // ... validation ...
        AggregateLifecycle.apply(new OwnerPatchedEvent(...));
    } catch (ForbiddenOperationException e) {
        // Create finding as side effect
        trafficSignChangeOwnerService.createFinding(
            trafficSign.getId(),
            command.getRoadAuthorityType(),
            command.getRoadAuthorityCode()
        );
        throw e; // re-throw → 403
    }
}
```

**Exception handler** (`ForbiddenExceptionHandler.java`):
```java
@ExceptionHandler(ForbiddenOperationException.class)
public ProblemDetail handle(RuntimeException exception) {
    return ProblemDetail.forStatus(FORBIDDEN); // 403, no body
}
```

**Finding creation** (`TrafficSignChangeOwnerService.java`):
```java
public TrafficSignFinding createFinding(UUID trafficSignId, RoadAuthorityType newOwnerType, String newOwnerCode) {
    var finding = TrafficSignFinding.builder()
        .trafficSign(trafficSign)
        .newOwnerRoadAuthorityType(newOwnerType)
        .newOwnerRoadAuthorityCode(newOwnerCode)
        .createdAt(Instant.now())
        .reason(FindingReason.TRANSFER_OWNERSHIP)
        .status(FindingStatus.NEW)
        .build();
    return trafficSignFindingRepository.save(finding);
}
```

---

## Current Frontend State (intentionally left broken — fix in this new branch)

### Files involved

| File | Current state |
|------|--------------|
| [traffic-sign-owner.service.ts](../../../traffic-sign-frontend/src/app/core/services/traffic-sign-owner.service.ts) | Still uses `PUT` ⚠️ (must be changed to `POST`), and has `Observable<OwnerChangeResponse>` with `findingCreated` — mismatches empty 202 body |
| [change-owner-modal.component.ts](../../../traffic-sign-frontend/src/app/shared/components/change-owner-modal/change-owner-modal.component.ts) | `next: (response) => response.findingCreated` — broken because response is void. Model access already updated to nested `owner?.code/type` (done in branch #108600/#109824 to compile). |

> ⚠️ **First fix needed**: Change `this.#http.put(...)` → `this.#http.post(...)` in `traffic-sign-owner.service.ts`. This was intentionally reverted in branch #108600/#109824 to avoid scope creep — **must be done in this new branch**.

### Why it errors

Angular's `HttpClient` with `put<OwnerChangeResponse>(...)` tries to parse the empty 202 body as JSON. Empty string is not valid JSON → parse error → `error()` callback fires instead of `next()`.

> **Note on `change-owner-modal.component.ts` model fields**: In branch #108600/#109824 the `TrafficSign` interface was refactored to use a nested `owner: { type, code }` object (replacing the flat `ownerRoadAuthorityType/Code` fields). The modal's field references were updated there (`sign.ownerRoadAuthorityCode` → `sign.owner?.code` etc.) to keep the build compiling. You do NOT need to redo those model-access changes. Only the HTTP verb, return type, and `subscribe` handler need fixing in this new branch.

---

## Required Frontend Fix

### Option 1: Handle by HTTP status code (correct, matches backend)

The backend communicates outcome via HTTP status, not response body.

**`traffic-sign-owner.service.ts`**: Change return type to `Observable<void>`:
```ts
export class TrafficSignOwnerService {
  changeOwner(trafficSignId: string, request: OwnerChangeRequest): Observable<void> {
    return this.#http.post<void>(
      `${environment.apiBaseUrl}/traffic-signs/${trafficSignId}/owner`,
      request,
    );
  }
}
```
Remove `OwnerChangeResponse` interface entirely.

**`change-owner-modal.component.ts`**: Handle 403 separately in error callback:
```ts
import { HttpErrorResponse } from '@angular/common/http';

// In confirm():
.subscribe({
  next: () => {
    this.#toastService.open('Eigenaar succesvol gewijzigd.');
    this.#modalService.close();
  },
  error: (error: HttpErrorResponse) => {
    if (error.status === 403) {
      this.#toastService.open('Bevinding aangemaakt - De eigenaarschapswijziging wacht op goedkeuring.');
      this.#modalService.close(); // Close modal — finding was created successfully
    } else {
      this.#toastService.open('Er is een fout opgetreden bij het wijzigen van de eigenaar. Probeer het later opnieuw.');
    }
  },
});
```

> **Important**: On 403, the modal should also close because the finding WAS created — it's a "success with pending approval" state, not a true error. Add `this.#modalService.close()` in the 403 branch.

### Notes on `roleInfoMessage`

The computed `roleInfoMessage` in the modal (line ~78) already correctly says:
- Admin: "U kunt eigenaarschap toewijzen aan alle wegbeheerders."
- Global mutation: "...Er wordt een bevinding aangemaakt."
- Limited: "...Er wordt een bevinding aangemaakt."

This text is shown BEFORE submit and is correct — no changes needed there.

---

## Dependencies / Blockers

- **Backend branch `feature/110156_create_finding_for_transfer_ownership` must be merged and deployed to staging first** before this frontend fix can be tested end-to-end
- Once deployed: 202 = direct change, 403 = finding created (pending)
- The backend PR is ready according to developer — check Azure DevOps for merge status

---

## Testing Plan

1. As **admin** user: open change-owner modal, select a road authority, confirm
   - Expected: 202 → "Eigenaar succesvol gewijzigd." toast, modal closes
2. As **non-admin without global mutation**: open change-owner modal, select a road authority, confirm
   - Expected: 403 → "Bevinding aangemaakt - De eigenaarschapswijziging wacht op goedkeuring." toast, modal closes
3. Submit with **invalid road authority**: (shouldn't be possible via UI but as sanity check)
   - Expected: other error code → generic error toast, modal stays open
