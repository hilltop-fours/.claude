# Traffic Sign Area Backend - API Reference

Complete reference for the traffic-sign-area-backend API. This service handles area-related data including environmental zones, emission zones, parking bans, traffic regulations, hazardous substance routes, and geographic areas.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | 5549738 | 2026-03-10 |
| Commit Message | Feature #110189 JDK25 compatibility (no API changes) | |
| Swagger Version | latest | 2026-03-10 |

**Status**: ✓ Up to date as of 2026-03-10
**Next Review**: Check commits after 5549738

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required |
|---------|----------------|--------------|---------------|
| **Environmental Zones** | `/environmental-zones`, `/environmental-zones/{id}` | GET, POST, POST (update) | NDW IAM |
| **Emission Zones** | `/emission-zones`, `/emission-zones/{id}` | GET, POST, POST (update) | NDW IAM |
| **Zone Uploads** | `/environmental-zones/upload`, `/emission-zones/upload` | POST | NDW IAM |
| **Parking Bans** | `/parking-bans`, `/parking-bans/{id}` | GET, POST, POST (update), DELETE | NDW IAM |
| **Traffic Regulations** | `/traffic-regulations`, `/traffic-regulations/{id}` | GET, POST, POST (update), DELETE | NDW IAM |
| **Hazardous Substance Routes** | `/routes/hazardous-substances`, `/routes/hazardous-substances/{id}` | GET, POST, PUT, DELETE | NDW IAM |
| **Map Features** | `/environmental-zones/map`, `/emission-zones/map`, `/parking-bans/map`, `/routes/hazardous-substances/map` | GET | NDW IAM |
| **Areas** | `/areas`, `/areas/{id}` | GET, POST, POST (update), DELETE | NDW IAM |
| **Geographic Data** | `/counties`, `/counties/{code}`, `/towns` | GET | NDW IAM |
| **Coordinate Conversion** | `/conversion/wgs84` | POST | NDW IAM |

---

## DETAILED ENDPOINTS

### Environmental Zones

#### GET /environmental-zones

**Authentication**: NDW IAM

**Description**: Retrieve all environmental zones with optional filtering.

**Query Parameters**:
- `zoneType` (string, optional) - Filter by zone type: ENVIRONMENTAL_ZONE, ZERO_EMISSION_ZONE
- `regulationId` (string, optional) - Filter by regulation ID (pattern: `^(gmb|stcrt|prb|stb|wsb|bgr|trb)-(19|20)\d{2}-\d+$`)
- `countyCode` (string, optional) - Filter by county code (pattern: `^[1-9]\d{1,3}$`)

**Response** (HTTP 200): Array of EnvironmentalZoneDto

**Example Response**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "identification": "Zone-A-001",
    "zoneType": "ENVIRONMENTAL_ZONE",
    "validFrom": "2025-01-01T00:00:00Z",
    "validTo": "2026-12-31T23:59:59Z",
    "regulationId": "gmb-2025-1234",
    "trafficOrderStatus": "DEFINITIVE",
    "countyCode": "0363",
    "taxiMaxRegistrationYear": 2015,
    "exemptions": [
      {
        "vehicleType": "CAR",
        "classification": "EURO6"
      }
    ]
  }
]
```

**Notes**:
- Returns empty array if no zones match criteria
- Optional filtering parameters can be combined

---

#### POST /environmental-zones

**Authentication**: NDW IAM

**Description**: Create a new environmental zone.

**Request Body**: EnvironmentalZoneDto

**Example Request**:
```json
{
  "identification": "Zone-A-002",
  "zoneType": "ENVIRONMENTAL_ZONE",
  "validFrom": "2025-01-01T00:00:00Z",
  "regulationId": "gmb-2025-1235",
  "trafficOrderStatus": "PLANNED",
  "area": {
    "type": "Polygon",
    "coordinates": [[
      [52.0, 5.0],
      [52.1, 5.0],
      [52.1, 5.1],
      [52.0, 5.1],
      [52.0, 5.0]
    ]]
  },
  "taxiMaxRegistrationYear": 2015,
  "exemptions": [
    {
      "vehicleType": "CAR",
      "classification": "EURO6"
    }
  ]
}
```

**Response** (HTTP 200): EnvironmentalZoneDto

**Possible Status Codes**:
- 200 OK - Zone created
- 400 Bad Request - Invalid data
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Area is required and must be valid GeoJSON geometry
- regulationId must match specific pattern
- taxiMaxRegistrationYear optional for ZERO_EMISSION_ZONE

---

#### POST /environmental-zones/{id}

**Authentication**: NDW IAM

**Description**: Update an existing environmental zone.

**Path Parameters**:
- `{id}` (UUID) - Environmental zone identifier

**Request Body**: EnvironmentalZoneDto

**Response** (HTTP 200): EnvironmentalZoneDto

**Notes**:
- Full update (replaces entire record)
- Zone must exist

---

#### DELETE /environmental-zones/{id}

**Authentication**: NDW IAM

**Description**: Delete an environmental zone.

**Path Parameters**:
- `{id}` (UUID) - Environmental zone identifier

**Response** (HTTP 200): OK

**Possible Status Codes**:
- 200 OK - Zone deleted
- 404 Not Found - Zone not found

---

#### POST /environmental-zones/upload

**Authentication**: NDW IAM

**Description**: Upload environmental zones from a GeoJSON or feature collection file.

**Request Body**: Multipart form-data with file upload

**Form Parameters**:
- `file` (binary, required) - GeoJSON or FeatureCollection file

**Response** (HTTP 200): FeatureCollection

**Example Response**:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "identification": "Zone-A-001",
        "zoneType": "ENVIRONMENTAL_ZONE"
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[...]]
      }
    }
  ]
}
```

**Notes**:
- Bulk upload operation
- File must be valid GeoJSON format
- Returns processed features

---

### Emission Zones

#### GET /emission-zones

**Authentication**: NDW IAM

**Description**: Retrieve all emission zones with optional filtering.

**Query Parameters**:
- `zoneType` (string, optional) - Filter by zone type: ENVIRONMENTAL_ZONE, ZERO_EMISSION_ZONE
- `regulationId` (string, optional) - Filter by regulation ID
- `countyCode` (string, optional) - Filter by county code

**Response** (HTTP 200): Array of EnvironmentalZoneDto

**Notes**:
- Same filtering as environmental zones
- Emission zones use the same EnvironmentalZoneDto structure

---

#### POST /emission-zones

**Authentication**: NDW IAM

**Description**: Create a new emission zone.

**Request Body**: EnvironmentalZoneDto

**Response** (HTTP 200): EnvironmentalZoneDto

**Notes**:
- zoneType should be ZERO_EMISSION_ZONE for emission zones

---

#### POST /emission-zones/{id}

**Authentication**: NDW IAM

**Description**: Update an existing emission zone.

**Path Parameters**:
- `{id}` (UUID) - Emission zone identifier

**Request Body**: EnvironmentalZoneDto

**Response** (HTTP 200): EnvironmentalZoneDto

---

#### DELETE /emission-zones/{id}

**Authentication**: NDW IAM

**Description**: Delete an emission zone.

**Path Parameters**:
- `{id}` (UUID) - Emission zone identifier

**Response** (HTTP 200): OK

---

#### POST /emission-zones/upload

**Authentication**: NDW IAM

**Description**: Upload emission zones from a GeoJSON file.

**Request Body**: Multipart form-data with file upload

**Response** (HTTP 200): FeatureCollection

---

### Parking Bans

#### GET /parking-bans

**Authentication**: NDW IAM

**Description**: Retrieve all parking bans.

**Response** (HTTP 200): Array of ParkingBanDto

**Example Response**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Summer Parking Ban 2025",
    "validFrom": "2025-06-01T00:00:00Z",
    "validTo": "2025-08-31T23:59:59Z",
    "remarks": "No parking during summer events",
    "areas": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440010",
        "name": "City Center",
        "countyCode": "0363"
      }
    ],
    "trafficRegulations": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440020",
        "name": "Event Parking Restriction",
        "regulationId": "gmb-2025-1236"
      }
    ]
  }
]
```

---

#### POST /parking-bans

**Authentication**: NDW IAM

**Description**: Create a new parking ban.

**Request Body**: ParkingBanDto

**Example Request**:
```json
{
  "name": "Winter Parking Ban 2025",
  "validFrom": "2025-12-01T00:00:00Z",
  "validTo": "2026-02-28T23:59:59Z",
  "remarks": "No parking for snow removal",
  "areas": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "name": "City Center"
    }
  ],
  "trafficRegulations": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440020"
    }
  ]
}
```

**Response** (HTTP 200): ParkingBanDto

---

#### POST /parking-bans/{id}

**Authentication**: NDW IAM

**Description**: Update a parking ban.

**Path Parameters**:
- `{id}` (UUID) - Parking ban identifier

**Request Body**: ParkingBanDto

**Response** (HTTP 200): ParkingBanDto

---

#### DELETE /parking-bans/{id}

**Authentication**: NDW IAM

**Description**: Delete a parking ban.

**Path Parameters**:
- `{id}` (UUID) - Parking ban identifier

**Response** (HTTP 200): OK

---

### Traffic Regulations

#### GET /traffic-regulations

**Authentication**: NDW IAM

**Description**: Retrieve all traffic regulations.

**Response** (HTTP 200): Array of TrafficRegulationDto

**Example Response**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440020",
    "name": "Event Parking Restriction",
    "regulationId": "gmb-2025-1236",
    "validFrom": "2025-06-01T00:00:00Z",
    "validTo": "2025-08-31T23:59:59Z",
    "countyCode": "0363",
    "validityConditions": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440030",
        "daysOfWeek": [1, 2, 3, 4, 5],
        "startTime": "09:00",
        "endTime": "17:00",
        "isException": false
      }
    ]
  }
]
```

---

#### POST /traffic-regulations

**Authentication**: NDW IAM

**Description**: Create a new traffic regulation.

**Request Body**: TrafficRegulationDto

**Example Request**:
```json
{
  "name": "New Traffic Regulation",
  "regulationId": "gmb-2025-1237",
  "validFrom": "2025-06-01T00:00:00Z",
  "validityConditions": [
    {
      "daysOfWeek": [1, 2, 3, 4, 5],
      "startTime": "09:00",
      "endTime": "17:00",
      "isException": false
    }
  ]
}
```

**Response** (HTTP 200): TrafficRegulationDto

---

#### GET /traffic-regulations/{id}

**Authentication**: NDW IAM

**Description**: Retrieve a specific traffic regulation.

**Path Parameters**:
- `{id}` (UUID) - Traffic regulation identifier

**Response** (HTTP 200): TrafficRegulationDto

---

#### POST /traffic-regulations/{id}

**Authentication**: NDW IAM

**Description**: Update a traffic regulation.

**Path Parameters**:
- `{id}` (UUID) - Traffic regulation identifier

**Request Body**: TrafficRegulationDto

**Response** (HTTP 200): TrafficRegulationDto

---

#### DELETE /traffic-regulations/{id}

**Authentication**: NDW IAM

**Description**: Delete a traffic regulation.

**Path Parameters**:
- `{id}` (UUID) - Traffic regulation identifier

**Response** (HTTP 200): OK

---

### Hazardous Substance Routes

#### POST /routes/hazardous-substances

**Authentication**: NDW IAM

**Description**: Create a new hazardous substance route.

**Request Body**: HazardousSubstanceRouteDto

**Example Request**:
```json
{
  "lineString": {
    "type": "LineString",
    "coordinates": [
      [5.1, 52.0],
      [5.2, 52.1],
      [5.3, 52.2]
    ]
  },
  "waypoints": {
    "type": "MultiPoint",
    "coordinates": [
      [5.1, 52.0],
      [5.3, 52.2]
    ]
  }
}
```

**Response** (HTTP 200): HazardousSubstanceRouteDto

---

#### GET /routes/hazardous-substances/{id}

**Authentication**: NDW IAM

**Description**: Retrieve a specific hazardous substance route.

**Path Parameters**:
- `{id}` (UUID) - Route identifier

**Response** (HTTP 200): HazardousSubstanceRouteDto

---

#### PUT /routes/hazardous-substances/{id}

**Authentication**: NDW IAM

**Description**: Update a hazardous substance route.

**Path Parameters**:
- `{id}` (UUID) - Route identifier

**Request Body**: HazardousSubstanceRouteDto

**Response** (HTTP 200): HazardousSubstanceRouteDto

---

#### DELETE /routes/hazardous-substances/{id}

**Authentication**: NDW IAM

**Description**: Delete a hazardous substance route.

**Path Parameters**:
- `{id}` (UUID) - Route identifier

**Response** (HTTP 200): OK

---

### Geographic Data

#### GET /areas

**Authentication**: NDW IAM

**Description**: Retrieve all geographic areas.

**Response** (HTTP 200): Array of AreaDto

---

#### POST /areas

**Authentication**: NDW IAM

**Description**: Create a new geographic area.

**Request Body**: AreaDto

**Response** (HTTP 200): AreaDto

---

#### GET /areas/{id}

**Authentication**: NDW IAM

**Description**: Retrieve a specific area.

**Path Parameters**:
- `{id}` (UUID) - Area identifier

**Response** (HTTP 200): AreaDto

---

#### POST /areas/{id}

**Authentication**: NDW IAM

**Description**: Update an area.

**Path Parameters**:
- `{id}` (UUID) - Area identifier

**Request Body**: AreaDto

**Response** (HTTP 200): AreaDto

---

#### DELETE /areas/{id}

**Authentication**: NDW IAM

**Description**: Delete an area.

**Path Parameters**:
- `{id}` (UUID) - Area identifier

**Response** (HTTP 200): OK

---

#### GET /counties

**Authentication**: NDW IAM

**Description**: Retrieve all counties.

**Response** (HTTP 200): Array of CountyDto

**Example Response**:
```json
[
  {
    "code": "0363",
    "gmCode": "GM0363",
    "name": "Utrecht",
    "localName": "Utrecht"
  }
]
```

---

#### GET /counties/{code}

**Authentication**: NDW IAM

**Description**: Retrieve a specific county by code.

**Path Parameters**:
- `{code}` (string) - County code (pattern: `^[1-9]\d{1,3}$`)

**Response** (HTTP 200): CountyDto

---

#### GET /towns

**Authentication**: NDW IAM

**Description**: Retrieve towns with optional filtering.

**Query Parameters**:
- `townName` (string, optional) - Filter by town name
- `municipalityName` (string, optional) - Filter by municipality name

**Response** (HTTP 200): Array of TownDto

**Example Response**:
```json
[
  {
    "code": "0363-001",
    "name": "Utrecht",
    "localName": "Utrecht",
    "county": {
      "code": "0363",
      "gmCode": "GM0363",
      "name": "Utrecht",
      "localName": "Utrecht"
    }
  }
]
```

---

### Map Features

#### GET /environmental-zones/map

**Authentication**: NDW IAM

**Description**: Retrieve all environmental zones as map features (GeoJSON).

**Response** (HTTP 200): FeatureCollection

**Notes**:
- Returns GeoJSON FeatureCollection format
- Suitable for displaying on maps

---

#### GET /emission-zones/map

**Authentication**: NDW IAM

**Description**: Retrieve all emission zones as map features (GeoJSON).

**Response** (HTTP 200): FeatureCollection

---

#### GET /parking-bans/map

**Authentication**: NDW IAM

**Description**: Retrieve all parking bans as map features (GeoJSON).

**Query Parameters**:
- `countyCode` (array of strings, optional) - Filter by one or more county codes

**Response** (HTTP 200): StreamingResponseBody (GeoJSON stream)

**Notes**:
- Streaming response for large datasets
- Content-Type: application/geo+json

---

#### GET /routes/hazardous-substances/map

**Authentication**: NDW IAM

**Description**: Retrieve all hazardous substance routes as map features.

**Response** (HTTP 200): FeatureCollection

---

### Coordinate Conversion

#### POST /conversion/wgs84

**Authentication**: NDW IAM

**Description**: Convert GeoJSON geometries to WGS84 coordinate system.

**Request Body**: GeoJSON object (Feature, FeatureCollection, or Geometry)

**Example Request**:
```json
{
  "type": "Point",
  "coordinates": [120000, 400000]
}
```

**Response** (HTTP 200): Converted GeoJSON object in WGS84

**Notes**:
- Accepts various GeoJSON types
- Returns same structure in WGS84 coordinates

---

### External API

#### GET /ibbm/emission-zones/v1

**Authentication**: NDW IAM

**Description**: Get emission zones in IBBM format.

**Response** (HTTP 200): String (JSON encoded)

**Notes**:
- IBBM (Integraal Bereikbaarheid en Bereik Mobiliteit) format
- External integration endpoint

---

## DATA TYPES (DTOs)

### EnvironmentalZoneDto

**Used in**: GET/POST `/environmental-zones`, GET/POST `/emission-zones`, `/zones/upload` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique zone identifier |
| `identification` | String | Yes | min 1 char | Zone identification/name |
| `zoneType` | Enum | Yes | ENVIRONMENTAL_ZONE, ZERO_EMISSION_ZONE | Type of zone |
| `validFrom` | DateTime | Yes | ISO 8601 | Start date of validity |
| `validTo` | DateTime | No | ISO 8601 | End date of validity |
| `regulationId` | String | Yes | Pattern: `^(gmb\|stcrt\|prb\|stb\|wsb\|bgr\|trb)-(19\|20)\d{2}-\d+$` | Government regulation reference |
| `trafficOrderStatus` | Enum | Yes | DEFINITIVE, PLANNED, REVOKED, SUBSTITUTED | Legal status of the zone |
| `area` | GeoJSON Geometry | Yes | Valid GeoJSON | Geographic boundary |
| `urlForInformation` | String | No | Valid URL | Information link |
| `taxiMaxRegistrationYear` | Integer | No | - | Maximum registration year for taxis (ZERO_EMISSION_ZONE) |
| `exemptions` | Array[CategoryExemptionDto] | No | - | Vehicle category exemptions |
| `county` | CountyDto | No | - | County information |
| `countyCode` | String | No | Pattern: `^[1-9]\d{1,3}$` | County code |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "identification": "Zone-A-001",
  "zoneType": "ENVIRONMENTAL_ZONE",
  "validFrom": "2025-01-01T00:00:00Z",
  "validTo": "2026-12-31T23:59:59Z",
  "regulationId": "gmb-2025-1234",
  "trafficOrderStatus": "DEFINITIVE",
  "area": {
    "type": "Polygon",
    "coordinates": [[...]]
  },
  "taxiMaxRegistrationYear": 2015,
  "exemptions": [
    {
      "vehicleType": "CAR",
      "classification": "EURO6"
    }
  ],
  "countyCode": "0363"
}
```

---

### ParkingBanDto

**Used in**: GET/POST `/parking-bans` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique parking ban identifier |
| `name` | String | Yes | min 1 char | Parking ban name |
| `validFrom` | DateTime | Yes | ISO 8601 | Start date of ban |
| `validTo` | DateTime | No | ISO 8601 | End date of ban |
| `remarks` | String | No | - | Additional remarks |
| `areas` | Array[AreaDto] | Yes | min 1 item | Geographic areas affected |
| `trafficRegulations` | Array[TrafficRegulationDto] | Yes | min 1 item | Associated regulations |
| `county` | CountyDto | No | - | County information |
| `countyCode` | String | No | - | County code |

---

### TrafficRegulationDto

**Used in**: GET/POST `/traffic-regulations` endpoints, ParkingBanDto

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique regulation identifier |
| `name` | String | Yes | min 1 char | Regulation name |
| `regulationId` | String | Yes | Pattern: `^(gmb\|stcrt\|prb\|stb\|wsb\|bgr\|trb)-(19\|20)\d{2}-\d+$` OR CVDR | Government regulation ID |
| `validFrom` | DateTime | Yes | ISO 8601 | Start date |
| `validTo` | DateTime | No | ISO 8601 | End date |
| `validityConditions` | Array[TrafficRegulationValidityConditionDto] | No | - | Time-based conditions |
| `county` | CountyDto | No | - | County information |
| `countyCode` | String | No | - | County code |

---

### TrafficRegulationValidityConditionDto

**Used in**: TrafficRegulationDto

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Condition identifier |
| `daysOfWeek` | Array[Integer] | No | 1-7 (Mon-Sun) | Days when regulation applies |
| `startTime` | String | No | HH:MM format | Start time of validity |
| `endTime` | String | No | HH:MM format | End time of validity |
| `isException` | Boolean | No | - | Whether this is an exception |

---

### HazardousSubstanceRouteDto

**Used in**: GET/POST `/routes/hazardous-substances` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique route identifier |
| `lineString` | GeoJSON LineString | Yes | Valid GeoJSON | Route path |
| `waypoints` | GeoJSON MultiPoint | Yes | Valid GeoJSON | Route waypoints |

---

### AreaDto

**Used in**: GET/POST `/areas` endpoints, ParkingBanDto

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique area identifier |
| `name` | String | Yes | min 1 char | Area name |
| `geometry` | GeoJSON Polygon | Yes | Valid Polygon GeoJSON | Area boundary |
| `county` | CountyDto | No | - | County information |
| `countyCode` | String | No | - | County code |

---

### CountyDto

**Used in**: GET `/counties` endpoints, EnvironmentalZoneDto, ParkingBanDto, etc.

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `code` | String | Yes | Pattern: `^[1-9]\d{1,3}$` | County code |
| `gmCode` | String | Yes | min 1 char | Municipality code |
| `name` | String | Yes | min 1 char | County name |
| `localName` | String | Yes | min 1 char | Local name |

---

### TownDto

**Used in**: GET `/towns` endpoint

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `code` | String | Yes | min 1 char | Town code |
| `name` | String | Yes | min 1 char | Official town name |
| `localName` | String | Yes | min 1 char | Local town name |
| `county` | CountyDto | Yes | - | Parent county |

---

### CategoryExemptionDto

**Used in**: EnvironmentalZoneDto

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `vehicleType` | Enum | Yes | CAR, VAN, TRUCK, BUS | Type of vehicle |
| `classification` | Enum | Yes | EURO1-EURO6 | Emission classification |

---

## ENUMS

### ZoneType

**Used in**: EnvironmentalZoneDto

| Value | Description |
|-------|-------------|
| ENVIRONMENTAL_ZONE | Standard environmental zone (emission restrictions) |
| ZERO_EMISSION_ZONE | Zero emission zone (stricter requirements) |

---

### TrafficOrderStatus

**Used in**: EnvironmentalZoneDto

| Value | Description |
|-------|-------------|
| DEFINITIVE | Zone is active and official |
| PLANNED | Zone is planned but not yet active |
| REVOKED | Zone has been revoked/cancelled |
| SUBSTITUTED | Zone has been replaced by another |

---

### VehicleType

**Used in**: CategoryExemptionDto

| Value | Description |
|-------|-------------|
| CAR | Passenger cars |
| VAN | Light commercial vehicles (vans) |
| TRUCK | Heavy goods vehicles (trucks) |
| BUS | Buses and public transport |

---

### EmissionClassification

**Used in**: CategoryExemptionDto

| Value | Description |
|-------|-------------|
| EURO1 | Euro 1 emission standard |
| EURO2 | Euro 2 emission standard |
| EURO3 | Euro 3 emission standard |
| EURO4 | Euro 4 emission standard |
| EURO5 | Euro 5 emission standard |
| EURO6 | Euro 6 emission standard (cleanest) |

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api/area`
**Security Scheme**: OAuth2 (NDW IAM)

### Required Roles by Feature

| Feature | Required Role | Description |
|---------|---------------|-------------|
| Read Zones/Areas | NDW IAM | Authenticated access |
| Create/Modify Zones | NDW IAM | Authenticated access |
| Upload Zones | NDW IAM | Authenticated access |
| Map Features | NDW IAM | Authenticated access |

### Authentication Details

- **Provider**: NDW IAM (Keycloak)
- **Authorization URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/auth`
- **Token URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`
- **Refresh URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`

> **Note**: All endpoints require valid NDW IAM authentication. No public/anonymous access endpoints in this API.

---

## GEO-SPATIAL OPERATIONS

### Coordinate Systems

This API works with multiple coordinate systems:
- **WGS84**: Standard geographic coordinates (latitude/longitude) - Primary format
- **RD (Rijksdriehoeksstelsel)**: Dutch national coordinate system

The `/conversion/wgs84` endpoint can convert between systems.

### GeoJSON Support

API accepts and returns standard GeoJSON format for all geographic data:
- **Feature**: Single geographic feature with properties
- **FeatureCollection**: Collection of features
- **Geometries**: Point, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon

### Map Endpoints

Several endpoints return map-optimized responses:
- `/environmental-zones/map` - FeatureCollection (fast response)
- `/emission-zones/map` - FeatureCollection
- `/parking-bans/map` - Streaming response (handles large datasets)
- `/routes/hazardous-substances/map` - FeatureCollection

---

## COMMON PATTERNS

### Filtering and Querying

- **By county**: Many endpoints support `countyCode` parameter
- **By zone type**: Environmental/emission zone endpoints support filtering
- **By regulation**: Most endpoints support `regulationId` filtering
- **By name**: Towns and areas support name-based search

### File Upload

Endpoints supporting bulk operations:
- `/environmental-zones/upload` - Upload GeoJSON feature collection
- `/emission-zones/upload` - Upload emission zone features
- Accepts file as multipart form-data

### Streaming Responses

Large dataset endpoints use streaming:
- `/parking-bans/map` - Returns `StreamingResponseBody` for performance
- Content-Type: `application/geo+json`

---
