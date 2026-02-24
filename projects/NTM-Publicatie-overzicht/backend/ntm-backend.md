# NTM Backend API - API Reference

Complete reference for the NTM Backend API. This service manages data publications, standards, organizations, users, and roles for the NTM (Publicatie Overzicht) publication management platform. It handles data cataloging, standards management, and publication approval workflows.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | f7d8481 | 2026-02-24 |
| Commit Message | feat(obligations): #108264 Adjust dto for FE | |
| Swagger Version | latest | 2026-02-24 |

**Status**: ✓ Up to date as of 2026-02-24
**Next Review**: Check commits after f7d8481

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required | Purpose |
|---------|----------------|--------------|---------------|---------|
| **Data Publications (CRUD)** | `/data-publications`, `/data-publications/{id}` | GET, POST, PUT, DELETE | Keycloak NTM | Manage publication records |
| **Publication Approval** | `/data-publications/{id}/approve`, `/data-publications/{id}/reject`, `/data-publications/{id}/hold` | POST | Keycloak NTM | Review and approve/reject publications |
| **Publication Search** | `/data-publications`, `/data-publications/mine`, `/data-publications/favorites`, `/data-publications/to-approve` | GET | Keycloak NTM | Query publications with filters |
| **Standards Management** | `/standards`, `/standards/{id}` | GET, POST, PUT, DELETE | Keycloak NTM | Manage data standards |
| **Organizations** | `/organizations`, `/organizations/{id}`, `/organizations/page`, `/organizations/search` | GET, POST, PUT, DELETE | Keycloak NTM | Manage organizations |
| **Users & Roles** | `/users`, `/users/{id}`, `/users/current` | GET, POST, PUT, DELETE | Keycloak NTM | User management and role requests |
| **Role Requests** | `/organizations/{id}/role_requests` | GET, POST, PUT | Keycloak NTM | Request and approve role changes |
| **Organization Permissions** | `/organizations/{id}/permissions`, `/organizations/{id}/logo` | PUT, GET | Keycloak NTM | Set permissions and manage org branding |
| **Obligations** | `/obligations`, `/obligations/{id}` | GET | Keycloak NTM | Retrieve obligations (OVD import from Excel) |
| **Favorites** | `/favorites` | GET, POST, DELETE | Keycloak NTM | Manage favorite publications |
| **Info Messages** | `/info-messages`, `/info-messages/{id}`, `/info-messages/current` | GET, POST, PUT, DELETE | Keycloak NTM | System-wide notifications |

---

## DETAILED ENDPOINTS

### Data Publications - CRUD Operations

#### GET /data-publications

**Authentication**: Keycloak NTM

**Description**: Search and retrieve publications with extensive filtering options.

**Query Parameters**:
- `search` (string, optional) - Full-text search across publication fields
- `name` (string, optional) - Filter by publication name
- `description` (string, optional) - Filter by description
- `organizationName` (string, optional) - Filter by organization name
- `organizationId` (UUID, optional) - Filter by organization UUID
- `ownerUserId` (UUID, optional) - Filter by publication owner
- `themes` (array, optional) - Filter by themes (SHARE_MOBILITY, MAAS, PUBLIC_TRANSPORT, LOGISTIC, TRAFFIC_SAFETY, TRAFFIC_MANAGEMENT, ALTERNATIVE_FUEL, PARKING_HUBS, BIKES)
- `regulationTypes` (array, optional) - Filter by regulation types (TRUCK_PARKING, ROAD_SAFETY, REALTIME, MULTIMODAL, MISC, AFIR, DATA_TOP_15, ENDS, SPVV, ITS)
- `categories` (array, optional) - Filter by data categories (extensive list of traffic/transport categories)
- `networkCoverages` (array, optional) - Filter by network coverage areas
- `transportModes` (array, optional) - Filter by transport modes
- `regionCode` (array, optional) - Filter by region codes
- `termsOfServiceType` (array, optional) - Filter by license type
- `dataFileFormat` (array, optional) - Filter by file format (CSV, JSON, GeoJSON, etc.)
- `standardId` (array, optional) - Filter by standard UUID
- `updateFrequency` (array, optional) - Filter by update frequency
- `reviewStatus` (array, optional) - Filter by status (IMPORTED, PENDING_REVIEW, DEFINITIVE, HELD)
- `pageable` (Pageable, required) - Pagination parameters (page, size, sort)
- `Accept-Language` (header, optional) - Language preference

**Response** (HTTP 200): PagedModelDataPublicationDto

**Example Response**:
```json
{
  "content": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Traffic Safety Data",
      "description": {
        "plain": "Real-time traffic safety information",
        "formatted": {
          "ops": [{"insert": "Real-time traffic safety information"}]
        }
      },
      "themes": ["TRAFFIC_SAFETY"],
      "categories": ["ACCIDENT_DATA"],
      "organization": {"id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "name": "Traffic Authority"},
      "reviewStatus": "DEFINITIVE",
      "favorite": false,
      "createdOn": "2026-01-30T10:30:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 150
}
```

**Possible Status Codes**:
- 200 OK - Publications retrieved
- 400 Bad Request - Invalid filter parameters
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Supports complex filtering with multiple criteria
- Results are paginated
- Empty search returns all accessible publications

---

#### GET /data-publications/mine

**Authentication**: Keycloak NTM

**Description**: Get publications owned by the authenticated user.

**Query Parameters**:
- `pageable` (Pageable, required) - Pagination parameters
- `Accept-Language` (header, optional) - Language preference

**Response** (HTTP 200): PagedModelDataPublicationDto

**Possible Status Codes**:
- 200 OK - User publications retrieved
- 401 Unauthorized - Not authenticated

---

#### GET /data-publications/favorites

**Authentication**: Keycloak NTM

**Description**: Get user's favorite publications.

**Query Parameters**:
- `pageable` (Pageable, required) - Pagination parameters
- `Accept-Language` (header, optional) - Language preference

**Response** (HTTP 200): PagedModelDataPublicationDto

---

#### GET /data-publications/to-approve

**Authentication**: Keycloak NTM

**Description**: Get publications pending review/approval (for reviewers), with optional filtering by review status.

**Query Parameters**:
- `pageable` (Pageable, required) - Pagination parameters
- `reviewStatus` (List<ReviewStatus>, optional) - Filter by review status(es). Accepts multiple values (comma-separated).
  - When omitted: Returns publications with statuses `PENDING_REVIEW`, `IMPORTED`, and `HELD` (default behavior)
  - When specified: Returns only publications matching the provided status(es)
  - Special behavior: When `PENDING_REVIEW` is included, `HELD` status is automatically included as well
  - Valid values: `PENDING_REVIEW`, `IMPORTED`, `HELD`, `APPROVED`, `REJECTED`

**Response** (HTTP 200): PagedModelDataPublicationDto

**Examples**:
- `/data-publications/to-approve?page=0&size=10` - Returns all publications with default statuses (PENDING_REVIEW, IMPORTED, HELD)
- `/data-publications/to-approve?reviewStatus=IMPORTED` - Returns only IMPORTED publications
- `/data-publications/to-approve?reviewStatus=PENDING_REVIEW` - Returns PENDING_REVIEW and HELD publications
- `/data-publications/to-approve?reviewStatus=IMPORTED,PENDING_REVIEW` - Returns IMPORTED, PENDING_REVIEW, and HELD publications

**Notes**:
- Only accessible to users with review/approval permissions (ROLE_ADMIN_READER or higher)

---

#### GET /data-publications/{id}

**Authentication**: Keycloak NTM

**Description**: Retrieve a specific publication with full details.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Query Parameters**:
- `Accept-Language` (header, optional) - Language preference

**Response** (HTTP 200): DataPublicationDto

**Possible Status Codes**:
- 200 OK - Publication found
- 401 Unauthorized - Not authenticated
- 404 Not Found - Publication not found

---

#### POST /data-publications

**Authentication**: Keycloak NTM

**Description**: Create a new data publication.

**Request Body**: DataPublicationDto

**Example Request**:
```json
{
  "name": "Public Transport Schedule",
  "description": {
    "plain": "Current public transport schedules",
    "formatted": {
      "ops": [{"insert": "Current public transport schedules"}]
    }
  },
  "themes": ["PUBLIC_TRANSPORT"],
  "categories": ["TIMETABLES_STATIC"],
  "termsOfService": {
    "type": "LICENSE_ACCORDING_CREATIVE_COMMONS",
    "url": "https://creativecommons.org/licenses/by/4.0/"
  },
  "scope": {
    "regionCodes": ["NL"],
    "transportModes": ["BUS", "TRAM"]
  },
  "dataExchanges": [
    {
      "dataFileFormat": "JSON",
      "standard": {"standardId": "550e8400-e29b-41d4-a716-446655440000"},
      "communicationProtocol": "HTTP_HTTPS",
      "communicationMethod": "PULL",
      "updateFrequency": "DAILY"
    }
  ],
  "organization": {"id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"},
  "contact": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com"
  },
  "contactType": "ORGANIZATION_CONTACT",
  "publicationStatus": "VISIBLE"
}
```

**Response** (HTTP 200): DataPublicationDto

**Possible Status Codes**:
- 200 OK - Publication created
- 400 Bad Request - Invalid publication data
- 401 Unauthorized - Not authenticated

---

#### PUT /data-publications/{id}

**Authentication**: Keycloak NTM

**Description**: Update an existing publication.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Request Body**: DataPublicationDto

**Response** (HTTP 200): DataPublicationDto

**Possible Status Codes**:
- 200 OK - Publication updated
- 400 Bad Request - Invalid data
- 401 Unauthorized - Not authenticated
- 404 Not Found - Publication not found

---

#### DELETE /data-publications/{id}

**Authentication**: Keycloak NTM

**Description**: Delete a publication.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Response** (HTTP 200): OK (no response body)

**Possible Status Codes**:
- 200 OK - Publication deleted
- 401 Unauthorized - Not authenticated
- 404 Not Found - Publication not found

---

### Data Publications - Approval Workflow

#### POST /data-publications/{id}/approve

**Authentication**: Keycloak NTM

**Description**: Approve a publication for publication (PENDING_REVIEW → DEFINITIVE).

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Response** (HTTP 200): OK (no response body)

**Possible Status Codes**:
- 200 OK - Publication approved
- 401 Unauthorized - Insufficient permissions
- 404 Not Found - Publication not found

---

#### POST /data-publications/{id}/reject

**Authentication**: Keycloak NTM

**Description**: Reject a publication with a reason.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Request Body**: RejectPublicationDto

**Example Request**:
```json
{
  "reason": "Missing required metadata fields"
}
```

**Response** (HTTP 200): OK (no response body)

**Possible Status Codes**:
- 200 OK - Publication rejected
- 400 Bad Request - Reason required
- 401 Unauthorized - Insufficient permissions
- 404 Not Found - Publication not found

---

#### POST /data-publications/{id}/hold

**Authentication**: Keycloak NTM

**Description**: Put a publication on hold pending further review.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Request Body**: HoldPublicationDto

**Example Request**:
```json
{
  "reason": "Awaiting organization response"
}
```

**Response** (HTTP 200): DataPublicationDto

---

#### POST /data-publications/{id}/transfer

**Authentication**: Keycloak NTM

**Description**: Transfer publication ownership to another user.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Query Parameters**:
- `newOwnerId` (UUID, required) - New owner's user ID

**Response** (HTTP 200): DataPublicationDto

---

### Data Publications - Favorites & Import

#### POST /data-publications/{id}/favorite

**Authentication**: Keycloak NTM

**Description**: Mark a publication as favorite.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Response** (HTTP 200): OK (no response body)

---

#### DELETE /data-publications/{id}/favorite

**Authentication**: Keycloak NTM

**Description**: Remove publication from favorites.

**Path Parameters**:
- `{id}` (UUID) - Publication identifier

**Response** (HTTP 200): OK (no response body)

---

#### POST /data-publications/import

**Authentication**: Keycloak NTM

**Description**: Import a publication from DCAT dataset format.

**Request Body**: DcatDatasetDto

**Response** (HTTP 200): DcatDatasetDto

---

### Standards Management

#### GET /standards

**Authentication**: Keycloak NTM

**Description**: Retrieve all data standards with filtering.

**Query Parameters**:
- `criteria` (StandardCriteria, required) - Search criteria
- `Accept-Language` (header, optional) - Language preference

**Response** (HTTP 200): Array of StandardDto

---

#### GET /standards/{id}

**Authentication**: Keycloak NTM

**Description**: Get a specific standard.

**Path Parameters**:
- `{id}` (UUID) - Standard identifier

**Response** (HTTP 200): StandardDto

---

#### POST /standards

**Authentication**: Keycloak NTM

**Description**: Create a new data standard.

**Request Body**: StandardDto

**Response** (HTTP 200): StandardDto

---

#### PUT /standards/{id}

**Authentication**: Keycloak NTM

**Description**: Update a standard.

**Path Parameters**:
- `{id}` (UUID) - Standard identifier

**Request Body**: StandardDto

**Response** (HTTP 200): StandardDto

---

#### DELETE /standards/{id}

**Authentication**: Keycloak NTM

**Description**: Delete a standard.

**Path Parameters**:
- `{id}` (UUID) - Standard identifier

**Response** (HTTP 200): OK (no response body)

---

### Organizations

#### GET /organizations

**Authentication**: Keycloak NTM

**Description**: Get all organizations.

**Response** (HTTP 200): Array of OrganizationDto

---

#### GET /organizations/{id}

**Authentication**: Keycloak NTM

**Description**: Get a specific organization.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): OrganizationDto

---

#### GET /organizations/search

**Authentication**: Keycloak NTM

**Description**: Search organizations by name.

**Query Parameters**:
- `name` (string, optional) - Organization name

**Response** (HTTP 200): Array of OrganizationDto

---

#### GET /organizations/page

**Authentication**: Keycloak NTM

**Description**: Get paginated organizations with filtering.

**Query Parameters**:
- `criteria` (OrganizationCriteria, required) - Filter criteria
- `pageable` (Pageable, required) - Pagination parameters

**Response** (HTTP 200): PagedModelOrganizationDto

---

#### POST /organizations

**Authentication**: Keycloak NTM

**Description**: Create a new organization.

**Request Body**: OrganizationDto

**Example Request**:
```json
{
  "name": "Transport Authority",
  "email": "info@transport.gov",
  "phoneNumber": "+31 1234567890",
  "website": "https://transport.gov",
  "address": {
    "street": "Main Street",
    "houseNumber": "100",
    "postalCode": "2511 AA",
    "city": "The Hague",
    "country": "NLD"
  },
  "contact": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@transport.gov"
  },
  "status": "ACTIVE"
}
```

**Response** (HTTP 200): OrganizationDto

---

#### PUT /organizations/{id}

**Authentication**: Keycloak NTM

**Description**: Update an organization.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Request Body**: OrganizationDto

**Response** (HTTP 200): OrganizationDto

---

#### DELETE /organizations/{id}

**Authentication**: Keycloak NTM

**Description**: Delete an organization.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): OK (no response body)

---

#### PUT /organizations/{id}/permissions

**Authentication**: Keycloak NTM

**Description**: Set organization moderation requirements.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Query Parameters**:
- `needsModeration` (boolean, required) - Whether publications need approval

**Response** (HTTP 200): OrganizationDto

---

#### GET /organizations/{id}/logo

**Authentication**: Keycloak NTM

**Description**: Get organization logo image.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): BlobStorageFile (image)

---

#### PUT /organizations/{id}/logo

**Authentication**: Keycloak NTM

**Description**: Upload organization logo.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Request Body**: Multipart form data
- `file` (binary) - Logo image file

**Response** (HTTP 200): OK (no response body)

---

#### PUT /repair/organizations

**Authentication**: Keycloak NTM

**Description**: Repair all organizations (admin maintenance operation).

**Response** (HTTP 200): Array (repair status)

---

#### PUT /repair/organizations/{id}

**Authentication**: Keycloak NTM

**Description**: Repair a specific organization.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Response** (HTTP 200): Object (repair status)

---

### Users & Authentication

#### GET /users

**Authentication**: Keycloak NTM

**Description**: Get all users.

**Query Parameters**:
- `withRoles` (boolean, optional, default=true) - Include user roles

**Response** (HTTP 200): Array of KeycloakUserResponseDto

---

#### GET /users/current

**Authentication**: Keycloak NTM

**Description**: Get current authenticated user details.

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### GET /users/{id}

**Authentication**: Keycloak NTM

**Description**: Get a specific user with roles.

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### POST /users

**Authentication**: Keycloak NTM

**Description**: Create a new user.

**Request Body**: KeycloakUserCreateUpdateRequestDto

**Example Request**:
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane@example.com",
  "phoneNumber": "+31 1234567890",
  "organizationId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "role": "EDITOR"
}
```

**Response** (HTTP 200): KeycloakUserResponseDto

**Possible Status Codes**:
- 200 OK - User created
- 400 Bad Request - Invalid user data
- 401 Unauthorized - Not authenticated

---

#### PUT /users/{id}

**Authentication**: Keycloak NTM

**Description**: Update a user.

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Request Body**: KeycloakUserCreateUpdateRequestDto

**Response** (HTTP 200): KeycloakUserResponseDto

---

#### DELETE /users/{id}

**Authentication**: Keycloak NTM

**Description**: Delete a user.

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Response** (HTTP 200): OK (no response body)

---

#### POST /users/{id}/reset-password

**Authentication**: Keycloak NTM

**Description**: Trigger password reset for a user.

**Path Parameters**:
- `{id}` (UUID) - User identifier

**Response** (HTTP 200): OK (no response body)

---

### Role Management

#### GET /organizations/{id}/role_requests

**Authentication**: Keycloak NTM

**Description**: Get role requests for an organization.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Query Parameters**:
- `includeUsers` (boolean, optional) - Include user details

**Response** (HTTP 200): Array of UserRoleRequestDto

---

#### POST /organizations/{id}/role_requests

**Authentication**: Keycloak NTM

**Description**: Request a role within an organization.

**Path Parameters**:
- `{id}` (UUID) - Organization identifier

**Query Parameters**:
- `role` (string, required) - Requested role (ADMIN, OBSERVER, DATA_ITEM_USER, HEAD_EDITOR, EDITOR, USER)

**Response** (HTTP 200): UserRoleRequestDto

---

#### POST /organizations/{organization_id}/role_requests/{role_request_id}/approve

**Authentication**: Keycloak NTM

**Description**: Approve a role request.

**Path Parameters**:
- `{organization_id}` (UUID) - Organization identifier
- `{role_request_id}` (UUID) - Role request identifier

**Response** (HTTP 200): OK (no response body)

---

#### POST /organizations/{organization_id}/role_requests/{role_request_id}/deny

**Authentication**: Keycloak NTM

**Description**: Deny a role request with reason.

**Path Parameters**:
- `{organization_id}` (UUID) - Organization identifier
- `{role_request_id}` (UUID) - Role request identifier

**Request Body**: RoleRequestDenyReasonDto

**Example Request**:
```json
{
  "reason": "User does not meet requirements"
}
```

**Response** (HTTP 200): OK (no response body)

---

### System Information

#### GET /info-messages

**Authentication**: Keycloak NTM

**Description**: Get all system info messages.

**Response** (HTTP 200): Array of InfoMessageDto

---

#### GET /info-messages/current

**Authentication**: Keycloak NTM

**Description**: Get currently active info messages.

**Response** (HTTP 200): Array of InfoMessageDto

---

#### GET /info-messages/current/count

**Authentication**: Keycloak NTM

**Description**: Get count of current info messages.

**Response** (HTTP 200): InfoMessageCountDto

---

#### POST /info-messages

**Authentication**: Keycloak NTM

**Description**: Create a system info message.

**Request Body**: InfoMessageDto

**Response** (HTTP 200): InfoMessageDto

---

#### PUT /info-messages/{id}

**Authentication**: Keycloak NTM

**Description**: Update an info message.

**Path Parameters**:
- `{id}` (UUID) - Message identifier

**Request Body**: InfoMessageDto

**Response** (HTTP 200): InfoMessageDto

---

#### DELETE /info-messages/{id}

**Authentication**: Keycloak NTM

**Description**: Delete an info message.

**Path Parameters**:
- `{id}` (UUID) - Message identifier

**Response** (HTTP 200): OK (no response body)

---

### Obligations

#### GET /obligations

**Authentication**: Keycloak NTM (ROLE_DATA_ITEM_READER)

**Description**: Get all obligations (data obligations imported from OVD Excel files).

**Response** (HTTP 200): Array of ObligationDto

---

#### GET /obligations/{id}

**Authentication**: Keycloak NTM (ROLE_DATA_ITEM_READER)

**Description**: Get a specific obligation by ID.

**Path Parameters**:
- `{id}` (UUID) - Obligation identifier

**Response** (HTTP 200): ObligationDto

---

### Other Endpoints

#### GET /notifications

**Authentication**: Keycloak NTM

**Description**: Get user notifications.

**Response** (HTTP 200): Array of NotificationDto

---

#### GET /notifications/count

**Authentication**: Keycloak NTM

**Description**: Get unread notification count.

**Response** (HTTP 200): NotificationCountDto

---

#### GET /favorites

**Authentication**: Keycloak NTM

**Description**: Get user's favorite publications.

**Response** (HTTP 200): Array of FavoriteDto

---

#### POST /favorites

**Authentication**: Keycloak NTM

**Description**: Add publication to favorites.

**Request Body**: FavoriteDto

**Response** (HTTP 200): OK (no response body)

---

#### DELETE /favorites

**Authentication**: Keycloak NTM

**Description**: Remove publication from favorites.

**Request Body**: FavoriteDto

**Response** (HTTP 200): OK (no response body)

---

#### GET /datasets

**Authentication**: Keycloak NTM

**Description**: Get all datasets.

> ⚠️ **DEPRECATED** - Moving to new model served by `/obligations`. Will be removed in a future version.

**Response** (HTTP 200): Array of DatasetDto

---

#### GET /data-regulations

**Authentication**: Keycloak NTM

**Description**: Get all data regulations.

> ⚠️ **DEPRECATED** - Moving to new model served by `/obligations`. Will be removed in a future version.

**Response** (HTTP 200): Array of DataRegulationDto

---

#### GET /data-regulations/{id}

**Authentication**: Keycloak NTM

**Description**: Get a specific data regulation.

> ⚠️ **DEPRECATED** - Moving to new model served by `/obligations`. Will be removed in a future version.

**Path Parameters**:
- `{id}` (UUID) - Regulation identifier

**Response** (HTTP 200): DataRegulationDto

---

#### GET /regions/municipalities

**Authentication**: Keycloak NTM

**Description**: Get all municipalities.

**Response** (HTTP 200): Array of RegionDto

---

#### GET /regions/{code}

**Authentication**: Keycloak NTM

**Description**: Get a specific region.

**Path Parameters**:
- `{code}` (string) - Region code

**Response** (HTTP 200): RegionDto

---

#### POST /contact-request

**Authentication**: Keycloak NTM

**Description**: Submit a contact request message.

**Request Body**: UserContactRequestDto

**Response** (HTTP 200): OK (no response body)

---

#### POST /blobs/image

**Authentication**: Keycloak NTM

**Description**: Upload an image file.

**Request Body**: Multipart form data
- `file` (binary, required) - Image file

**Response** (HTTP 200): BlobFileDto

---

#### GET /blobs/image/{id}

**Authentication**: Keycloak NTM

**Description**: Retrieve an uploaded image.

**Path Parameters**:
- `{id}` (UUID) - Image identifier

**Response** (HTTP 200): BlobStorageFile (image)

---

#### GET /subscriptions/mine

**Authentication**: Keycloak NTM

**Description**: Get user's email subscriptions.

**Response** (HTTP 200): EmailSubscriptionsDto

---

#### POST /subscriptions/mine

**Authentication**: Keycloak NTM

**Description**: Update user's email subscriptions.

**Request Body**: EmailSubscriptionsDto

**Response** (HTTP 200): OK (no response body)

---

#### GET /statistics/users

**Authentication**: Keycloak NTM

**Description**: Get user statistics.

**Response** (HTTP 200): UserStatisticsDto

---

#### GET /statistics/organizations

**Authentication**: Keycloak NTM

**Description**: Get organization statistics.

**Response** (HTTP 200): OrganizationStatisticsDto

---

#### GET /statistics/data-publications

**Authentication**: Keycloak NTM

**Description**: Get data publication statistics.

**Response** (HTTP 200): DataPublicationStatisticsDto

---

#### GET /export/users

**Authentication**: Keycloak NTM

**Description**: Export all users as streaming data.

**Response** (HTTP 200): StreamingResponseBody (CSV/TSV format)

---

#### GET /export/publications

**Authentication**: Keycloak NTM

**Description**: Export all publications as streaming data.

**Response** (HTTP 200): StreamingResponseBody (CSV/TSV format)

---

#### GET /translations/usage

**Authentication**: Keycloak NTM

**Description**: Get translation usage statistics.

**Response** (HTTP 200): Usage

---

---

## DATA TYPES (DTOs)

### DataPublicationDto

**Used in**: GET/POST/PUT `/data-publications` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique publication identifier |
| `name` | String | Yes | min 1 char | Publication name |
| `description` | RichTextDto | Yes | - | Rich text description |
| `themes` | Array[String] | Yes | min 1 item | Publication themes |
| `regulationTypes` | Array[String] | No | - | Associated regulation types |
| `categories` | Array[String] | Yes | min 1 item | Data categories |
| `termsOfService` | TermsOfServiceDto | Yes | - | License/terms information |
| `publicationUrl` | String | No | - | URL to publication |
| `scope` | ScopeDto | Yes | - | Geographic and mode scope |
| `dataQuality` | DataQualityDto | No | - | Quality metrics |
| `dataExchanges` | Array[DataExchangeDto] | Yes | min 1 item | Data exchange specifications |
| `startDate` | Date | No | - | Publication start date |
| `endDate` | Date | No | - | Publication end date |
| `organization` | OrganizationDto | No | - | Publishing organization |
| `contact` | ContactDto | No | - | Contact information |
| `contactType` | String | Yes | ORGANIZATION, ORGANIZATION_CONTACT, OWNER | Type of contact |
| `owner` | UserDetailsDto | No | - | Publication owner |
| `obligations` | List[ObligationDto] | No | - | Associated obligations with full details (defaults to empty list) |
| `publicationStatus` | String | Yes | VISIBLE, HIDDEN | Visibility status |
| `reviewStatus` | String | Yes | IMPORTED, PENDING_REVIEW, DEFINITIVE, HELD | Review status |
| `favorite` | Boolean | No | - | Is favorite (user-specific) |
| `imageId` | UUID | No | - | Associated image ID |
| `createdOn` | DateTime | Yes (response) | ISO 8601 | Creation timestamp |
| `updatedOn` | DateTime | Yes (response) | ISO 8601 | Last update timestamp |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Real-time Traffic Data",
  "description": {
    "plain": "Current traffic conditions",
    "formatted": {"ops": [{"insert": "Current traffic conditions"}]}
  },
  "themes": ["TRAFFIC_MANAGEMENT"],
  "categories": ["REAL_TIME_TRAFFIC_DATA"],
  "termsOfService": {"type": "LICENSE_ACCORDING_CREATIVE_COMMONS"},
  "scope": {"regionCodes": ["NL"], "transportModes": ["CAR"]},
  "dataExchanges": [{"dataFileFormat": "JSON", "communicationProtocol": "HTTP_HTTPS"}],
  "organization": {"id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"},
  "publicationStatus": "VISIBLE",
  "reviewStatus": "DEFINITIVE"
}
```

---

### OrganizationDto

**Used in**: GET/POST/PUT `/organizations` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique organization identifier |
| `name` | String | Yes | min 1 char | Organization name |
| `website` | String | No | - | Organization website URL |
| `email` | String | No | Valid email | Contact email |
| `phoneNumber` | String | No | - | Contact phone |
| `address` | AddressDto | No | - | Street address |
| `poBox` | PoBoxDto | No | - | PO Box address |
| `contact` | OrganizationContactDto | No | - | Contact person details |
| `status` | String | No | ACTIVE, PENDING | Organization status |
| `needsModeration` | Boolean | No | - | Requires publication approval |
| `organizationType` | OrganizationType | No | See OrganizationType enum | Category of the organization (public/private sector) |

---

### KeycloakUserResponseDto

**Used in**: GET `/users` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes | - | User identifier |
| `firstName` | String | Yes | - | User's first name |
| `lastName` | String | Yes | - | User's last name |
| `email` | String | Yes | Valid email | User email |
| `phoneNumber` | String | No | - | User phone |
| `organization` | OrganizationDto | No | - | User's organization |
| `role` | String | Yes | ADMIN, OBSERVER, DATA_ITEM_USER, HEAD_EDITOR, EDITOR, USER | User role |
| `createdOn` | DateTime | Yes | ISO 8601 | Account creation date |
| `active` | Boolean | Yes | - | Account active status |

---

### StandardDto

**Used in**: GET/POST/PUT `/standards` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Standard identifier |
| `name` | String | Yes | max 255 chars | Standard name |
| `shortName` | String | Yes | max 20 chars | Short name/abbreviation |
| `description` | RichTextDto | Yes | - | Rich text description |
| `types` | Array[String] | Yes | min 1 item | Standard type (DATA_EXCHANGE, METADATA, PROCESS_AND_WORKFLOW) |
| `themes` | Array[String] | Yes | min 1 item | Associated themes |
| `categories` | Array[String] | Yes | min 1 item | Data categories |
| `networkCoverages` | Array[String] | No | - | Network coverage areas |
| `networkLayer` | String | No | - | Network layer type |
| `region` | String | No | WORLD, EUROPE, NL, OTHER | Geographic region |
| `mobilityStandard` | String | Yes | - | Standard classification |

---

### ObligationDto

**Used in**: GET `/obligations`, `/obligations/{id}`, and embedded in `DataPublicationDto.obligations`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Obligation identifier |
| `startDateNewData` | LocalDate | No | ISO 8601 date | Start date for obligation on new data |
| `startDateExistingData` | LocalDate | No | ISO 8601 date | Start date for obligation on existing data |
| `obligationType` | ObligationType | No | EU, NL | Origin of the obligation |
| `networkType` | DataNetwork | No | See DataNetwork enum | Network coverage type |
| `modality` | Modality | No | DEMAND_DEPENDENT, EXCLUDING_DEMAND_DEPENDENT | Transport modality scope |
| `dataItem` | ObligationDataItemDto | No | - | Linked obligation data item |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "startDateNewData": "2024-01-01",
  "startDateExistingData": "2025-01-01",
  "obligationType": "EU",
  "networkType": "TEN_T",
  "modality": "EXCLUDING_DEMAND_DEPENDENT",
  "dataItem": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "description": "Real-time traffic data obligation",
    "sourceLocation": "EUR-Lex",
    "sourceDescription": "ITS Delegated Regulation",
    "sourceCategory": "ITS",
    "regulationType": "ITS"
  }
}
```

---

### ObligationDataItemDto

**Used in**: ObligationDto.dataItem

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Data item identifier |
| `description` | String | No | - | Description of the data item/obligation |
| `sourceLocation` | String | No | - | Source document location (e.g. EUR-Lex URL) |
| `sourceDescription` | String | No | - | Description of the source document |
| `sourceCategory` | String | No | - | Category of the source |
| `regulationType` | RegulationType | No | See RegulationType enum | Regulation type |

---

### AddressDto

**Used in**: OrganizationDto, StandardOrganizationDto

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `street` | String | Yes | min 1 char | Street name |
| `houseNumber` | String | Yes | min 1 char | House number |
| `houseNumberAddition` | String | No | - | House number suffix |
| `postalCode` | String | Yes | min 1 char | Postal code |
| `city` | String | Yes | min 1 char | City name |
| `country` | String | Yes | ISO 3166-1 alpha-3 code | Country code |

---

## ENUMS

### UserRole

**Used in**: KeycloakUserResponseDto, KeycloakUserCreateUpdateRequestDto

| Value | Description |
|-------|-------------|
| ADMIN | System administrator |
| OBSERVER | View-only access |
| DATA_ITEM_USER | Can manage data items |
| HEAD_EDITOR | Senior editor with approval rights |
| EDITOR | Can edit publications |
| USER | Standard user access |

---

### PublicationStatus

**Used in**: DataPublicationDto

| Value | Description |
|-------|-------------|
| VISIBLE | Publication is publicly visible |
| HIDDEN | Publication is hidden from public view |

---

### ReviewStatus

**Used in**: DataPublicationDto

| Value | Description |
|-------|-------------|
| IMPORTED | Initially imported, not yet reviewed |
| PENDING_REVIEW | Awaiting review/approval |
| DEFINITIVE | Approved and final |
| HELD | On hold pending further action |

---

### ThemeType

**Used in**: DataPublicationDto, StandardDto

| Value | Description |
|-------|-------------|
| SHARE_MOBILITY | Shared mobility services |
| MAAS | Mobility as a Service |
| PUBLIC_TRANSPORT | Public transportation |
| LOGISTIC | Logistics and freight |
| TRAFFIC_SAFETY | Traffic safety |
| TRAFFIC_MANAGEMENT | Traffic management |
| ALTERNATIVE_FUEL | Alternative fuel infrastructure |
| PARKING_HUBS | Parking facilities |
| BIKES | Bicycle infrastructure |

---

### OrganizationType

**Used in**: OrganizationDto

| Value | Description |
|-------|-------------|
| RWS | Rijkswaterstaat (public sector) |
| PROVINCE | Province (public sector) |
| COUNTY | County/municipality (public sector) |
| OTHER_PUBLIC | Other public sector organization |
| DATA_OWNER | Private data owner |
| SERVICE_PROVIDER | Private service provider |
| OTHER_PRIVATE | Other private sector organization |

Each value also carries an `isPublic` boolean: `RWS`, `PROVINCE`, `COUNTY`, `OTHER_PUBLIC` are public (`true`); `DATA_OWNER`, `SERVICE_PROVIDER`, `OTHER_PRIVATE` are private (`false`).

---

### ObligationType

**Used in**: ObligationDto

| Value | Description |
|-------|-------------|
| EU | Obligation originates from EU regulation |
| NL | Obligation originates from Dutch national regulation |

---

### Modality

**Used in**: ObligationDto

| Value | Description |
|-------|-------------|
| DEMAND_DEPENDENT | Demand-dependent transport (e.g., taxis, on-demand buses) |
| EXCLUDING_DEMAND_DEPENDENT | All transport excluding demand-dependent |

---

### RegulationType

**Used in**: DataPublicationDto, ObligationDataItemDto, filter params

| Value | Description |
|-------|-------------|
| TRUCK_PARKING | Truck parking regulation |
| ROAD_SAFETY | Road safety regulation |
| REALTIME | Real-time data regulation |
| MULTIMODAL | Multimodal transport regulation |
| MISC | Miscellaneous regulation |
| AFIR | Alternative Fuels Infrastructure Regulation |
| DATA_TOP_15 | Data Top 15 regulation |
| ENDS | European National Data Spaces regulation |
| SPVV | SPVV regulation |
| ITS | ITS 2023/2661 regulation |

---

### DataNetwork

**Used in**: ObligationDto

| Value | Description |
|-------|-------------|
| EU_ENTIRE_TRANSPORT_NETWORK | Gehele vervoersnetwerk EU |
| MAIN_ROADS | Hoofdwegen |
| TEN_T | TEN-T network |
| TEN_T_PLUS | TEN-T+ network |
| TEN_T_PLUS_AND_OTHER_HIGHWAYS | TEN-T+ en andere snelwegen |
| TEN_T_AND_ROADS_WITH_INTENSITY_GREATER_THAN_8000 | TEN-T & wegen met intensiteit > 8000 |
| ROADS_WITH_URBAN_NODES | Wegen met urban nodes |
| OTHER | Other network |

---

### TermsOfServiceType

**Used in**: TermsOfServiceDto

| Value | Description |
|-------|-------------|
| NO_LICENSE_NO_AGREEMENT | No formal license |
| LICENSE_ACCORDING_CREATIVE_COMMONS | Creative Commons license |
| LICENSE_REWARD | License with attribution requirement |
| CONTRACT_NO_REWARD | Contract without compensation |
| CONTRACT_REWARD | Contract with compensation |

---

### DataFileFormat

**Used in**: DataExchangeDto

| Value | Description |
|-------|-------------|
| CSV | Comma-separated values |
| JSON | JSON format |
| GeoJSON | Geographic JSON |
| XML | XML format |
| XLSX | Excel spreadsheet |
| PDF | Portable Document Format |
| GTFS | General Transit Feed Specification |
| REST | REST API |
| WFS_SRVC | Web Feature Service |
| WMS_SRVC | Web Map Service |
| Other formats | CSV, DOC, DOCX, DWG, DXF, GEOTIFF, GML, GPX, HTML, KML, KMZ, MARKDOWN, MPEG4, NETCDF, PARQUET, RSS, SHP, XLS |

---

### CommunicationProtocol

**Used in**: DataExchangeDto

| Value | Description |
|-------|-------------|
| HTTP_HTTPS | HTTP/HTTPS web protocol |
| FTP | File Transfer Protocol |
| MQTT | MQTT messaging protocol |
| AMQP | Advanced Message Queuing Protocol |
| GRPC | gRPC protocol |
| SOAP | SOAP web services |
| REST | RESTful API |
| OTS2 | OTS2 protocol |
| RSS | RSS feeds |
| Other | Other protocol |

---

### CommunicationMethod

**Used in**: DataExchangeDto

| Value | Description |
|-------|-------------|
| PUSH | Server pushes data to client |
| PULL | Client pulls data from server |

---

### UpdateFrequency

**Used in**: DataPublicationDto, DataExchangeDto

| Value | Description |
|-------|-------------|
| CONTINUOUS | Continuous real-time updates |
| HOURLY | Updated hourly |
| DAILY | Updated daily |
| WEEKLY | Updated weekly |
| MONTHLY | Updated monthly |
| ANNUALLY | Updated annually |
| NEVER | Not updated |
| UNKNOWN | Update frequency unknown |
| Other frequencies | Various time-based frequencies (ANNUAL_2, BIWEEKLY, AS_NEEDED, etc.) |

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://ntm.staging.ndw.nu/api`
**Security Scheme**: OAuth2 (Keycloak NTM)

### Required Authentication

All endpoints require valid Keycloak NTM authentication with an OAuth2 bearer token.

### Authentication Details

- **Provider**: Keycloak NTM
- **Security Scheme**: OAuth2
- **Token Format**: Bearer token in Authorization header
- **Scopes**: Various based on endpoint

### Role-Based Access Control

| Role | Access Level | Typical Endpoints |
|------|--------------|-------------------|
| ADMIN | Full system access | All endpoints, organization management |
| HEAD_EDITOR | Editorial approval | `/data-publications/{id}/approve`, `/role_requests/approve` |
| EDITOR | Publication creation/editing | POST/PUT `/data-publications`, publication management |
| DATA_ITEM_USER | Limited publication access | GET `/data-publications`, limited modifications |
| OBSERVER | Read-only access | GET endpoints only |
| USER | Basic user access | Profile, favorites, notifications |

---

## COMMON USE CASES

### Publishing a Data Publication

1. Create publication: `POST /data-publications`
2. Review status becomes `PENDING_REVIEW` if organization requires moderation
3. Admin approves: `POST /data-publications/{id}/approve` (→ `DEFINITIVE`)
4. Publication becomes `VISIBLE` to users

### Managing User Roles

1. User requests role: `POST /organizations/{id}/role_requests?role=EDITOR`
2. Status: `REQUESTED`
3. Admin approves: `POST /organizations/{id}/role_requests/{id}/approve` (→ `APPROVED`)
4. Or denies: `POST /organizations/{id}/role_requests/{id}/deny`

### Searching Publications

- Full-text search: `/data-publications?search=traffic`
- Filter by theme: `/data-publications?themes=TRAFFIC_MANAGEMENT`
- Filter by organization: `/data-publications?organizationId={id}`
- Filter by review status: `/data-publications?reviewStatus=DEFINITIVE`
- Complex filters with pagination

---

## NOTES

- **Keycloak Integration**: User authentication and roles managed via Keycloak
- **Publication Workflow**: Supports PENDING_REVIEW → DEFINITIVE → VISIBLE flow
- **Rich Text Support**: Descriptions use QuillDelta format for rich text editing
- **Multi-language Support**: Supports multiple languages via Accept-Language header
- **GeoJSON Support**: Scope includes geographic coverage information
- **Pagination**: Most list endpoints support pagination via Pageable parameter
- **File Upload**: Logo and image uploads via multipart form data
- **Statistics**: Admin endpoints provide usage analytics
- **DCAT-AP ADMS Identifiers**: In the DCAT-AP XML output (`/v1`), `otherIdentifiers` are now serialized as proper `adms:Identifier` resources with `skos:notation` (spec-compliant). This affects only the RDF/XML catalog output, not the JSON REST API.

---
