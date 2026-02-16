# Traffic Sign Backend - API Reference

Complete reference for the traffic-sign-backend API. This is the core backend service handling traffic sign management, organizations, users, findings, and related operations.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | d2055bf3 | 2026-02-12 |
| Commit Message | feat(findings): #109233 Add get by ID endpoint for findings | |
| Swagger Version | latest | 2026-02-12 |

**Status**: ✓ Up to date as of 2026-02-12
**Next Review**: Check commits after d2055bf3

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required |
|---------|----------------|--------------|---------------|
| **Traffic Signs (CRUD)** | `/traffic-signs`, `/traffic-signs/{id}` | GET, POST, PUT, PATCH | Writer role |
| **Traffic Sign History** | `/traffic-signs/{id}/history` | GET | None |
| **Traffic Sign Images** | `/images`, `/images/{id}` | GET, POST | Reader/Writer role |
| **Organizations** | `/organizations`, `/organizations/{id}` | GET, POST, PUT, DELETE | Admin role |
| **Users** | `/users`, `/users/{id}` | GET, POST, PUT, DELETE | Admin role |
| **Findings/Issues** | `/findings`, `/findings/{id}` | GET, POST, PUT, DELETE | Finding writer role |
| **Black Codes** | `/black-codes`, `/black-codes/uploads` | POST, GET | Writer role |
| **Opening Hours** | `/opening-hours/check-valid` | POST | None |
| **Road Authorities** | `/road-authorities`, `/road-authorities/search` | GET | None |
| **Info Messages** | `/info-messages` | GET, POST, PUT, DELETE | Admin role |
| **GraphQL** | `/graphql` | POST | Reader role |

---

## DETAILED ENDPOINTS

### Traffic Sign Operations

#### GET /traffic-signs

**Authentication**: None (public endpoint)

**Description**: Retrieve traffic signs with pagination and filtering.

**Query Parameters**:
- `criteria` (TrafficSignCriteria, required) - Filter criteria
- `pageable` (Pageable, required) - Pagination (page, size, sort)

**Response** (HTTP 200): Page<TrafficSignResponseDto>

**Example Response**:
```json
{
  "content": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "rvvCode": "C22",
      "status": "PLACED",
      "validated": true,
      "location": {
        "road": {
          "name": "A12",
          "type": "A",
          "number": 12,
          "roadSectionId": 12345
        }
      }
    }
  ],
  "totalPages": 10,
  "totalElements": 250,
  "size": 25,
  "number": 0
}
```

**Notes**:
- Returns paginated results
- Filtering by RVV code, status, validated flag, etc.
- Public read endpoint

---

#### GET /traffic-signs/{id}

**Authentication**: None (public endpoint)

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Response** (HTTP 200): TrafficSignResponseDto

**Example Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "rvvCode": "C22",
  "blackCode": "ABC123",
  "status": "PLACED",
  "validated": true,
  "validatedOn": "2026-01-15T10:30:00Z",
  "location": {
    "wgs84Location": {
      "coordinates": [52.0704, 5.1204]
    },
    "placement": "ALONGSIDE",
    "side": "RIGHT",
    "road": {
      "name": "A12",
      "type": "A",
      "number": 12,
      "roadSectionId": 12345
    }
  },
  "details": {
    "placedOn": "2026-01-10T00:00:00Z",
    "expectedRemovedOn": "2026-12-31T00:00:00Z"
  }
}
```

---

#### POST /traffic-signs

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Description**: Create a new traffic sign.

**Request Body**: TrafficSignRequestDto (JSON or multipart file upload)

**Example Request**:
```json
{
  "rvvCode": "C22",
  "blackCode": "ABC123",
  "status": "PLACED",
  "validated": true,
  "location": {
    "wgs84Location": {
      "coordinates": [52.0704, 5.1204]
    },
    "placement": "ALONGSIDE",
    "side": "RIGHT",
    "road": {
      "name": "A12",
      "type": "A",
      "number": 12,
      "roadSectionId": 12345
    }
  },
  "details": {
    "placedOn": "2026-01-10"
  }
}
```

**Response** (HTTP 200): TrafficSignRequestDto

**Possible Status Codes**:
- 200 OK - Sign created
- 400 Bad Request - Invalid data
- 401 Unauthorized - Missing auth
- 409 Conflict - Duplicate sign

**Notes**:
- Can upload JSON or multipart (CSV/GeoJSON)
- Optional Content-Crs header for coordinate system

---

#### PUT /traffic-signs/{id}

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Request Body**: TrafficSignRequestDto

**Response** (HTTP 200): TrafficSignRequestDto

**Notes**:
- Full update (replaces entire record)
- Use PATCH for partial updates

---

#### PATCH /traffic-signs/{id}

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Request Body**: Array of PatchOperationDto (JSON Patch format)

**Example Request**:
```json
[
  {
    "op": "replace",
    "path": "/status",
    "value": "REMOVED"
  },
  {
    "op": "replace",
    "path": "/validated",
    "value": true
  }
]
```

**Response** (HTTP 204): No Content

**Notes**:
- Supports: add, remove, replace, move, copy, test operations
- Max 1 operation per request

---

#### PUT /traffic-signs/{id}/validate

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Query Parameters**:
- `validated` (boolean, required) - Set validated to true/false

**Response** (HTTP 204): No Content

**Example**: `PUT /traffic-signs/550e8400-e29b-41d4-a716-446655440000/validate?validated=true`

---

#### PUT /traffic-signs/{id}/remove

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Request Body** (optional): TrafficSignRemoveDto

**Example Request**:
```json
{
  "removedOn": "2026-01-30"
}
```

**Response** (HTTP 202): Accepted

**Notes**:
- Marks sign as removed
- Asynchronous operation

---

#### GET /traffic-signs/{id}/history

**Authentication**: None

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier

**Query Parameters**:
- `pageable` (Pageable, required) - Pagination

**Response** (HTTP 200): PagedModel<TrafficSignHistoryDto> or Array<TrafficSignHistoryDto>

**Example Response**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "eventId": "event-123",
    "changeType": "CREATED",
    "changedOn": "2026-01-10T10:00:00Z",
    "changedBy": "user-456"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "eventId": "event-124",
    "changeType": "UPDATED",
    "changedOn": "2026-01-15T14:30:00Z",
    "changedBy": "user-789"
  }
]
```

**Notes**:
- Returns all changes made to this traffic sign
- Includes who made changes and when

---

#### GET /traffic-signs/{id}/authorize/organization/{organizationId}

**Authentication**: ROLE_TRAFFIC_SIGN_AUTHORIZER

**Path Parameters**:
- `{id}` (UUID) - Traffic sign identifier
- `{organizationId}` (UUID) - Organization identifier

**Response** (HTTP 200): HasAuthorizationResponseDto

**Example Response**:
```json
{
  "authorized": true
}
```

**Notes**:
- Check if organization can edit this traffic sign
- Used for authorization checks

---

#### GET /traffic-signs/map/updates

**Authentication**: None

**Query Parameters**:
- `timestamp` (DateTime, required) - Only return updates after this time

**Response** (HTTP 200): FeatureCollection (GeoJSON)

**Notes**:
- Returns traffic signs as GeoJSON features
- Useful for map updates

---

### Traffic Sign Images

#### GET /images

**Authentication**: ROLE_TRAFFIC_SIGN_IMAGE_READER

**Query Parameters**:
- `url` (String, required) - Search by URL

**Response** (HTTP 200): Array<TrafficSignImageDto>

---

#### POST /images

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Request Body**: Multipart form-data (file: BMP, JPEG, or PNG)

**Response** (HTTP 200): TrafficSignImageDto

---

#### GET /images/{id}

**Authentication**: None

**Path Parameters**:
- `{id}` (UUID) - Image identifier

**Response** (HTTP 200): Streamed image (BMP, JPEG, or PNG)

---

#### GET /images/{id}/metadata

**Authentication**: ROLE_TRAFFIC_SIGN_IMAGE_READER

**Path Parameters**:
- `{id}` (UUID) - Image identifier

**Response** (HTTP 200): TrafficSignImageDto

---

### Organizations

#### GET /organizations

**Authentication**: None

**Response** (HTTP 200): Array<OrganizationDto>

---

#### POST /organizations

**Authentication**: ROLE_ADMIN

**Request Body**: OrganizationDto

**Response** (HTTP 200): OrganizationDto

---

#### GET /organizations/{id}

**Authentication**: None

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): OrganizationDto

---

#### PUT /organizations/{id}

**Authentication**: ROLE_ADMIN

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Request Body**: OrganizationDto

**Response** (HTTP 200): OrganizationDto

---

#### DELETE /organizations/{id}

**Authentication**: ROLE_ADMIN

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): OK

---

#### GET /organizations/{id}/has-authority/{roadSectionId}

**Authentication**: ROLE_ORGANIZATION_READER

**Path Parameters**:
- `{id}` (UUID) - Organization identifier
- `{roadSectionId}` (Integer) - Road section identifier

**Response** (HTTP 200): Boolean

---

#### POST /organizations/{id}/upload

**Authentication**: ROLE_ADMIN or ROLE_USER_MANAGER

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Request Body**: Multipart form-data (file: GeoJSON)

**Response** (HTTP 200): OK

---

### Users

#### GET /users/current

**Authentication**: Required (any user)

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### GET /users/organization/{id}

**Authentication**: ROLE_ADMIN or ROLE_USER_MANAGER

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): Array<KeycloakUserResponseDto>

---

#### GET /users/{id}

**Authentication**: ROLE_TRAFFIC_SIGN_USER_ADMIN_READER or ROLE_ADMIN or ROLE_USER_MANAGER

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Query Parameters**:
- `applicationScope` (boolean, optional) - Filter by application scope

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### POST /users

**Authentication**: ROLE_ADMIN or ROLE_USER_MANAGER

**Request Body**: KeycloakUserRequestDto

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### PUT /users/{id}

**Authentication**: ROLE_ADMIN or ROLE_USER_MANAGER

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Request Body**: KeycloakUserRequestDto

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### DELETE /users/{id}

**Authentication**: ROLE_ADMIN or ROLE_USER_MANAGER

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Response** (HTTP 200): OK

---

#### POST /users/{id}/reset-password

**Authentication**: ROLE_ADMIN or ROLE_USER_MANAGER

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Response** (HTTP 200): OK

---

### Findings (Issues)

#### GET /findings

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER or ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Query Parameters**:
- `criteria` (FindingCriteriaDto, required) - Filter criteria
- `pageable` (Pageable, required) - Pagination

**Response** (HTTP 200): Page<TrafficSignFindingDto>

---

#### POST /findings

**Authentication**: ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Request Body**: TrafficSignFindingDto

**Example Request**:
```json
{
  "trafficSign": {
    "id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "reason": "INVALID_BLACK_CODE",
  "feedbackText": "Code mismatch"
}
```

**Response** (HTTP 200): OK

**Notes**:
- Creates or updates finding if already exists for same traffic sign + reason

---

#### GET /findings/{id}

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER or ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Path Parameters**:
- `{id}` (UUID, required) - Finding identifier

**Response** (HTTP 200): TrafficSignFindingDto

**Example Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "trafficSign": {
    "id": "660e8400-e29b-41d4-a716-446655440001"
  },
  "reason": "NO_COUNTERPART",
  "status": "NEW",
  "feedbackText": "Finding details"
}
```

**Notes**:
- Retrieves a single finding by its unique identifier

---

#### GET /findings/traffic-signs/{trafficSignId}

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER or ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Path Parameters**:
- `{trafficSignId}` (UUID) - Traffic sign identifier

**Response** (HTTP 200): Array<TrafficSignFindingDto>

**Notes**:
- Get all findings for a specific traffic sign

---

#### GET /findings/traffic-signs/{trafficSignId}/reasons/{reason}

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER or ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Path Parameters**:
- `{trafficSignId}` (UUID) - Traffic sign identifier
- `{reason}` (FindingReason, required) - Finding reason enum value

**Response** (HTTP 200): TrafficSignFindingDto

---

#### PUT /findings/{id}/status

**Authentication**: ROLE_ADMIN or ROLE_TRAFFIC_SIGN_WRITER or ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Path Parameters**:
- `{id}` (UUID) - Finding identifier

**Request Body**: TrafficSignFindingDto

**Response** (HTTP 200): TrafficSignFindingDto

**Notes**:
- Update finding status (NEW, SOLVED, DECLINED)

---

#### DELETE /findings/{id}

**Authentication**: ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Path Parameters**:
- `{id}` (UUID) - Finding identifier

**Response** (HTTP 200): OK

---

#### GET /findings/map

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER or ROLE_TRAFFIC_SIGN_FINDING_WRITER

**Query Parameters**:
- `roadAuthority` (String, required) - Filter by road authority

**Response** (HTTP 200): Array<TrafficSignFindingDto> (as map features)

---

### Black Codes

#### POST /black-codes

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Request Body**: Multipart form-data (file: TSV - Tab Separated Values)

**Response** (HTTP 200): FileUploadDto

---

#### GET /black-codes/uploads

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Query Parameters**:
- `criteria` (FileUploadCriteria, required) - Filter criteria
- `pageable` (Pageable, required) - Pagination

**Response** (HTTP 200): Page<FileUploadDto>

---

### Info Messages

#### GET /info-messages

**Authentication**: None

**Response** (HTTP 200): Array<InfoMessageDto>

---

#### GET /info-messages/current

**Authentication**: None

**Response** (HTTP 200): Array<InfoMessageDto> (currently active messages)

---

#### POST /info-messages

**Authentication**: ROLE_ADMIN

**Request Body**: InfoMessageDto

**Response** (HTTP 200): InfoMessageDto

---

#### PUT /info-messages/{id}

**Authentication**: ROLE_ADMIN

**Path Parameters**:
- `{id}` (UUID) - Message identifier

**Request Body**: InfoMessageDto

**Response** (HTTP 200): InfoMessageDto

---

#### DELETE /info-messages/{id}

**Authentication**: ROLE_ADMIN

**Path Parameters**:
- `{id}` (UUID) - Message identifier

**Response** (HTTP 200): OK

---

### Road Authorities

#### GET /road-authorities

**Authentication**: None

**Response** (HTTP 200): Array<RoadAuthorityDto>

---

#### GET /road-authorities/search

**Authentication**: None

**Query Parameters**:
- `type` (RoadAuthorityType, required) - Type: R, P, G, W, T
- `code` (String, required) - Authority code

**Response** (HTTP 200): RoadAuthorityDto

---

### Other Utilities

#### POST /opening-hours/check-valid

**Authentication**: None

**Request Body**: OpeningHoursCheckDto

**Response** (HTTP 200): OpeningHoursResultDto

---

#### GET /connected-roads/{roadId}

**Authentication**: ROLE_TRAFFIC_SIGN_WRITER

**Path Parameters**:
- `{roadId}` (Integer) - Road identifier

**Response** (HTTP 200): Array<RoadSectionDto>

---

#### GET /blobs/{id}

**Authentication**: None

**Path Parameters**:
- `{id}` (UUID) - Blob identifier

**Response** (HTTP 200): Streamed blob file

---

#### GET /usage-statistics

**Authentication**: ROLE_ADMIN

**Query Parameters**:
- `date-start` (Date, optional) - Start date
- `date-end` (Date, optional) - End date
- `organization-id` (Array<UUID>, optional) - Filter by organizations

**Response** (HTTP 200): Array<UsageStatisticsBucketDto> or CSV

---

### GraphQL

#### POST /graphql

**Authentication**: ROLE_READER (or higher)

**Description**: GraphQL query endpoint for traffic sign data. Supports querying traffic signs with filtering by RVV codes, status, and road section IDs. Returns traffic sign details including text signs with ObCode values.

**Request Body**: Standard GraphQL JSON (`query` field with the GraphQL query string)

**Example Query**:
```graphql
{
  findTrafficSigns(rvvCodes: ["C17", "C18"], status: PLACED, roadSectionIds: [1, 2, 3]) {
    ndwId
    rvvCode
    textSigns {
      obCode
    }
  }
}
```

**Response** (HTTP 200): Standard GraphQL response wrapping the queried data.

> **Note**: ObCode enum values use zero-padded single-digit codes (`OB01`–`OB09`) and lowercase directional suffixes (`OB17l`, `OB17r`). See [ObCode](#obcode) enum for the full list.

---

## DATA TYPES (DTOs)

### TrafficSignResponseDto

**Used in**: GET `/traffic-signs`, GET `/traffic-signs/{id}`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes | - | Unique identifier |
| `rvvCode` | String | Yes | 1-12 chars | Traffic sign code (RVV) |
| `blackCode` | String | No | - | Internal black code |
| `status` | TrafficSignStatus (Enum) | Yes | PLANNED, PLACED, REMOVED | Current status |
| `validated` | Boolean | Yes | - | Whether manually validated |
| `validatedOn` | DateTime | No | ISO 8601 | When validated |
| `location` | LocationResponseDto | Yes | nested | Geographic details |
| `details` | TrafficSignDetailsResponseDto | No | nested | Additional metadata |
| `externalIds` | Array<ExternalIdResponseDto> | No | - | External system IDs |
| `textSigns` | Array<TrafficSignTextSignResponseDto> | No | - | Text content on sign |
| `publishedOn` | DateTime | No | ISO 8601 | Publication timestamp |
| `owner` | RoadAuthorityDto | No | nested | Sign owner (road authority) - populated from road section if not explicitly set |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "rvvCode": "C22",
  "status": "PLACED",
  "validated": true,
  "location": {
    "road": {
      "name": "A12",
      "type": "A",
      "number": 12,
      "roadSectionId": 12345
    }
  },
  "owner": {
    "type": "P",
    "code": "UT"
  }
}
```

---

### TrafficSignRequestDto

**Used in**: POST `/traffic-signs`, PUT `/traffic-signs/{id}`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | No | - | Identifier (generated if omitted) |
| `rvvCode` | String | Yes | 1-12 chars | Traffic sign code |
| `blackCode` | String | No | - | Internal black code |
| `status` | TrafficSignStatus (Enum) | Yes | PLANNED, PLACED, REMOVED | Current status |
| `validated` | Boolean | Yes | - | Validation flag |
| `location` | LocationRequestDto | Yes | nested | Location details |
| `details` | TrafficSignDetailsRequestDto | Yes | nested | Sign details |
| `textSigns` | Array<TrafficSignTextSignRequestDto> | No | - | Text on sign |
| `externalIds` | Array<ExternalIdRequestDto> | No | - | External IDs |
| `places` | Integer | No | positive | Number of physical signs |

---

### RoadAuthorityDto

**Used in**: TrafficSignResponseDto (as `owner` field), GET `/road-authorities`, GET `/road-authorities/search`

**Description**: Represents a road authority (wegbeheerder) responsible for managing traffic signs.

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `type` | RoadAuthorityType (Enum) | Yes | R, P, G, W, T | Authority type |
| `code` | String | Yes | - | Authority code (e.g., "344" for Utrecht, "UT" for province Utrecht, "R" for Rijkswaterstaat) |

**Example**:
```json
{
  "type": "G",
  "code": "344"
}
```

**Notes**:
- For traffic signs, `owner` field is automatically populated from the road section authority if not explicitly set
- Empty owner (null) indicates signs on private property or without road section assignment
- Authorization checks use the `owner` field to determine edit permissions

---

### TrafficSignFindingDto

**Used in**: POST/PUT `/findings`, GET `/findings`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique finding ID |
| `trafficSign` | TrafficSignDto | Yes | nested object | Reference to traffic sign |
| `reason` | FindingReason (Enum) | Yes | see enum | Why this finding exists |
| `status` | FindingStatus (Enum) | No | NEW, SOLVED, DECLINED | Current status |
| `nlsId` | UUID | No | - | NLS issue reference |
| `feedbackText` | String | No | max 1000 chars | User feedback |
| `createdAt` | DateTime | Yes (response) | ISO 8601 | Creation time |
| `updatedAt` | DateTime | Yes (response) | ISO 8601 | Last update |

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
  "feedbackText": "Code mismatch detected",
  "createdAt": "2026-01-30T10:30:00Z"
}
```

---

### TrafficSignDto

**Used in**: TrafficSignFindingDto

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Traffic sign identifier |
| `rvvCode` | String | No | RVV code |
| `blackCode` | String | No | Black code |
| `location` | TrafficSignLocationDto | No | Location details |

---

### KeycloakUserResponseDto

**Used in**: GET `/users/{id}`, GET `/users/organization/{id}`, GET `/users/current`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | User identifier |
| `firstName` | String | Yes | User's first name |
| `lastName` | String | Yes | User's last name |
| `email` | String | Yes | Email address |
| `phoneNumber` | String | No | Phone number |
| `organization` | OrganizationDto | No | Associated organization |
| `roleGroups` | Array<String> (Enum) | Yes | User roles |
| `createdOn` | DateTime | Yes | Account creation date |
| `active` | Boolean | Yes | Account status |

---

### KeycloakUserRequestDto

**Used in**: POST `/users`, PUT `/users/{id}`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `firstName` | String | Yes | 1-255 chars | First name |
| `lastName` | String | Yes | 1-255 chars | Last name |
| `email` | String | Yes | valid email | Email address |
| `phoneNumber` | String | No | - | Phone number |
| `organizationId` | UUID | Yes | - | Organization ID |
| `roleGroups` | Array<String> (Enum) | Yes | see enum | User roles |
| `active` | Boolean | Yes | - | Account status |

---

### OrganizationDto

**Used in**: GET `/organizations`, POST `/organizations`, PUT `/organizations/{id}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | No (generated) | Organization ID |
| `name` | String | Yes | Organization name |
| `roadAuthorities` | Array<RoadAuthorityDto> | No | Associated road authorities |
| `hasGlobalMutationPermissions` | Boolean | No | Mutation permissions flag |
| `location` | GeoJSON Feature | No | Geographic location |

---

### InfoMessageDto

**Used in**: GET `/info-messages`, POST `/info-messages`, PUT `/info-messages/{id}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | No (generated) | Message ID |
| `message` | String | Yes | Message content |
| `startDate` | DateTime | No | Start date/time |
| `endDate` | DateTime | No | End date/time |

---

### FileUploadDto

**Used in**: POST `/black-codes`, POST `/traffic-signs` (upload)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Upload ID |
| `organizationId` | UUID | No | Organization that uploaded |
| `status` | FileUploadStatus (Enum) | Yes | STARTED, COMPLETED, FAILED |
| `startedOn` | DateTime | Yes | Start time |
| `endedOn` | DateTime | No | End time |
| `dataBlob` | BlobFileDto | No | Data file reference |
| `reportBlob` | BlobFileDto | No | Report file reference |

---

## ENUMS

### TrafficSignStatus

**Used in**: TrafficSignResponseDto, TrafficSignRequestDto

| Value | Description |
|-------|-------------|
| PLANNED | Sign is planned but not yet placed |
| PLACED | Sign is physically placed |
| REMOVED | Sign has been removed |

---

### FindingReason

**Used in**: TrafficSignFindingDto, GET `/findings`

| Value | Description |
|-------|-------------|
| INVALID_BLACK_CODE | Traffic sign has incorrect black code |
| FEEDBACK | User submitted feedback about this sign |
| NO_COUNTERPART | No matching record in NLS |
| NO_DIRECTION | Missing driving direction |
| NO_ROAD_SECTION | Road section not found |
| UNKNOWN_TRAFFIC_ORDER | Traffic order reference missing |
| WKD_INCONSISTENCY_AXLE_LOAD | Axle load restriction mismatch |
| WKD_INCONSISTENCY_HEIGHT | Height restriction mismatch |
| WKD_INCONSISTENCY_LENGTH | Length restriction mismatch |
| WKD_INCONSISTENCY_LOAD | Load restriction mismatch |
| WKD_INCONSISTENCY_SPEED | Speed limit mismatch |
| WKD_INCONSISTENCY_WIDTH | Width restriction mismatch |

---

### FindingStatus

**Used in**: TrafficSignFindingDto

| Value | Description |
|-------|-------------|
| NEW | Finding is newly created |
| SOLVED | Issue has been resolved |
| DECLINED | Issue was reviewed and declined |

---

### RoadAuthorityType

**Used in**: RoadAuthorityDto, search endpoints

| Value | Description |
|-------|-------------|
| R | National roads (Rijkswaterstaat) |
| P | Provincial roads |
| G | Municipal roads |
| W | Water authority |
| T | Traffic company |

---

### FileUploadStatus

**Used in**: FileUploadDto

| Value | Description |
|-------|-------------|
| STARTED | Upload started |
| COMPLETED | Upload completed successfully |
| FAILED | Upload failed |

---

### ObCode

**Used in**: GraphQL `textSigns.obCode` field

Text sign object codes exposed via the GraphQL API. Single-digit OB codes are zero-padded (`OB01`–`OB09`). Directional variants use a lowercase suffix (`l` = left, `r` = right).

> **Changed in commit `a7b27c0e`**: Single-digit codes renamed from `OB1`–`OB9` to `OB01`–`OB09`. Directional suffixes changed from uppercase (`OB17L`) to lowercase (`OB17l`).

| Value | Description |
|-------|-------------|
| C22A1–C22A9 | C22 sub-type codes |
| C22C1 | C22 C-variant code |
| OB01–OB09 | Object codes 1–9 (zero-padded) |
| OB10–OB16 | Object codes 10–16 |
| OB17l, OB17r | Object code 17, left / right |
| OB18l, OB18r | Object code 18, left / right |
| OB19 | Object code 19 |
| OB51–OB66 | Object codes 51–66 |
| OB101–OB115 | Object codes 101–115 |
| OB254, OB256, OB259 | Object codes 254, 256, 259 |
| OB301–OB311, OB313, OB320 | Object codes 301–320 (subset) |
| OB401, OB411 | Object codes 401, 411 |
| OB501l, OB501r | Object code 501, left / right |
| OB502–OB505 | Object codes 502–505 |
| OB617–OB621, OB627 | Object codes 617–627 (subset) |
| OB711 | Object code 711 |
| OB711l, OB711r | Object code 711, left / right |
| OB712 | Object code 712 |
| OB712l, OB712r | Object code 712, left / right |
| OB713 | Object code 713 |
| OB713l, OB713r | Object code 713, left / right |
| OB719, OB720 | Object codes 719, 720 |
| OTHER | Any other object code |

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api`

**Security Scheme**: OAuth2 / Bearer Token (Keycloak)

### Required Roles by Feature

| Feature | Required Roles | Description |
|---------|----------------|-------------|
| Read Traffic Signs | None | Public endpoint |
| Create Traffic Sign | ROLE_TRAFFIC_SIGN_WRITER | Write permission |
| Update Traffic Sign | ROLE_TRAFFIC_SIGN_WRITER | Write permission |
| Delete Traffic Sign | ROLE_TRAFFIC_SIGN_WRITER | Write permission |
| Upload Images | ROLE_TRAFFIC_SIGN_WRITER | Image write permission |
| Read Images | ROLE_TRAFFIC_SIGN_IMAGE_READER | Image read permission |
| Manage Organizations | ROLE_ADMIN | Admin only |
| Manage Users | ROLE_ADMIN or ROLE_USER_MANAGER | Admin/User manager |
| Create Findings | ROLE_TRAFFIC_SIGN_FINDING_WRITER | Finding write permission |
| Update Findings | ROLE_TRAFFIC_SIGN_FINDING_WRITER or ROLE_ADMIN | Write permission |
| Upload Black Codes | ROLE_TRAFFIC_SIGN_WRITER | Writer role |
| Admin Messages | ROLE_ADMIN | Admin only |
| Check Authorization | ROLE_TRAFFIC_SIGN_AUTHORIZER | Authorization check |

### Role Definitions

| Role | Scope | Endpoints |
|------|-------|-----------|
| ROLE_TRAFFIC_SIGN_WRITER | Full CRUD on traffic signs, images, black codes | POST, PUT, PATCH, DELETE /traffic-signs, /images, /black-codes |
| ROLE_TRAFFIC_SIGN_IMAGE_READER | Read traffic sign images | GET /images |
| ROLE_TRAFFIC_SIGN_FINDING_WRITER | Create/manage findings | POST, PUT, DELETE /findings |
| ROLE_TRAFFIC_SIGN_AUTHORIZER | Check authorization | GET /traffic-signs/{id}/authorize |
| ROLE_ADMIN | Full system access | All endpoints |
| ROLE_USER_MANAGER | Manage users | POST, PUT, DELETE /users |
| ROLE_ORGANIZATION_READER | Read organizations | GET /organizations |
| ROLE_NWB_UPDATER | Update NWB data | PUT /traffic-signs/{id}/road-section |

---

## COMMON PATTERNS

### Pagination

Most list endpoints use Spring Data pagination:

```json
{
  "page": 0,
  "size": 25,
  "sort": ["name,asc"]
}
```

Response includes:
- `content`: Array of items
- `totalPages`: Total number of pages
- `totalElements`: Total item count
- `size`: Items per page
- `number`: Current page number
- `first`: Is this the first page
- `last`: Is this the last page

### Error Responses

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Invalid traffic sign data",
  "timestamp": "2026-01-30T10:30:00Z"
}
```

### File Upload

For file uploads, use multipart/form-data with `file` field. Supported formats vary by endpoint:
- Traffic signs: CSV, GeoJSON
- Images: BMP, JPEG, PNG
- Black codes: TSV (Tab Separated Values)

---

## NOTES

> **Important**: The `trafficSign` field in TrafficSignFindingDto is a nested object. Access the traffic sign ID via `trafficSign.id`, not directly from the finding. This changed in version 1.7.0 of the traffic-sign-client library.

> **Note**: All timestamps are in ISO 8601 format with UTC timezone (Z suffix)

> **Deprecation**: GET `/blobs/pdf/{id}` is deprecated since 2026-04-16. Use `/blobs/{id}` instead.
