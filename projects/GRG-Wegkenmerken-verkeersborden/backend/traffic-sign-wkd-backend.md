# Traffic Sign WKD Backend - API Reference

Complete reference for the traffic-sign-wkd-backend API. This service manages vehicle access restrictions (WKD - Wegverkeerswet) mutations for road sections, including speed limits, traffic types, school zones, RVM types, road narrowings, categories, authorities, and various restriction types (height, length, load, axle-load).

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | 3856557 | 2026-03-10 |
| Commit Message | Feature #110189 JDK25 compatibility (no API changes) | |
| Swagger Version | latest | 2026-03-10 |

**Status**: ✓ Up to date as of 2026-03-10
**Next Review**: Check commits after 3856557

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required | Purpose |
|---------|----------------|--------------|---------------|---------|
| **Traffic Types** | `/traffic-types/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Vehicle type restrictions (car, truck, motorcycle, etc.) |
| **Speed Limits** | `/speeds/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Speed limit restrictions |
| **Speed Upload** | `/speeds/upload` | POST | NDW IAM | Bulk speed limit uploads |
| **School Zones** | `/schoolzones/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | School zone restrictions |
| **RVM Types** | `/rvm-types/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | RVM (Remote VMS) type restrictions |
| **Road Narrowings** | `/road-narrowings/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Road narrowing points |
| **Road Categories** | `/road-categories/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Road category classifications |
| **Road Authorities** | `/road-authorities/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Road authority assignments |
| **Load Restrictions** | `/load-restrictions/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Total load weight restrictions |
| **Length Restrictions** | `/length-restrictions/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Vehicle length restrictions |
| **Height Restrictions** | `/height-restrictions/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Vehicle height restrictions |
| **Axle Load Restrictions** | `/axle-load-restrictions/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Per-axle weight restrictions |
| **Driving Directions** | `/driving-directions/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Traffic driving direction requirements |
| **Carriageway Types** | `/carriageway-types/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST, DELETE | NDW IAM | Carriageway type specifications |
| **Joint Mutations** | `/joint-mutations/{nwbVersion}/road-sections/{roadSectionId}` | GET, POST | NDW IAM | Combined mutations for road section |
| **File Uploads** | `/file-uploads` | GET | NDW IAM | Track file upload status and history |
| **SFTP Operations** | `/sftp/*` | GET, POST | NDW IAM | SFTP server interactions for batch processing |
| **Export Operations** | `/export/*` | POST, GET | NDW IAM | Data export and migration between NWB versions |
| **Usage Statistics** | `/usage-statistics` | GET | NDW IAM | Usage tracking and reporting |
| **NLS Integration** | `/nls/*` | GET | NDW IAM | Integration with national traffic data services |

---

## DETAILED ENDPOINTS

### Speed Limit Mutations

#### GET /speeds/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Get speed limit mutations for a specific road section and NWB version.

**Path Parameters**:
- `{nwbVersion}` (date, YYYY-MM-DD) - NWB version (e.g., 2025-01-01)
- `{roadSectionId}` (integer) - Road section identifier (must be > 0)

**Response** (HTTP 200): Array of SpeedMutationDto

**Example Response**:
```json
[
  {
    "nwbVersion": "2025-01-01",
    "roadSectionId": 12345,
    "segments": [
      {
        "from": 0,
        "to": 500,
        "direction": "BOTH",
        "speedLimit": "KM_50"
      }
    ],
    "status": "PROCESSED",
    "version": "2026-01-28T10:30:00Z",
    "organizationId": "org-uuid"
  }
]
```

---

#### POST /speeds/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Create or update speed limit mutations for a road section.

**Path Parameters**:
- `{nwbVersion}` (date) - NWB version
- `{roadSectionId}` (integer) - Road section ID

**Request Body**: Array of SpeedMutationDto

**Response** (HTTP 200): FeatureCollection

**Note** (updated eac7cbc): Segment length validation now allows minor rounding errors — if the segment max `to` value is within 1 metre of the road section length (due to floating-point rounding), the backend automatically adjusts it to match the road section length exactly rather than rejecting the request.

---

#### DELETE /speeds/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Delete speed limit mutations for a road section.

**Path Parameters**:
- `{nwbVersion}` (date) - NWB version
- `{roadSectionId}` (integer) - Road section ID

**Response** (HTTP 200): OK

---

#### POST /speeds/upload

**Authentication**: NDW IAM

**Description**: Bulk upload speed limit mutations from file.

**Request Body**: Multipart form-data with file

**Response** (HTTP 200): FileUploadDto

---

#### GET /speeds/{nwbVersion}

**Authentication**: NDW IAM

**Description**: Get all speed mutations for an NWB version (optionally filtered by road authority).

**Path Parameters**:
- `{nwbVersion}` (date) - NWB version

**Query Parameters**:
- `roadAuthority` (array of strings, optional) - Filter by road authority codes

**Response** (HTTP 200): FeatureCollection

---

#### GET /speeds (Paginated)

**Authentication**: NDW IAM

**Description**: Get all speed mutations with pagination and filtering.

**Query Parameters**:
- `criteria` (SpeedMutationCriteria, required) - Filter criteria
- `pageable` (Pageable, required) - Pagination info

**Response** (HTTP 200): PageSpeedMutationDto

---

### Traffic Type Mutations

#### GET /traffic-types/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Get traffic type (vehicle type allowed) for a road section.

**Path Parameters**:
- `{nwbVersion}` (date) - NWB version
- `{roadSectionId}` (integer) - Road section ID

**Response** (HTTP 200): TrafficTypeMutationDto

**Example Response**:
```json
{
  "nwbVersion": "2025-01-01",
  "roadSectionId": 12345,
  "trafficDirectionTypes": [
    {
      "trafficType": "CAR",
      "forward": true,
      "backward": true
    },
    {
      "trafficType": "TRUCK",
      "forward": true,
      "backward": false
    }
  ],
  "status": "PROCESSED"
}
```

---

#### POST /traffic-types/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Create or update traffic type mutation for a road section.

**Request Body**: TrafficTypeMutationDto

**Response** (HTTP 200): Feature (GeoJSON)

**GeoJSON Feature Properties** (flat format — one boolean property per traffic type × direction):
```json
{
  "type": "Feature",
  "geometry": { "type": "LineString", "coordinates": [...] },
  "properties": {
    "roadSectionId": 12345,
    "roadAuthorityType": "G",
    "roadAuthorityCode": "344",
    "status": "NEW",
    "organizationId": "org-uuid",
    "pedestrianForward": true,
    "pedestrianBackward": true,
    "bicycleForward": true,
    "bicycleBackward": true,
    "mofaForward": false,
    "mofaBackward": false,
    "mopedForward": false,
    "mopedBackward": false,
    "motorcycleForward": true,
    "motorcycleBackward": true,
    "carForward": true,
    "carBackward": true,
    "trailerForward": true,
    "trailerBackward": false,
    "truckForward": true,
    "truckBackward": false,
    "busForward": true,
    "busBackward": false,
    "agriculturalvehicleForward": false,
    "agriculturalvehicleBackward": false
  }
}
```

**Note**: Properties use the `TrafficType.wkdPrefix` + `Forward`/`Backward` pattern. WKD prefixes differ from enum names: `MOPED_25` → `mofa`, `MOPED_45` → `moped`, `AGRICULTURAL_VEHICLE` → `agriculturalvehicle`.

---

#### DELETE /traffic-types/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Delete traffic type mutation.

**Response** (HTTP 200): OK

---

### School Zone Mutations

#### GET /schoolzones/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Get school zone mutations for a road section.

**Path Parameters**:
- `{nwbVersion}` (date) - NWB version
- `{roadSectionId}` (integer) - Road section ID

**Response** (HTTP 200): Array of SchoolZoneMutationDto

---

#### POST /schoolzones/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Create school zone mutation.

**Request Body**: SchoolZoneMutationDto

**Response** (HTTP 200): Feature (GeoJSON)

---

#### GET /schoolzones/{nwbVersion}/road-sections/{roadSectionId}/{brinCode}

**Authentication**: NDW IAM

**Description**: Get specific school zone by BRIN code (educational institution identifier).

**Path Parameters**:
- `{nwbVersion}` (date) - NWB version
- `{roadSectionId}` (integer) - Road section ID
- `{brinCode}` (string) - BRIN code of school

**Response** (HTTP 200): SchoolZoneMutationDto

---

#### DELETE /schoolzones/{nwbVersion}/road-sections/{roadSectionId}/{brinCode}

**Authentication**: NDW IAM

**Description**: Delete specific school zone.

**Response** (HTTP 200): OK

---

#### GET /schoolzones/max-zone-number

**Authentication**: NDW IAM

**Description**: Get maximum school zone number for numbering purposes.

**Response** (HTTP 200): MaxSchoolZoneNumberDto

---

### Restriction Mutations

#### GET /height-restrictions/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Get height restrictions for a road section.

**Response** (HTTP 200): Array of HeightRestrictionMutationDto

---

#### POST /height-restrictions/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Create height restrictions.

**Request Body**: Array of HeightRestrictionMutationDto

**Response** (HTTP 200): FeatureCollection

---

#### DELETE /height-restrictions/{nwbVersion}/road-sections/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Delete height restrictions.

**Response** (HTTP 200): OK

---

Similar endpoints exist for:
- `/length-restrictions/` - Vehicle length restrictions
- `/load-restrictions/` - Total load weight restrictions
- `/axle-load-restrictions/` - Per-axle weight restrictions
- `/road-narrowings/` - Road narrowing points
- `/road-categories/` - Road category classifications
- `/road-authorities/` - Road authority assignments
- `/rvm-types/` - RVM type definitions
- `/driving-directions/` - Driving direction requirements
- `/carriageway-types/` - Carriageway type specifications

---

### Data Upload Operations

#### POST /speeds/upload

**Authentication**: NDW IAM

**Description**: Upload speed limits from file.

**Request Body**: Multipart file upload

**Response** (HTTP 200): FileUploadDto

**Note** (updated adc16c6): On validation failure, the response now includes a more specific error code (`upload.error.invalid-speed`) with carriageway type, speed value, and direction details, in addition to the generic `upload.error.invalid-mutation` and `upload.error.invalid-segment-range` codes.

---

#### POST /driving-directions/upload

**Authentication**: NDW IAM

**Description**: Upload driving directions from file.

---

#### POST /carriageway-types/upload

**Authentication**: NDW IAM

**Description**: Upload carriageway types from file.

---

### Export and Migration Operations

#### POST /export/start

**Authentication**: NDW IAM

**Description**: Start data export for a specific WKD type and NWB version. On completion, the system sends email notifications to configured recipients with the export result (updated 685a5d3).

**Query Parameters**:
- `nwbVersion` (date, optional) - Target NWB version
- `type` (string, required) - Export type (SPEED_LIMIT, HEIGHT_RESTRICTION, etc.)

**Response** (HTTP 200): Job ID (string)

---

#### POST /export/run-processed-job/wkd

**Authentication**: NDW IAM

**Description**: Run post-processing job for WKD data.

**Query Parameters**:
- `wkdType` (string, required) - WKD type to process

**Response** (HTTP 200): Job status

---

#### POST /export/migrate

**Authentication**: NDW IAM

**Description**: Migrate data from one NWB version to another.

**Query Parameters**:
- `fromNwbVersion` (date, required) - Source NWB version
- `toNwbVersion` (date, required) - Target NWB version
- `type` (string, required) - Data type to migrate

**Response** (HTTP 200): Job ID

---

#### POST /export/remigrate

**Authentication**: NDW IAM

**Description**: Re-migrate previously migrated data.

**Query Parameters**:
- `fromNwbVersion` (date, required) - Source NWB version
- `toNwbVersion` (date, required) - Target NWB version
- `type` (string, required) - Data type

---

#### GET /export/files

**Authentication**: NDW IAM

**Description**: List export files for a specific NWB version.

**Query Parameters**:
- `nwbVersion` (date, required) - NWB version

**Response** (HTTP 200): File list

---

### SFTP Operations

#### GET /sftp/test

**Authentication**: NDW IAM

**Description**: Test SFTP connection.

**Response** (HTTP 200): Connection status

---

#### GET /sftp/list

**Authentication**: NDW IAM

**Description**: List files on SFTP server.

**Response** (HTTP 200): Array of filenames

---

#### POST /sftp/write

**Authentication**: NDW IAM

**Description**: Write data to SFTP server.

**Query Parameters**:
- `content` (string, optional) - Content to write (auto-generated if empty)
- `filename` (string, optional) - Filename (auto-generated if empty)

**Response** (HTTP 200): Confirmation

---

### NLS Integration Endpoints

#### GET /nls/wkd/trafficType/{wkdVersion}

**Authentication**: NDW IAM

**Description**: Get traffic type data from NLS (national traffic services).

**Path Parameters**:
- `{wkdVersion}` (date) - WKD version

**Query Parameters**:
- `nwbRoadSectionId` (integer, required) - NWB road section ID

**Response** (HTTP 200): Traffic type object

---

#### GET /nls/wkd/speedLimit/{wkdVersion}

**Authentication**: NDW IAM

**Description**: Get speed limit data from NLS.

---

#### GET /nls/wkd/schoolZone/{wkdVersion}

**Authentication**: NDW IAM

**Description**: Get school zone data from NLS.

**Query Parameters**:
- `nwbRoadSectionId` (integer, optional) - Road section ID
- `brin6` (string, optional) - BRIN code filter
- `schoolName` (string, optional) - School name filter

---

#### GET /nls/nwb/map/{mapVersion}/roadSection

**Authentication**: NDW IAM

**Description**: Find road sections by address label.

**Query Parameters**:
- `bagPublicSpaceLabel` (string, optional) - BAG public space label
- `page` (integer, optional) - Page number
- `size` (integer, optional) - Page size

---

#### GET /nls/nwb/map/{mapVersion}/roadSection/{roadSectionId}

**Authentication**: NDW IAM

**Description**: Get road section details from NWB.

---

#### GET /nls/routing/map/{mapVersion}/nearest/{coordinates}

**Authentication**: NDW IAM

**Description**: Find nearest road sections to coordinates.

**Path Parameters**:
- `{coordinates}` (string) - Coordinates (format: "lon,lat")

**Query Parameters**:
- `radius` (number, optional) - Search radius in meters

---

### Usage Statistics

#### GET /usage-statistics

**Authentication**: NDW IAM

**Description**: Get usage statistics for WKD mutations.

**Query Parameters**:
- `date-start` (date, optional) - Start date
- `date-end` (date, optional) - End date
- `organization-id` (array of UUIDs, optional) - Filter by organization

**Response** (HTTP 200): CSV or JSON array

---

## DATA TYPES (DTOs)

### SpeedMutationDto

**Used in**: Speed mutation endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `nwbVersion` | Date | Yes | YYYY-MM-DD | NWB version reference |
| `roadSectionId` | Integer | Yes | > 0 | Road section identifier |
| `segments` | Array[Segment] | Yes | - | Speed limit segments |
| `status` | Enum | Yes | NEW, SENT, PROCESSED, NOT_PROCESSED, MIGRATED, NOT_MIGRATED | Mutation status |
| `version` | DateTime | No | ISO 8601 | Last update timestamp |
| `createdOn` | DateTime | No | ISO 8601 | Creation timestamp |
| `organizationId` | UUID | No | - | Organization that created mutation |

---

### TrafficTypeMutationDto

**Used in**: Traffic type mutation endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `nwbVersion` | Date | Yes | YYYY-MM-DD | NWB version |
| `roadSectionId` | Integer | Yes | > 0 | Road section ID |
| `trafficDirectionTypes` | Array[TrafficDirectionTypeDto] | Yes | Exactly 10 items | Traffic type list |
| `status` | Enum | Yes | NEW, SENT, PROCESSED, NOT_PROCESSED, MIGRATED, NOT_MIGRATED | Mutation status |
| `version` | DateTime | No | ISO 8601 | Last update |
| `createdOn` | DateTime | No | ISO 8601 | Creation timestamp |
| `organizationId` | UUID | No | - | Organization ID |

---

### TrafficDirectionTypeDto

**Used in**: TrafficTypeMutationDto trafficDirectionTypes array

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `trafficType` | Enum | Yes | PEDESTRIAN, BICYCLE, MOPED_25, MOPED_45, MOTORCYCLE, CAR, TRAILER, TRUCK, BUS, AGRICULTURAL_VEHICLE | Vehicle type |
| `forward` | Boolean | Yes | - | Allowed in forward direction |
| `backward` | Boolean | Yes | - | Allowed in backward direction |

---

### SchoolZoneMutationDto

**Used in**: School zone mutation endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `nwbVersion` | Date | Yes | - | NWB version |
| `roadSectionId` | Integer | Yes | > 0 | Road section ID |
| `brinCode` | String | Yes | - | School BRIN identifier |
| `zoneNumber` | Integer | No | - | Zone sequence number |
| `status` | Enum | Yes | NEW, SENT, PROCESSED, NOT_PROCESSED, MIGRATED, NOT_MIGRATED | Status |

---

### FileUploadDto

**Used in**: Upload endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Upload identifier |
| `status` | Enum | Yes | STARTED, COMPLETED, FAILED | Upload status |
| `startedOn` | DateTime | No | ISO 8601 | Start time |
| `endedOn` | DateTime | No | ISO 8601 | Completion time |
| `dataBlob` | BlobFileDto | No | - | Uploaded data file |
| `reportBlob` | BlobFileDto | No | - | Upload report file |

---

## ENUMS

### MutationStatus

**Used in**: All mutation DTOs

| Value | Description |
|-------|-------------|
| NEW | Newly created, not yet sent |
| SENT | Sent for processing |
| PROCESSED | Successfully processed |
| NOT_PROCESSED | Processing failed |
| MIGRATED | Migrated to new NWB version |
| NOT_MIGRATED | Migration failed |

---

### TrafficType

**Used in**: TrafficDirectionTypeDto, GeoJSON feature properties (as `{wkdPrefix}Forward`/`{wkdPrefix}Backward`)

| Value | WKD Prefix | Description |
|-------|------------|-------------|
| PEDESTRIAN | `pedestrian` | Pedestrians/foot traffic |
| BICYCLE | `bicycle` | Bicycles/cycles |
| MOPED_25 | `mofa` | Mopeds max 25 km/h |
| MOPED_45 | `moped` | Mopeds max 45 km/h |
| MOTORCYCLE | `motorcycle` | Motorcycles |
| CAR | `car` | Passenger cars |
| TRAILER | `trailer` | Vehicles with trailers |
| TRUCK | `truck` | Heavy goods vehicles |
| BUS | `bus` | Buses/public transport |
| AGRICULTURAL_VEHICLE | `agriculturalvehicle` | Agricultural machinery |

---

### ExportType

**Used in**: Export endpoints

| Value | Description |
|-------|-------------|
| AXLE_LOAD_RESTRICTION | Per-axle weight limits |
| CARRIAGEWAY_TYPE | Carriageway classifications |
| DRIVING_DIRECTION | Traffic direction rules |
| HEIGHT_RESTRICTION | Height limitations |
| LENGTH_RESTRICTION | Length limitations |
| LOAD_RESTRICTION | Total weight limits |
| ROAD_AUTHORITY | Road authority assignments |
| ROAD_CATEGORY | Road classifications |
| ROAD_NARROWING | Narrowing points |
| RVM_TYPE | Remote VMS types |
| SCHOOL_ZONE | School zones |
| SPEED_LIMIT | Speed restrictions |
| TRAFFIC_TYPE | Vehicle type allowances |

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api/wkd`
**Security Scheme**: OAuth2 (NDW IAM)

### Required Authentication

All endpoints require valid NDW IAM authentication.

### Authentication Details

- **Provider**: NDW IAM (Keycloak)
- **Authorization URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/auth`
- **Token URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`
- **Refresh URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`

---

## KEY CONCEPTS

### NWB Versions

All WKD mutations are version-specific. Each mutation is tied to a specific **NWB (National Road Network) version** in date format (YYYY-MM-DD).

- Example: `2025-01-01` represents the NWB version from January 1, 2025
- Mutations can be migrated between versions
- Export operations work with specific NWB versions

### Road Sections

Road sections are the fundamental geographic units. All mutations apply to specific road sections identified by:
- `roadSectionId` - Unique identifier for the road section
- `nwbVersion` - NWB version the section belongs to

### Mutation Statuses

Mutations progress through states:
1. **NEW** - Created but not yet sent
2. **SENT** - Sent for processing
3. **PROCESSED** - Successfully applied
4. **NOT_PROCESSED** - Failed to process
5. **MIGRATED** - Moved to new NWB version
6. **NOT_MIGRATED** - Migration failed

### GeoJSON Responses

Many endpoints return GeoJSON Feature or FeatureCollection objects for geographic visualization:
- GET operations may return map-compatible responses
- POST operations that create mutations may return Feature (GeoJSON format)
- Useful for displaying on maps and in geographic viewers

---

## COMMON WORKFLOWS

### Creating a Speed Limit

1. Identify road section ID and NWB version
2. POST to `/speeds/{nwbVersion}/road-sections/{roadSectionId}`
3. Provide SpeedMutationDto with segments
4. System processes and applies mutation
5. Query result using GET to verify

### Bulk Upload

1. Prepare file in expected format
2. POST to `/speeds/upload` or similar upload endpoint
3. File processed asynchronously
4. Check FileUploadDto for status and report

### Version Migration

1. Get all mutations for source NWB version
2. POST to `/export/migrate` with source and target versions
3. System migrates all compatible mutations
4. Verify with GET for target NWB version

---
