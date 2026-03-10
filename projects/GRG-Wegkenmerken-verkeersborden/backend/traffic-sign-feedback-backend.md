# Traffic Sign Feedback Backend - API Reference

Complete reference for the traffic-sign-feedback-backend API. This service manages user corrections and feedback about road features, allowing users to report issues with road sections, WKD (vehicle access restrictions), and other geographic features through a location-based feedback system.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | 8f57066 | 2026-03-10 |
| Commit Message | Feature #110189 JDK25 compatibility (no API changes) | |
| Swagger Version | latest | 2026-03-10 |

**Status**: ✓ Up to date as of 2026-03-10
**Next Review**: Check commits after 8f57066

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required | Purpose |
|---------|----------------|--------------|---------------|----|
| **User Corrections** | `/corrections` | GET, POST | NDW IAM | Submit and retrieve user corrections/feedback |
| **Correction Map Features** | `/corrections/map` | GET | NDW IAM | Get all corrections as GeoJSON for map display |

---

## DETAILED ENDPOINTS

### Corrections Management

#### GET /corrections

**Authentication**: NDW IAM

**Description**: Retrieve all user corrections and feedback about road features.

**Query Parameters**: None

**Response** (HTTP 200): Array of CorrectionDto

**Example Response**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "location": {
      "type": "Point",
      "coordinates": [5.1204, 52.0704]
    },
    "category": "ROAD_SECTION_MUST_BE_CHANGED",
    "text": "This road section needs to be updated due to recent construction",
    "createdOn": "2026-01-30T10:30:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "location": {
      "type": "Point",
      "coordinates": [5.1305, 52.0805]
    },
    "category": "CANNOT_ENTER_WKD",
    "text": "Vehicle access restriction is incorrect on this road",
    "createdOn": "2026-01-29T14:15:00Z"
  }
]
```

**Possible Status Codes**:
- 200 OK - Corrections retrieved successfully
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Returns all corrections regardless of status or date
- May return large datasets - consider using map endpoint for display
- Each correction includes geographic location and category

---

#### POST /corrections

**Authentication**: NDW IAM

**Description**: Submit a new correction or feedback about a road feature or restriction.

**Request Body**: CorrectionDto

**Example Request**:
```json
{
  "location": {
    "type": "Point",
    "coordinates": [5.1204, 52.0704]
  },
  "category": "ROAD_SECTION_MUST_BE_CHANGED",
  "text": "The road section boundaries need adjustment"
}
```

**Response** (HTTP 200): Feature (GeoJSON)

**Example Response**:
```json
{
  "type": "Feature",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "geometry": {
    "type": "Point",
    "coordinates": [5.1204, 52.0704]
  },
  "properties": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "category": "ROAD_SECTION_MUST_BE_CHANGED",
    "text": "The road section boundaries need adjustment",
    "createdOn": "2026-01-30T10:30:00Z"
  }
}
```

**Possible Status Codes**:
- 200 OK - Correction created successfully
- 400 Bad Request - Invalid correction data (missing required fields)
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Location must be valid GeoJSON Point (longitude, latitude)
- Category is required and must be one of the defined enum values
- Text field is required (minimum 1 character)
- Response includes the created correction as GeoJSON Feature
- Each correction receives a unique UUID identifier

---

### Map Features

#### GET /corrections/map

**Authentication**: NDW IAM

**Description**: Retrieve all corrections as a GeoJSON FeatureCollection for map visualization.

**Query Parameters**: None

**Response** (HTTP 200): FeatureCollection

**Example Response**:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "geometry": {
        "type": "Point",
        "coordinates": [5.1204, 52.0704]
      },
      "properties": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "category": "ROAD_SECTION_MUST_BE_CHANGED",
        "text": "The road section boundaries need adjustment",
        "createdOn": "2026-01-30T10:30:00Z"
      }
    },
    {
      "type": "Feature",
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "geometry": {
        "type": "Point",
        "coordinates": [5.1305, 52.0805]
      },
      "properties": {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "category": "CANNOT_ENTER_WKD",
        "text": "Vehicle access restriction is incorrect",
        "createdOn": "2026-01-29T14:15:00Z"
      }
    }
  ]
}
```

**Possible Status Codes**:
- 200 OK - Map features retrieved
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Returns all corrections in GeoJSON FeatureCollection format
- Optimized for map display and visualization
- Each feature is a Point at the correction location
- Properties include all correction metadata
- Suitable for use with mapping libraries (Leaflet, MapBox, etc.)

---

## DATA TYPES (DTOs)

### CorrectionDto

**Used in**: GET/POST `/corrections` endpoints

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `id` | UUID | Yes (response) | - | Unique correction identifier |
| `location` | Point (GeoJSON) | Yes | Valid GeoJSON Point | Geographic location of the issue |
| `category` | Enum | Yes | ROAD_SECTION_MUST_BE_CHANGED, ROAD_SECTION_DOES_NOT_EXIST, CANNOT_ENTER_WKD, NOT_SPECIFIED | Type of correction/feedback |
| `text` | String | Yes | min 1 char | Description of the issue or feedback |
| `createdOn` | DateTime | Yes (response) | ISO 8601 | Creation timestamp |

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "location": {
    "type": "Point",
    "coordinates": [5.1204, 52.0704]
  },
  "category": "ROAD_SECTION_MUST_BE_CHANGED",
  "text": "This road section boundaries need adjustment due to recent highway construction",
  "createdOn": "2026-01-30T10:30:00Z"
}
```

**Validation Notes**:
- `location` must be a valid GeoJSON Point object
- Coordinates must be [longitude, latitude] (not reversed)
- `category` must match one of the defined enum values
- `text` is required and cannot be empty
- `createdOn` is automatically generated on POST (do not include in request)

---

## ENUMS

### CorrectionCategory

**Used in**: CorrectionDto

| Value | Description |
|-------|-------------|
| ROAD_SECTION_MUST_BE_CHANGED | The road section data needs to be updated or modified |
| ROAD_SECTION_DOES_NOT_EXIST | The reported road section is no longer valid or does not exist |
| CANNOT_ENTER_WKD | Vehicle access restriction (WKD) information is incorrect |
| NOT_SPECIFIED | Other feedback or correction (generic/uncategorized) |

**Usage Notes**:
- Use ROAD_SECTION_MUST_BE_CHANGED when the current road section data is inaccurate
- Use ROAD_SECTION_DOES_NOT_EXIST when reporting a road that has been removed or shouldn't exist
- Use CANNOT_ENTER_WKD for issues related to vehicle access restrictions (height, weight, speed, etc.)
- Use NOT_SPECIFIED for feedback that doesn't fit other categories

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api/feedback`
**Security Scheme**: OAuth2 (NDW IAM)

### Required Authentication

All endpoints require valid NDW IAM authentication.

### Authentication Details

- **Provider**: NDW IAM (Keycloak)
- **Authorization URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/auth`
- **Token URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`
- **Refresh URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`

---

## GEO-SPATIAL OPERATIONS

### GeoJSON Support

The feedback backend works exclusively with GeoJSON Point geometry for correction locations:

- **Feature**: Single correction as GeoJSON Feature
- **FeatureCollection**: All corrections as GeoJSON FeatureCollection
- **Point**: Individual correction location (required for submission)

### Coordinate System

- **CRS**: WGS84 (EPSG:4326) - Standard geographic coordinates
- **Format**: [longitude, latitude] - Note: longitude first!
- **Precision**: Full floating-point precision supported

### Map Integration

The `/corrections/map` endpoint provides FeatureCollection output ideal for:
- Leaflet.js mapping library
- MapBox GL
- GeoJSON viewers
- GIS applications
- Web-based mapping displays

---

## TYPICAL WORKFLOWS

### Submitting User Feedback

1. **User identifies issue on map**
   - Clicks location or uses address search
   - Gets coordinates [lon, lat]

2. **User selects category**
   - Chooses from: ROAD_SECTION_MUST_BE_CHANGED, ROAD_SECTION_DOES_NOT_EXIST, CANNOT_ENTER_WKD, or NOT_SPECIFIED

3. **User writes description**
   - Describes the issue (minimum 1 character)

4. **Submit correction**
   ```
   POST /corrections
   {
     "location": {"type": "Point", "coordinates": [5.1204, 52.0704]},
     "category": "ROAD_SECTION_MUST_BE_CHANGED",
     "text": "The road section needs updating"
   }
   ```

5. **Receive confirmation**
   - Response includes created correction with ID and timestamp
   - Correction is now in system for review

### Viewing All Corrections

1. **Retrieve all corrections**
   ```
   GET /corrections
   ```

2. **Get map-optimized view**
   ```
   GET /corrections/map
   ```

3. **Display on map or in table**
   - Use GeoJSON FeatureCollection for map rendering
   - Array response for list views

### Administrative Review

1. **Fetch all corrections periodically**
2. **Review by category to identify patterns**
3. **Take action based on feedback type**:
   - **ROAD_SECTION_MUST_BE_CHANGED**: Update road section data
   - **ROAD_SECTION_DOES_NOT_EXIST**: Delete/archive road section
   - **CANNOT_ENTER_WKD**: Review and correct WKD restrictions
   - **NOT_SPECIFIED**: Manual review needed

---

## INTEGRATION WITH OTHER SERVICES

### Traffic Sign Backend

- Corrections can reference traffic sign issues
- May trigger creation of findings/issues in traffic-sign-backend

### WKD Backend

- CANNOT_ENTER_WKD corrections relate to vehicle access restrictions
- May indicate WKD data inaccuracies requiring backend updates

### Area Backend

- Road section corrections may affect area-based data
- Potentially triggers updates to area management

---

## COMMON USE CASES

### User Reports Road Closure

User discovers a road has been closed due to construction:
- Category: ROAD_SECTION_DOES_NOT_EXIST
- Text: "Highway A12 north exit closed due to construction until March 2026"
- Location: Exact coordinates of the closure

### Height Restriction Issue

Driver reports incorrect height restriction sign:
- Category: CANNOT_ENTER_WKD
- Text: "Height restriction shows 3.5m but actual sign shows 3.2m"
- Location: Coordinates of the traffic sign

### Boundary Correction

Surveyor identifies outdated road boundaries:
- Category: ROAD_SECTION_MUST_BE_CHANGED
- Text: "Road section boundary shifted 50m west due to new construction"
- Location: Coordinates of the boundary discrepancy

### General Feedback

Public provides non-specific feedback:
- Category: NOT_SPECIFIED
- Text: "This area needs updated mapping"
- Location: General area coordinates

---

## NOTES

- **Minimal API**: This backend has a very focused scope - corrections only
- **Location-Based**: All feedback is tied to specific geographic coordinates
- **GeoJSON Native**: Designed for map-based workflows and visualization
- **Stateless**: Corrections are created and retrieved, but not updated or deleted via API
- **User Feedback Loop**: Part of larger data quality assurance process for road features

---
