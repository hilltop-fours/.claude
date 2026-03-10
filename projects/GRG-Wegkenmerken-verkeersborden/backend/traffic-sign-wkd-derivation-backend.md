# Traffic Sign WKD Derivation Backend - API Reference

Complete reference for the traffic-sign-wkd-derivation-backend API. This service manages speed limit mutation proposals for road sections, deriving vehicle access restriction data (WKD - Wegverkeerswet) from network data and traffic sign information.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | 0a05a4d | 2026-03-10 |
| Commit Message | Feature #110189 JDK25 compatibility (no API changes) | |
| Swagger Version | latest | 2026-03-10 |

**Status**: ✓ Up to date as of 2026-03-10
**Next Review**: Check commits after 0a05a4d

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required | Purpose |
|---------|----------------|--------------|---------------|----|
| **Speed Mutation Proposals** | `/speeds/road-section/{roadSectionId}` | GET, POST | NDW IAM | Get or create speed limit mutation proposals for a road section |
| **Delete Proposals** | `/speeds/{id}` | DELETE | NDW IAM | Remove a speed mutation proposal |

---

## DETAILED ENDPOINTS

### Speed Mutation Proposals

#### GET /speeds/road-section/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Retrieve an existing speed limit mutation proposal for a specific road section.

**Path Parameters**:
- `{roadSectionId}` (integer) - NWB road section identifier

**Response** (HTTP 200): SpeedMutationProposalDto

**Example Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "nwbVersion": "2026-01-01",
  "roadSectionId": 12345,
  "segments": [
    {
      "from": 0,
      "to": 500,
      "direction": "BOTH",
      "speedLimit": "KM_50"
    },
    {
      "from": 500,
      "to": 1000,
      "direction": "FORTH",
      "speedLimit": "KM_60"
    },
    {
      "from": 500,
      "to": 1000,
      "direction": "BACK",
      "speedLimit": "KM_50"
    }
  ]
}
```

**Possible Status Codes**:
- 200 OK - Proposal retrieved
- 404 Not Found - No proposal exists for this road section

**Notes**:
- Returns existing proposal if one has been created
- Returns null if no proposal exists for the road section
- Use POST endpoint to create if it doesn't exist

---

#### POST /speeds/road-section/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Get or create a speed limit mutation proposal for a specific road section. If a proposal already exists, returns the existing one. If not, creates a new proposal based on current NWB data and traffic sign information.

**Path Parameters**:
- `{roadSectionId}` (integer) - NWB road section identifier

**Request Body**: None (empty POST)

**Response** (HTTP 200): SpeedMutationProposalDto

**Example Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "nwbVersion": "2026-01-01",
  "roadSectionId": 12345,
  "segments": [
    {
      "from": 0,
      "to": 1000,
      "direction": "BOTH",
      "speedLimit": "KM_50"
    }
  ]
}
```

**Possible Status Codes**:
- 200 OK - Proposal created or retrieved
- 400 Bad Request - Invalid road section ID
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Creates new proposal if none exists for the road section
- Derives speed limits from current NWB version and traffic signs
- Returns immediately; proposal generation may continue in background
- Idempotent operation - calling multiple times returns same result

---

#### DELETE /speeds/{id}

**Authentication**: NDW IAM

**Description**: Delete a speed limit mutation proposal.

**Path Parameters**:
- `{id}` (UUID) - Speed mutation proposal identifier

**Response** (HTTP 200): OK (no response body)

**Possible Status Codes**:
- 200 OK - Proposal deleted successfully
- 404 Not Found - Proposal not found
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Removes the proposal and all associated segments
- Cannot be undone without recreating via POST
- Use cautiously

---

## DATA TYPES (DTOs)

### SpeedMutationProposalDto

**Used in**: GET/POST `/speeds/road-section/{roadSectionId}` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique proposal identifier |
| `nwbVersion` | Date | Yes | YYYY-MM-DD format | NWB (national road network) version used for derivation |
| `roadSectionId` | Integer | Yes | Positive integer | NWB road section identifier |
| `segments` | Array[SpeedMutationProposalSegmentDto] | Yes | At least 1 segment | Speed limit segments for the road section |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "nwbVersion": "2026-01-01",
  "roadSectionId": 12345,
  "segments": [
    {
      "from": 0,
      "to": 500,
      "direction": "BOTH",
      "speedLimit": "KM_50"
    }
  ]
}
```

---

### SpeedMutationProposalSegmentDto

**Used in**: SpeedMutationProposalDto segments array

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `from` | Integer | Yes | Non-negative | Start position in meters along road section |
| `to` | Integer | Yes | Greater than `from` | End position in meters along road section |
| `direction` | Enum | Yes | BOTH, FORTH, BACK | Traffic direction(s) this speed limit applies to |
| `speedLimit` | Enum | Yes | See enum below | Speed limit value for this segment |

**Example**:
```json
{
  "from": 0,
  "to": 500,
  "direction": "BOTH",
  "speedLimit": "KM_50"
}
```

**Validation Notes**:
- `from` must be >= 0
- `to` must be > `from`
- Segments should not overlap for same direction
- Multiple segments can exist for different directions in same position range

---

## ENUMS

### SpeedDirection

**Used in**: SpeedMutationProposalSegmentDto

| Value | Description |
|-------|-------------|
| BOTH | Speed limit applies in both directions |
| FORTH | Speed limit applies in forward direction only |
| BACK | Speed limit applies in backward direction only |

**Notes**:
- FORTH and BACK are used for roads with divided directions
- BOTH is most common for bidirectional roads
- A position range can have different limits for FORTH and BACK

---

### SpeedLimit

**Used in**: SpeedMutationProposalSegmentDto

| Value | Description |
|-------|-------------|
| KM_5 | 5 km/h speed limit |
| KM_15 | 15 km/h speed limit |
| KM_20 | 20 km/h speed limit |
| KM_30 | 30 km/h speed limit (urban areas) |
| KM_40 | 40 km/h speed limit |
| KM_50 | 50 km/h speed limit (common urban/suburban) |
| KM_60 | 60 km/h speed limit |
| KM_70 | 70 km/h speed limit |
| KM_80 | 80 km/h speed limit |
| KM_90 | 90 km/h speed limit |
| KM_100 | 100 km/h speed limit (highway) |
| KM_120 | 120 km/h speed limit (highway) |
| KM_130 | 130 km/h speed limit (highway) |
| NOT_OPEN_FOR_MOTOR_TRAFFIC | Road is closed to motor vehicles |
| NOT_APPLICABLE | Speed limit not applicable (e.g., pedestrian area) |
| UNKNOWN | Speed limit could not be determined |

**Notes**:
- KM_5 through KM_50 most common in urban/suburban areas
- KM_80 through KM_130 for rural and highway sections
- NOT_OPEN_FOR_MOTOR_TRAFFIC indicates cycling/pedestrian only roads
- UNKNOWN indicates derivation uncertainty - may need manual review

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api/wkd-derivation`
**Security Scheme**: OAuth2 (NDW IAM)

### Required Authentication

| Feature | Required | Scope |
|---------|----------|-------|
| Get mutation proposals | NDW IAM | Read access |
| Create mutation proposals | NDW IAM | Write access |
| Delete mutation proposals | NDW IAM | Admin access |

### Authentication Details

- **Provider**: NDW IAM (Keycloak)
- **Authorization URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/auth`
- **Token URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`
- **Refresh URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`

> **Note**: All endpoints require valid NDW IAM authentication.

---

## WKD DERIVATION PROCESS

### What is WKD Derivation?

WKD Derivation is the automatic process of deriving vehicle access restrictions (Wegverkeerswet - vehicle traffic law restrictions) from:
1. **NWB Data**: National road network baseline data
2. **Traffic Signs**: Physical traffic signs on the road
3. **Regulatory Data**: Legal traffic order information

### Speed Limit Derivation

This backend specifically handles **speed limit derivation**:

1. **Input Sources**:
   - NWB road section geometry and attributes
   - Traffic sign inventory (C2 speed limit signs)
   - Current traffic orders and regulations

2. **Derivation Process**:
   - Analyzes traffic signs along the road section
   - Extracts speed limit information
   - Segments the road by speed changes
   - Accounts for directional variations

3. **Output**:
   - SpeedMutationProposal with segments
   - Each segment specifies: position, direction, speed limit
   - Used by frontend for visualization and editing

### Mutation Proposals

A "mutation proposal" represents a suggested set of speed limit rules for a road section:
- Can be reviewed before applying
- Can be modified segment-by-segment
- Can be accepted or rejected
- Provides audit trail of changes

---

## TYPICAL WORKFLOWS

### Creating a Speed Proposal

1. **Request Creation**:
   ```
   POST /speeds/road-section/12345
   ```

2. **Service Process**:
   - Analyzes road section 12345
   - Queries traffic signs on this section
   - Derives speed limits
   - Creates segments for different speeds/directions

3. **Response**:
   ```json
   {
     "id": "uuid-xxx",
     "roadSectionId": 12345,
     "segments": [...]
   }
   ```

### Reviewing Results

Frontend can:
- Display the proposed segments on a map
- Show current vs. proposed speed limits
- Allow user to edit segments
- Apply changes back to system

### Deleting Outdated Proposals

When a proposal is no longer valid:
```
DELETE /speeds/550e8400-e29b-41d4-a716-446655440000
```

---

## INTEGRATION WITH OTHER SERVICES

### Traffic Sign Backend

- **Uses**: Traffic sign data to extract speed limits
- **Purpose**: Speed limit signs (C2) are primary input for derivation
- **Integration**: Queries traffic-sign-backend for signs on a road section

### Traffic Sign WKD Backend

- **Related Service**: traffic-sign-wkd-backend handles vehicle access restrictions
- **Difference**: WKD backend handles width, load, height, axle-load; this handles speed
- **Coordination**: Both derive restrictions, this is speed-specific

### Area Backend

- **Uses**: Road network data (NWB) from area backend
- **Purpose**: Gets road section geometry and network topology
- **Data**: NWB version information for consistency

---

## COMMON USE CASES

### New Road Section

When a new road section is added:
1. Create initial speed proposal via POST
2. Review derived segments
3. Manually adjust if needed
4. Accept and apply

### Speed Limit Change

When traffic regulations change:
1. System generates new proposal
2. Compare with previous version
3. Identify and review differences
4. Apply changes

### Data Quality Assurance

Periodic validation workflow:
1. Generate proposals for all road sections
2. Compare with current data
3. Identify inconsistencies
4. Queue for manual review

---

## NOTES

- **NWB Version**: Proposals are tied to a specific NWB version for auditability
- **Segment Accuracy**: Segment boundaries derive from traffic sign positions
- **Direction Handling**: Dutch roads often have separate speed limits by direction
- **Derivation Confidence**: UNKNOWN speed limit indicates uncertain derivation

---
