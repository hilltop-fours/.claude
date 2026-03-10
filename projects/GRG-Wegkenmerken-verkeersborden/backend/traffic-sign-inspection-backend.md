# Traffic Sign Inspection Backend - API Reference

Complete reference for the traffic-sign-inspection-backend API. This service handles automated inspections of traffic signs, validating them against various criteria (WKD restrictions, road sections, NLS data, etc.) and processes user feedback.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | f16ddce | 2026-03-10 |
| Commit Message | Feature #110189 JDK25 compatibility (no API changes) | |
| Swagger Version | latest | 2026-03-10 |

**Status**: ✓ Up to date as of 2026-03-10
**Next Review**: Check commits after f16ddce

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required | Purpose |
|---------|----------------|--------------|---------------|----|
| **WKD Width Inspections** | `/jobs/inspections/wkd/width` | POST | NDW IAM | Check width restrictions against traffic signs |
| **WKD Speed Inspections** | `/jobs/inspections/wkd/speed` | POST | NDW IAM | Check speed limit restrictions |
| **WKD Load Inspections** | `/jobs/inspections/wkd/load` | POST | NDW IAM | Check load restrictions |
| **WKD Length Inspections** | `/jobs/inspections/wkd/length` | POST | NDW IAM | Check length restrictions |
| **WKD Height Inspections** | `/jobs/inspections/wkd/height` | POST | NDW IAM | Check height restrictions |
| **WKD Axle Load Inspections** | `/jobs/inspections/wkd/axle-load` | POST | NDW IAM | Check axle load restrictions |
| **Unknown Traffic Orders** | `/jobs/inspections/unknown-traffic-orders` | POST | NDW IAM | Identify traffic signs with invalid traffic orders |
| **Road Section Validation** | `/jobs/inspections/road-sections` | POST | NDW IAM | Validate traffic signs against road section data |
| **NLS Data Issues** | `/jobs/inspections/nls-issues` | POST | NDW IAM | Find traffic signs with NLS (national database) mismatches |
| **Missing Direction Info** | `/jobs/inspections/missing-direction` | POST | NDW IAM | Find traffic signs without driving direction |
| **Invalid Black Codes** | `/jobs/inspections/invalid-black-codes` | POST | NDW IAM | Find traffic signs with incorrect black codes |
| **User Feedback** | `/feedback` | POST | NDW IAM | Submit user feedback about traffic signs |

---

## DETAILED ENDPOINTS

### Inspection Jobs - WKD Restrictions

These endpoints run batch inspection jobs that validate traffic signs against Vehicle Access Restrictions (WKD - Wegverkeerswet). Each inspection type runs asynchronously and returns a job ID.

#### POST /jobs/inspections/wkd/width

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to inspect and validate width restrictions on traffic signs against WKD data.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Example Response**:
```
"job-uuid-1234-5678-9012-3456"
```

**Possible Status Codes**:
- 200 OK - Inspection job started
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Runs asynchronously - returns immediately with job ID
- Job validates each traffic sign's width restrictions
- Creates findings for mismatches
- Use job ID to track progress

---

#### POST /jobs/inspections/wkd/speed

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to inspect and validate speed limit restrictions on traffic signs.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates speed restriction values
- Compares against WKD data
- Creates WKD_INCONSISTENCY_SPEED findings for mismatches

---

#### POST /jobs/inspections/wkd/load

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to inspect and validate load restrictions on traffic signs.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates load restriction values
- Checks against WKD reference data
- Creates WKD_INCONSISTENCY_LOAD findings for mismatches

---

#### POST /jobs/inspections/wkd/length

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to inspect and validate length restrictions on traffic signs.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates length restriction values
- Compares against WKD data
- Creates WKD_INCONSISTENCY_LENGTH findings for mismatches

---

#### POST /jobs/inspections/wkd/height

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to inspect and validate height restrictions on traffic signs.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates height restriction values
- Checks against WKD reference data
- Creates WKD_INCONSISTENCY_HEIGHT findings for mismatches

---

#### POST /jobs/inspections/wkd/axle-load

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to inspect and validate axle load restrictions on traffic signs.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates axle load restriction values
- Compares against WKD data
- Creates WKD_INCONSISTENCY_AXLE_LOAD findings for mismatches

---

### Inspection Jobs - Data Validation

#### POST /jobs/inspections/unknown-traffic-orders

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to find traffic signs with unknown or invalid traffic orders.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Possible Status Codes**:
- 200 OK - Inspection job started
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- Identifies traffic signs referencing non-existent traffic orders
- Creates UNKNOWN_TRAFFIC_ORDER findings
- Helps maintain data integrity

---

#### POST /jobs/inspections/road-sections

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to validate traffic signs against road section data.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates road section references
- Checks if road sections still exist
- Creates NO_ROAD_SECTION findings for invalid references
- Essential for location-based queries

---

#### POST /jobs/inspections/nls-issues

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to find traffic signs with NLS (national traffic sign database) data inconsistencies.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Compares against NLS reference data
- Identifies missing counterparts in NLS
- Creates NO_COUNTERPART findings
- Validates against official national database

---

#### POST /jobs/inspections/missing-direction

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to find traffic signs without driving direction information.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Identifies signs missing direction data
- Creates NO_DIRECTION findings
- Direction is important for some traffic sign types
- Helps ensure complete location information

---

#### POST /jobs/inspections/invalid-black-codes

**Authentication**: NDW IAM

**Description**: Start an asynchronous job to find traffic signs with invalid or mismatched black codes.

**Request Body**: None (empty POST)

**Response** (HTTP 200): Job ID (string)

**Notes**:
- Validates black code format and values
- Checks black code against RVV code
- Creates INVALID_BLACK_CODE findings for mismatches
- Black codes are internal identification codes

---

### User Feedback

#### POST /feedback

**Authentication**: NDW IAM

**Description**: Submit user feedback about a specific traffic sign. Can include optional captcha for anonymous/public submissions.

**Request Body**: FeedbackRequestDto

**Example Request**:
```json
{
  "trafficSignId": "550e8400-e29b-41d4-a716-446655440000",
  "feedback": "This traffic sign is missing from the location",
  "captcha": "captcha-token-if-required"
}
```

**Response** (HTTP 200): OK (no response body)

**Possible Status Codes**:
- 200 OK - Feedback submitted successfully
- 400 Bad Request - Invalid feedback data
- 401 Unauthorized - Missing/invalid auth

**Notes**:
- `feedback` field is required (10-255 characters)
- `trafficSignId` is required and must be valid UUID
- `captcha` is optional (for public/anonymous submissions)
- Creates FEEDBACK finding in the system
- Submitted feedback is reviewed by administrators

---

## DATA TYPES (DTOs)

### FeedbackRequestDto

**Used in**: POST `/feedback` endpoint

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `trafficSignId` | UUID | Yes | Valid UUID | Identifier of the traffic sign being reported |
| `feedback` | String | No | 10-255 chars | User feedback message |
| `captcha` | String | No | - | Captcha token for verification |

**Example**:
```json
{
  "trafficSignId": "550e8400-e29b-41d4-a716-446655440000",
  "feedback": "This sign is no longer present at this location, it should be removed",
  "captcha": "03AOLTBLQt-abc123..."
}
```

**Validation Notes**:
- Only trafficSignId is strictly required in request body
- Feedback text minimum 10 characters is enforced when provided
- Maximum 255 characters for feedback message
- Captcha token format depends on implementation

---

## INSPECTION JOB PATTERNS

### Asynchronous Job Execution

All inspection endpoints (`/jobs/inspections/*`) follow the same pattern:

1. **Request**: Empty POST to trigger inspection
2. **Response**: Immediate return with job ID (string)
3. **Execution**: Job runs asynchronously in background
4. **Results**: Creates findings in traffic-sign-backend for mismatches

### Job ID Usage

When an inspection job is started:
- Returns a job identifier immediately
- Job runs in background, checking all relevant traffic signs
- Results are stored as findings in the system
- Findings can be queried from traffic-sign-backend `/findings` endpoint

### Finding Types Created

Each inspection type creates specific finding types:

| Inspection Type | Finding Reason Created |
|-----------------|----------------------|
| WKD Width | WKD_INCONSISTENCY_WIDTH |
| WKD Speed | WKD_INCONSISTENCY_SPEED |
| WKD Load | WKD_INCONSISTENCY_LOAD |
| WKD Length | WKD_INCONSISTENCY_LENGTH |
| WKD Height | WKD_INCONSISTENCY_HEIGHT |
| WKD Axle Load | WKD_INCONSISTENCY_AXLE_LOAD |
| Unknown Traffic Orders | UNKNOWN_TRAFFIC_ORDER |
| Road Sections | NO_ROAD_SECTION |
| NLS Issues | NO_COUNTERPART |
| Missing Direction | NO_DIRECTION |
| Invalid Black Codes | INVALID_BLACK_CODE |
| User Feedback | FEEDBACK |

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api/inspection`
**Security Scheme**: OAuth2 (NDW IAM)

### Required Authentication

| Feature | Required | Scope |
|---------|----------|-------|
| All inspection jobs | NDW IAM | Administrative/automated task |
| User feedback submission | NDW IAM | User/frontend authentication |

### Authentication Details

- **Provider**: NDW IAM (Keycloak)
- **Authorization URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/auth`
- **Token URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`
- **Refresh URL**: `https://iam.ndw.nu/auth/realms/ndw/protocol/openid-connect/token`

> **Note**: All endpoints require valid NDW IAM authentication. Inspection jobs are typically run by backend administrators or scheduled tasks.

---

## INSPECTION WORKFLOWS

### Typical Inspection Workflow

1. **Trigger Inspection Job**
   - POST to `/jobs/inspections/{type}`
   - Receive job ID immediately
   - Job executes asynchronously

2. **Processing**
   - Service iterates through all traffic signs
   - Validates each sign against criteria
   - Creates findings for mismatches

3. **View Results**
   - Query `/findings` endpoint in traffic-sign-backend
   - Filter by finding reason (e.g., WKD_INCONSISTENCY_WIDTH)
   - Review and resolve findings

### User Feedback Workflow

1. **User Submits Feedback**
   - POST to `/feedback` with traffic sign ID and message
   - Optional captcha for public submissions

2. **Feedback Processing**
   - Creates FEEDBACK finding in system
   - Associated with specific traffic sign
   - Marked for review by administrators

3. **Resolution**
   - Administrator reviews feedback
   - Updates traffic sign data or closes finding
   - User notification (if logged in)

---

## INTEGRATION WITH TRAFFIC-SIGN-BACKEND

This service works closely with traffic-sign-backend:

- **Findings API**: Creates findings via traffic-sign-backend POST `/findings`
- **Traffic Signs**: References traffic signs by ID from traffic-sign-backend
- **Findings Query**: Results can be queried from traffic-sign-backend GET `/findings`
- **Status Updates**: Updates finding status via traffic-sign-backend PUT `/findings/{id}/status`

See traffic-sign-backend documentation for details on findings management.

---

## COMMON USE CASES

### Data Quality Assurance

Run inspections periodically to maintain data quality:
1. Run all WKD restriction inspections (width, speed, load, length, height, axle-load)
2. Run data validation inspections (road sections, NLS issues, traffic orders)
3. Review and resolve created findings
4. Track quality metrics over time

### Bulk Finding Generation

Start multiple inspections to generate comprehensive findings:
```
POST /jobs/inspections/invalid-black-codes
POST /jobs/inspections/missing-direction
POST /jobs/inspections/unknown-traffic-orders
```

### User Feedback Collection

Allow frontend users to report issues:
1. Frontend displays traffic sign details
2. User submits feedback via POST `/feedback`
3. Creates FEEDBACK finding for administrative review
4. System tracks user-reported issues

---
