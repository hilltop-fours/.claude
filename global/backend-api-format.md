# BACKEND API DOCUMENTATION FORMAT

This document defines the standard format for documenting backend APIs in the `.claude/projects/backend/` folder. This format is optimized for quick scanning, easy maintenance, and serving as a reference for frontend development.

---

## General Structure

Each backend API document should follow this hierarchy:

```
# [Backend Name] - API Reference

## COMMIT TRACKING
[Table tracking last verified commit and Swagger version]

## QUICK REFERENCE
[Table: Feature → Endpoints mapping]

## DETAILED ENDPOINTS
### [Module/Feature Name]
#### [HTTP Method] [Path]
[Endpoint details]

## DATA TYPES (DTOs)
### [DTO Name]
[Fields, types, and constraints]

## ENUMS
### [Enum Name]
[List of values]

## AUTHENTICATION & AUTHORIZATION
[Roles and security requirements]
```

---

## Detailed Format Specifications

### 1. COMMIT TRACKING SECTION

Purpose: Track which Swagger version and commits have been reviewed.

```markdown
## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | [commit-hash] | [YYYY-MM-DD] |
| Commit Message | [message summary] | |
| Swagger Version | latest | [YYYY-MM-DD] |

**Status**: ✓ Up to date as of [date]
**Next Review**: Check commits after [commit-hash]
```

---

### 2. QUICK REFERENCE SECTION

Purpose: Enable rapid feature-to-endpoint lookup without reading the whole document.

```markdown
## QUICK REFERENCE BY FEATURE

| Feature | Endpoints | HTTP Methods | Auth Required |
|---------|-----------|--------------|---------------|
| **Traffic Signs (CRUD)** | `/traffic-signs`, `/traffic-signs/{id}` | GET, POST, PUT, PATCH | ROLE_TRAFFIC_SIGN_WRITER |
| **Organizations** | `/organizations`, `/organizations/{id}` | GET, POST, PUT, DELETE | ROLE_ADMIN |
| **Users** | `/users`, `/users/{id}` | GET, POST, PUT, DELETE | ROLE_ADMIN |
| **Findings** | `/findings`, `/findings/{id}` | GET, POST, PUT, DELETE | ROLE_TRAFFIC_SIGN_FINDING_WRITER |
```

---

### 3. DETAILED ENDPOINTS SECTION

Purpose: Document each endpoint with full details for implementation.

#### Format for Each Endpoint:

```markdown
#### [HTTP_METHOD] [Path]

**Authentication**: [Role required or "None"]

**Path Parameters**:
- `{paramName}` (type, constraints) - Description

**Query Parameters**:
- `paramName` (type, optional/required) - Description

**Request Body**: [DTO Name]
```json
{
  "field1": "type",
  "field2": "type"
}
```

**Response** (HTTP 200):
```json
{
  "id": "uuid",
  "field1": "type"
}
```

**Possible Status Codes**:
- 200 OK
- 400 Bad Request
- 401 Unauthorized
- 404 Not Found
- 409 Conflict

**Notes**: Any additional context or constraints
```

#### Real Example:

```markdown
#### GET /traffic-signs/{id}

**Authentication**: None (public endpoint)

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Response** (HTTP 200):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "rvvCode": "C22",
  "status": "PLACED",
  "location": {
    "road": {
      "name": "A12",
      "type": "A",
      "number": 12,
      "roadSectionId": 12345
    }
  }
}
```

**Notes**:
- Returns full traffic sign details including location and metadata
- No authentication required for read operations
```

---

### 4. DATA TYPES (DTOs) SECTION

Purpose: Document all data structures used in requests/responses.

#### Format:

```markdown
### [DTOName]

**Used in**: [List endpoints that use this DTO]

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes | - | Unique identifier |
| `rvvCode` | String | Yes | length: 1-12 | Traffic sign code |
| `status` | Enum | Yes | PLANNED, PLACED, REMOVED | Current status |
| `location` | LocationDto | Yes | nested object | Geographic location |
| `validated` | Boolean | No | - | Whether validated |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "rvvCode": "C22",
  "status": "PLACED",
  "validated": true
}
```
```

#### Real Example:

```markdown
### TrafficSignFindingDto

**Used in**: POST/PUT `/findings`, GET `/findings/{id}`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique finding identifier |
| `trafficSign` | TrafficSignDto | Yes | nested object | Reference to traffic sign |
| `reason` | FindingReason (Enum) | Yes | see enum below | Why this finding exists |
| `status` | FindingStatus (Enum) | No | NEW, SOLVED, DECLINED | Current status |
| `nlsId` | UUID | No | - | NLS issue reference |
| `feedbackText` | String | No | max 1000 chars | User-provided feedback |
| `createdAt` | DateTime | Yes (response) | ISO 8601 | Creation timestamp |
| `updatedAt` | DateTime | Yes (response) | ISO 8601 | Last update timestamp |

**Example**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "trafficSign": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "rvvCode": "C22"
  },
  "reason": "INVALID_BLACK_CODE",
  "status": "NEW",
  "feedbackText": "Black code doesn't match RVV code",
  "createdAt": "2026-01-30T10:30:00Z"
}
```
```

---

### 5. ENUMS SECTION

Purpose: List all enum values used throughout the API.

#### Format:

```markdown
### [EnumName]

**Used in**: [List of DTOs/endpoints]

| Value | Description |
|-------|-------------|
| VALUE_1 | Description of this value |
| VALUE_2 | Description of this value |
```

#### Real Example:

```markdown
### FindingReason

**Used in**: TrafficSignFindingDto, GET `/findings`

| Value | Description |
|-------|-------------|
| INVALID_BLACK_CODE | Traffic sign has incorrect black code |
| FEEDBACK | User submitted feedback about this sign |
| NO_COUNTERPART | NLS has no matching record |
| NO_DIRECTION | Missing driving direction |
| NO_ROAD_SECTION | Road section not found |
| UNKNOWN_TRAFFIC_ORDER | Traffic order reference missing |
| WKD_INCONSISTENCY_AXLE_LOAD | Axle load restriction mismatch |
| WKD_INCONSISTENCY_HEIGHT | Height restriction mismatch |
| WKD_INCONSISTENCY_LENGTH | Length restriction mismatch |
| WKD_INCONSISTENCY_LOAD | Load restriction mismatch |
| WKD_INCONSISTENCY_SPEED | Speed limit mismatch |
| WKD_INCONSISTENCY_WIDTH | Width restriction mismatch |
```

---

### 6. AUTHENTICATION & AUTHORIZATION SECTION

Purpose: Document security requirements and role-based access.

#### Format:

```markdown
## AUTHENTICATION & AUTHORIZATION

**Base URL**: [URL]
**Security Scheme**: [OAuth2, Bearer Token, API Key, etc.]

### Required Roles by Feature

| Feature | Required Roles | Description |
|---------|----------------|-------------|
| Read Traffic Signs | None | Public endpoint |
| Create Traffic Sign | ROLE_TRAFFIC_SIGN_WRITER | Write permission needed |
| Manage Users | ROLE_ADMIN | Admin only |
| Submit Feedback | ROLE_USER | Any authenticated user |

### Role Definitions

| Role | Access Level | Endpoints |
|------|--------------|-----------|
| ROLE_TRAFFIC_SIGN_WRITER | Full CRUD on traffic signs | POST, PUT, PATCH, DELETE /traffic-signs |
| ROLE_ADMIN | Full system access | All endpoints |
| ROLE_TRAFFIC_SIGN_FINDING_WRITER | Create/manage findings | POST, PUT, DELETE /findings |
```

---

## Style Guidelines

### Code Blocks

Always use proper JSON formatting in examples:
```json
{
  "field": "value",
  "nested": {
    "subfield": "value"
  }
}
```

### Link References

When referencing DTOs within the document:
```markdown
Request Body: [TrafficSignRequestDto](#trafficsignrequestdto)
```

### Notes and Warnings

Use blockquotes for important information:
```markdown
> **Important**: This endpoint requires admin privileges
> **Note**: Responses are paginated by default
> **Deprecation**: Use `/v2/endpoint` instead
```

---

## Example: Full Endpoint Documentation

```markdown
#### POST /findings

**Authentication**: ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Description**: Create or update a finding (issue) for a traffic sign.

**Request Body**: [TrafficSignFindingDto](#trafficsignfindingdto)

**Response** (HTTP 200): Confirmation

**Example Request**:
```json
{
  "trafficSign": {
    "id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "reason": "INVALID_BLACK_CODE",
  "feedbackText": "Code mismatch detected"
}
```

**Possible Status Codes**:
- 200 OK - Finding created/updated
- 400 Bad Request - Invalid finding data
- 401 Unauthorized - Missing auth token
- 404 Not Found - Traffic sign not found

**Notes**:
- If finding already exists for this traffic sign + reason, it will be updated
- feedbackText is optional but recommended for user-submitted findings
- trafficSign object only requires the ID field
```

---

## File Naming Convention

- `{backend-name}.md` - Main API documentation
  - Example: `traffic-sign-backend.md`

---

## Quick Tips for Readability

1. **Use tables extensively** - Easy to scan
2. **Use hierarchy properly** - H2 for sections, H3 for subsections, H4 for endpoints
3. **Keep endpoint groups small** - Max 15-20 endpoints per section
4. **Always include examples** - Even brief ones help
5. **Use consistent terminology** - Don't call the same thing by different names
6. **Link to DTOs** - Makes navigation easier
7. **Note deprecated endpoints** - Include migration path
