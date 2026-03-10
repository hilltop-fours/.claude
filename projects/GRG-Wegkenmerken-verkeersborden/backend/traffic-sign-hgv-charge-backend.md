# Traffic Sign HGV Charge Backend - API Reference

Complete reference for the traffic-sign-hgv-charge-backend API. This service manages HGV (Heavy Goods Vehicle) charge data and provides access to road charging information for heavy vehicles, such as tolls and congestion charging systems.

---

## COMMIT TRACKING

| Item | Value | Date |
|------|-------|------|
| Last Verified Commit | 8497e35 | 2026-03-10 |
| Commit Message | Feature #110189 JDK25 compatibility (no API changes) | |
| Swagger Version | latest | 2026-03-10 |

**Status**: ✓ Up to date as of 2026-03-10
**Next Review**: Check commits after 8497e35

---

## QUICK REFERENCE BY FEATURE

| Feature | Main Endpoints | HTTP Methods | Auth Required | Purpose |
|---------|----------------|--------------|---------------|----|
| **HGV Charge Mutations** | `/mutations/{version}` | GET | NDW IAM | Export HGV charge data for a specific version |

---

## DETAILED ENDPOINTS

### HGV Charge Mutations

#### GET /mutations/{version}

**Authentication**: NDW IAM

**Description**: Export HGV (Heavy Goods Vehicle) charge mutations for a specific version. Returns tab-separated values format containing road charging information for heavy vehicles.

**Path Parameters**:
- `{version}` (date, YYYY-MM-DD) - Data version (e.g., 2025-10-01)

**Query Parameters**: None

**Response** (HTTP 200): StreamingResponseBody (tab-separated values)

**Response Content-Type**: `text/tab-separated-values`

**Example Response Format**:
```
roadSectionId	chargingType	amount	currency	validFrom	validTo
12345	CONGESTION_CHARGE	5.00	EUR	2025-01-01	2025-12-31
12346	TOLL	10.50	EUR	2025-01-01	2025-12-31
12347	ENVIRONMENTAL_CHARGE	2.75	EUR	2025-01-01	2025-12-31
```

**Possible Status Codes**:
- 200 OK - Charge data exported successfully
- 400 Bad Request - Invalid version format
- 401 Unauthorized - Missing/invalid auth
- 404 Not Found - Version not found

**Notes**:
- Returns data as tab-separated values (TSV) for easy import into spreadsheets/databases
- Version format is YYYY-MM-DD (e.g., 2025-10-01)
- Response is a streaming body suitable for large datasets
- Useful for batch exports of HGV charging information
- Data includes all road sections with active charging during the version period

---

## DATA TYPES

### StreamingResponseBody

**Used in**: GET `/mutations/{version}` response

This is a streaming response body that returns tab-separated values. The actual structure depends on the HGV charge data schema, which typically includes:

| Field | Type | Description |
|-------|------|-------------|
| roadSectionId | Integer | NWB road section identifier |
| chargingType | String | Type of charge (TOLL, CONGESTION_CHARGE, ENVIRONMENTAL_CHARGE, etc.) |
| amount | Decimal | Charge amount |
| currency | String | Currency code (EUR, etc.) |
| validFrom | Date | Start date of validity |
| validTo | Date | End date of validity |

> **Note**: The exact TSV schema depends on the backend implementation. Refer to actual export files for precise field ordering and complete field list.

---

## AUTHENTICATION & AUTHORIZATION

**Base URL**: `https://wegkenmerken.staging.ndw.nu/api/hgv-charge`
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

### HGV Charging

HGV (Heavy Goods Vehicle) charging refers to tolls and fees applied to heavy vehicles on specific road sections. This can include:

- **Road Tolls**: Fixed or distance-based charges for using specific roads
- **Congestion Charges**: Fees for entering congested areas during peak times
- **Environmental Charges**: Eco-based charges based on vehicle emissions
- **Weight-Based Charges**: Fees based on vehicle weight or axle load

### Version Management

All HGV charge data is version-specific, identified by date (YYYY-MM-DD format):

- Example: `2025-10-01` represents HGV charge data as of October 1, 2025
- Different versions may reflect:
  - Updated charge amounts
  - New charging zones
  - Changes in charging rules
  - Policy updates

### Tab-Separated Values Format

The export uses TSV (Tab-Separated Values) format for:
- Easy parsing and import into databases
- Direct use in spreadsheet applications
- Simple text-based data exchange
- Large-scale data processing

---

## COMMON USE CASES

### Export HGV Charges for Analysis

Operator needs current HGV charging data for analysis:
```
GET /mutations/2025-10-01
```

Response provides all active HGV charges for that version, useful for:
- Route planning optimization
- Cost analysis for logistics companies
- Infrastructure planning
- Revenue forecasting

### Update Database with Latest Charges

System needs to update local HGV charge database:
1. Query `/mutations/{current-version}`
2. Compare with previously stored version
3. Import changes into local system
4. Update routing and cost calculation engines

### Integration with Vehicle Management Systems

Logistics company integrates HGV charge data:
- Fetch charges for multiple road versions
- Calculate tolls for planned routes
- Estimate delivery costs
- Provide customer billing information

---

## TYPICAL WORKFLOW

1. **Identify Required Version**
   - Determine which date version is needed
   - Format as YYYY-MM-DD

2. **Request Export**
   ```
   GET /mutations/2025-10-01
   ```

3. **Receive TSV Data**
   - Response is tab-separated values
   - Contains all HGV charges for that version

4. **Process Data**
   - Parse TSV format
   - Import into local system
   - Update calculations/mappings

5. **Use in Application**
   - Route planning
   - Cost calculation
   - Billing systems
   - User information

---

## INTEGRATION WITH OTHER SERVICES

### Traffic Sign Backend

- HGV restrictions relate to vehicle access restrictions
- May be used alongside WKD (vehicle access) data

### WKD Backend

- HGV charges complement vehicle access restrictions
- Together provide comprehensive HGV data

### Area Backend

- Charging zones may align with geographic areas
- Environmental charges related to zone type

---

## API CHARACTERISTICS

### Minimal API

This backend has a very focused scope:
- **Single endpoint** for data export
- **One operation** - retrieving mutations by version
- **Simple response** - TSV format

### Export-Focused

- Read-only access (GET only)
- Designed for data extraction
- Streaming response for large datasets
- Batch processing friendly

### Version-Based

- All data tied to specific versions
- Easy to manage different time periods
- Clear versioning for auditing

---

## NOTES

- **TSV Format**: Data is returned as tab-separated values, suitable for direct import into databases or spreadsheets
- **Streaming Response**: Large datasets are streamed to minimize memory usage
- **Version Format**: Must use YYYY-MM-DD format (e.g., 2025-10-01)
- **Single Purpose**: This backend focuses solely on HGV charge data export
- **Read-Only**: No create, update, or delete operations available through API
- **Data Volume**: Response size depends on the number of road sections with active charges

---
