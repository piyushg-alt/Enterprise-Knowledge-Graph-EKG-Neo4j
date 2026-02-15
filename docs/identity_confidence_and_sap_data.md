# Identity Confidence Percentage & SAP Data Points
## Enterprise Knowledge Graph (EKG) - Predictive Access Analytics

---

## Table of Contents

1. [Overview](#overview)
2. [Identity Confidence Percentage](#identity-confidence-percentage)
3. [Scoring Criteria & Weights](#scoring-criteria--weights)
4. [Cypher Queries for Confidence Calculation](#cypher-queries-for-confidence-calculation)
5. [Predictive Role Recommendations](#predictive-role-recommendations)
6. [SAP Data Points Required](#sap-data-points-required)
7. [Data Extraction Methods](#data-extraction-methods)
8. [Data Mapping to Graph Nodes](#data-mapping-to-graph-nodes)

---

## Overview

This document defines the methodology for calculating **Identity Confidence Percentage** - a score that determines how likely a user should have a specific role or access based on their identity attributes, organizational context, and peer analysis. It also documents all **SAP data points** required to build the knowledge graph.

### Key Objectives

1. **Predictive Access**: Recommend appropriate roles based on user attributes
2. **Anomaly Detection**: Identify users with roles that don't match their profile
3. **Auto-Approval**: Enable automatic approval for high-confidence role assignments
4. **Risk Scoring**: Calculate risk scores for access requests

---

## Identity Confidence Percentage

### Definition

The Identity Confidence Percentage is a calculated score (0-100%) that indicates how well a user's identity attributes align with a specific role assignment. Higher scores indicate stronger alignment and lower risk.

### Formula

```
Identity Confidence % = Σ (Criterion Weight × Criterion Score) / Total Weight × 100
```

### Score Interpretation

| Score Range | Confidence Level | Recommended Action |
|-------------|------------------|-------------------|
| **90-100%** | HIGH | Auto-approve role assignment |
| **70-89%** | MEDIUM | Standard approval workflow |
| **50-69%** | LOW | Enhanced review required |
| **Below 50%** | ANOMALY | Flag for investigation |

---

## Scoring Criteria & Weights

### Criteria Breakdown

| # | Criterion | Weight | Description | Data Source |
|---|-----------|--------|-------------|-------------|
| 1 | **Function Match** | 30% | User's function matches role's intended function | SuccessFactors, Entra ID |
| 2 | **Country/Entity Match** | 20% | User's country matches role's country derivation | SuccessFactors, SAP |
| 3 | **Org Level Match** | 15% | User's org level (L1-L4) matches role's typical level | SuccessFactors |
| 4 | **Department Match** | 10% | User's department aligns with role's module | SuccessFactors, Entra ID |
| 5 | **Peer Analysis** | 15% | % of peers with same function/level who have this role | Graph Analysis |
| 6 | **Historical Usage** | 10% | User's actual usage of transactions in the role | SAP Usage Logs |

### Detailed Scoring Logic

#### 1. Function Match (30%)

| Scenario | Score |
|----------|-------|
| User function exactly matches role module (e.g., Finance user → Finance role) | 100 |
| User function partially matches (e.g., Finance user → P2P role) | 50 |
| No match between user function and role module | 0 |

**Function to Module Mapping:**
| User Function | Matching Role Modules |
|---------------|----------------------|
| Finance | FIN, P2P |
| Sales & Marketing | S&D |
| Manufacturing | DFE |
| Procurement & Supply Chain | P2P |

#### 2. Country/Entity Match (20%)

| Scenario | Score |
|----------|-------|
| User country code matches role's derived country code | 100 |
| Role is a master role (no country derivation) | 50 |
| User country does not match role's country | 0 |

**Country Code Mapping:**
| Entity Code | ISO Code | Country |
|-------------|----------|---------|
| 1000 | UK | United Kingdom |
| 2000 | US | United States |
| 3000 | AE | United Arab Emirates |
| 4000 | DE | Germany |
| 5000 | IN | India |
| 6000 | RU | Russia |
| 7000 | CN | China |
| 8000 | AU | Australia |
| 9000 | SG | Singapore |
| A000 | ZA | South Africa |
| B000 | KZ | Kazakhstan |

#### 3. Org Level Match (15%)

| Role Type | Expected Org Level | Score if Match | Score if Mismatch |
|-----------|-------------------|----------------|-------------------|
| Finance Manager | L2 | 100 | 50 |
| Budget Approver | L2 | 100 | 50 |
| S&D Analyst | L4 | 100 | 50 |
| Warehouse Manager | L3 | 100 | 50 |
| PO Creator | L4 | 100 | 50 |
| PO Releaser | L4 | 100 | 50 |
| GR Processor | L4 | 100 | 50 |
| AP Clerk | L4 | 100 | 50 |

#### 4. Department Match (10%)

| Scenario | Score |
|----------|-------|
| User department directly maps to role's functional area | 100 |
| User department is related to role's functional area | 50 |
| No relationship between department and role | 0 |

#### 5. Peer Analysis (15%)

| Scenario | Score |
|----------|-------|
| >50% of peers (same function + level + country) have this role | 100 |
| 25-50% of peers have this role | 75 |
| 10-25% of peers have this role | 50 |
| <10% of peers have this role | 25 |
| No peers have this role | 0 |

#### 6. Historical Usage (10%)

| Scenario | Score |
|----------|-------|
| User has actively used >75% of transactions in the role | 100 |
| User has used 50-75% of transactions | 75 |
| User has used 25-50% of transactions | 50 |
| User has used <25% of transactions | 25 |
| No usage data available (new assignment) | 50 |

---

## Cypher Queries for Confidence Calculation

### Query 1: Calculate Confidence Score for User-Role Combination

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// IDENTITY CONFIDENCE SCORE CALCULATION
// Parameters: $userId, $roleId
// ═══════════════════════════════════════════════════════════════════════════

WITH $userId AS userId, $roleId AS roleId

// Get user and role
MATCH (u:User {userId: userId})
MATCH (br:BusinessRole {roleId: roleId})

// ─────────────────────────────────────────────────────────────────────────────
// CRITERION 1: Function Match (30%)
// ─────────────────────────────────────────────────────────────────────────────
WITH u, br,
     CASE 
       WHEN u.function = 'Finance' AND br.module IN ['FIN', 'P2P'] THEN 100
       WHEN u.function = 'Sales & Marketing' AND br.module = 'S&D' THEN 100
       WHEN u.function = 'Manufacturing' AND br.module = 'DFE' THEN 100
       WHEN u.function = 'Procurement & Supply Chain' AND br.module = 'P2P' THEN 100
       WHEN br.module CONTAINS substring(u.function, 0, 3) THEN 50
       ELSE 0 
     END AS functionScore

// ─────────────────────────────────────────────────────────────────────────────
// CRITERION 2: Country Match (20%)
// ─────────────────────────────────────────────────────────────────────────────
OPTIONAL MATCH (br)-[:VALID_FOR_COUNTRY]->(c:Country)
WITH u, br, functionScore,
     CASE 
       WHEN u.countryCode = c.isoCode THEN 100
       WHEN c IS NULL THEN 50  // Master role
       ELSE 0 
     END AS countryScore

// ─────────────────────────────────────────────────────────────────────────────
// CRITERION 3: Org Level Match (15%)
// ─────────────────────────────────────────────────────────────────────────────
WITH u, br, functionScore, countryScore,
     CASE 
       WHEN br.name CONTAINS 'Finance Manager' AND u.level = 'L2' THEN 100
       WHEN br.name CONTAINS 'Budget' AND u.level = 'L2' THEN 100
       WHEN br.name CONTAINS 'Analyst' AND u.level = 'L4' THEN 100
       WHEN br.name CONTAINS 'Warehouse' AND u.level = 'L3' THEN 100
       WHEN br.name CONTAINS 'Creator' AND u.level = 'L4' THEN 100
       WHEN br.name CONTAINS 'Releaser' AND u.level = 'L4' THEN 100
       WHEN br.name CONTAINS 'Processor' AND u.level = 'L4' THEN 100
       WHEN br.name CONTAINS 'Clerk' AND u.level = 'L4' THEN 100
       ELSE 50 
     END AS levelScore

// ─────────────────────────────────────────────────────────────────────────────
// CRITERION 4: Department Match (10%)
// ─────────────────────────────────────────────────────────────────────────────
WITH u, br, functionScore, countryScore, levelScore,
     CASE 
       WHEN u.department = u.function THEN 100
       ELSE 50 
     END AS deptScore

// ─────────────────────────────────────────────────────────────────────────────
// CRITERION 5: Peer Analysis (15%)
// ─────────────────────────────────────────────────────────────────────────────
OPTIONAL MATCH (peer:User)-[:HAS_BUSINESS_ROLE]->(br)
WHERE peer.function = u.function 
  AND peer.level = u.level 
  AND peer.countryCode = u.countryCode
  AND peer.userId <> u.userId

WITH u, br, functionScore, countryScore, levelScore, deptScore,
     count(peer) AS peersWithRole

OPTIONAL MATCH (allPeer:User)
WHERE allPeer.function = u.function 
  AND allPeer.level = u.level 
  AND allPeer.countryCode = u.countryCode
  AND allPeer.userId <> u.userId

WITH u, br, functionScore, countryScore, levelScore, deptScore, 
     peersWithRole, count(allPeer) AS totalPeers,
     CASE 
       WHEN count(allPeer) = 0 THEN 50
       WHEN toFloat(peersWithRole) / count(allPeer) > 0.5 THEN 100
       WHEN toFloat(peersWithRole) / count(allPeer) > 0.25 THEN 75
       WHEN toFloat(peersWithRole) / count(allPeer) > 0.1 THEN 50
       ELSE 25 
     END AS peerScore

// ─────────────────────────────────────────────────────────────────────────────
// CRITERION 6: Historical Usage (10%) - Default 50 if no data
// ─────────────────────────────────────────────────────────────────────────────
WITH u, br, functionScore, countryScore, levelScore, deptScore, peerScore,
     50 AS usageScore  // Default - would be calculated from SAP usage logs

// ─────────────────────────────────────────────────────────────────────────────
// CALCULATE FINAL CONFIDENCE SCORE
// ─────────────────────────────────────────────────────────────────────────────
WITH u, br,
     functionScore, countryScore, levelScore, deptScore, peerScore, usageScore,
     (functionScore * 0.30 + 
      countryScore * 0.20 + 
      levelScore * 0.15 + 
      deptScore * 0.10 +
      peerScore * 0.15 + 
      usageScore * 0.10) AS confidenceScore

RETURN 
  u.userId AS UserId,
  u.firstName + ' ' + u.lastName AS UserName,
  u.function AS Function,
  u.level AS OrgLevel,
  u.country AS Country,
  br.roleId AS RoleId,
  br.name AS RoleName,
  br.module AS Module,
  functionScore AS FunctionMatchScore,
  countryScore AS CountryMatchScore,
  levelScore AS LevelMatchScore,
  deptScore AS DepartmentMatchScore,
  peerScore AS PeerAnalysisScore,
  usageScore AS HistoricalUsageScore,
  round(confidenceScore, 2) AS ConfidencePercentage,
  CASE 
    WHEN confidenceScore >= 90 THEN 'HIGH - Auto Approve'
    WHEN confidenceScore >= 70 THEN 'MEDIUM - Standard Approval'
    WHEN confidenceScore >= 50 THEN 'LOW - Enhanced Review'
    ELSE 'ANOMALY - Investigation Required'
  END AS Recommendation
```

### Query 2: Find All Low-Confidence Role Assignments

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// FIND USERS WITH LOW CONFIDENCE ROLE ASSIGNMENTS (Anomalies)
// ═══════════════════════════════════════════════════════════════════════════

MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)

// Calculate function match
WITH u, br,
     CASE 
       WHEN u.function = 'Finance' AND br.module IN ['FIN', 'P2P'] THEN 100
       WHEN u.function = 'Sales & Marketing' AND br.module = 'S&D' THEN 100
       WHEN u.function = 'Manufacturing' AND br.module = 'DFE' THEN 100
       WHEN u.function = 'Procurement & Supply Chain' AND br.module = 'P2P' THEN 100
       ELSE 0 
     END AS functionScore

// Calculate country match
OPTIONAL MATCH (br)-[:VALID_FOR_COUNTRY]->(c:Country)
WITH u, br, functionScore,
     CASE WHEN u.countryCode = c.isoCode THEN 100 ELSE 0 END AS countryScore

// Simple confidence calculation
WITH u, br, 
     (functionScore * 0.30 + countryScore * 0.20 + 50 * 0.50) AS confidenceScore

WHERE confidenceScore < 50

RETURN 
  u.userId AS UserId,
  u.firstName + ' ' + u.lastName AS UserName,
  u.function AS UserFunction,
  u.country AS UserCountry,
  br.roleId AS RoleId,
  br.name AS RoleName,
  br.module AS RoleModule,
  round(confidenceScore, 2) AS ConfidencePercentage,
  'ANOMALY - Investigation Required' AS Status
ORDER BY confidenceScore ASC
```

---

## Predictive Role Recommendations

### Query 3: Recommend Roles for a User

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// RECOMMEND ROLES FOR A USER BASED ON IDENTITY ATTRIBUTES
// Parameter: $userId
// ═══════════════════════════════════════════════════════════════════════════

MATCH (u:User {userId: $userId})
MATCH (br:BusinessRole)
WHERE br.status = 'ACTIVE'
  AND NOT EXISTS { MATCH (u)-[:HAS_BUSINESS_ROLE]->(br) }

// Calculate function match score
WITH u, br,
     CASE 
       WHEN u.function = 'Finance' AND br.module IN ['FIN', 'P2P'] THEN 30
       WHEN u.function = 'Sales & Marketing' AND br.module = 'S&D' THEN 30
       WHEN u.function = 'Manufacturing' AND br.module = 'DFE' THEN 30
       WHEN u.function = 'Procurement & Supply Chain' AND br.module = 'P2P' THEN 30
       ELSE 0 
     END AS funcScore

// Calculate country match score
OPTIONAL MATCH (br)-[:VALID_FOR_COUNTRY]->(c:Country {isoCode: u.countryCode})
WITH u, br, funcScore,
     CASE WHEN c IS NOT NULL THEN 20 ELSE 0 END AS countryScore

// Check peer assignments
OPTIONAL MATCH (peer:User)-[:HAS_BUSINESS_ROLE]->(br)
WHERE peer.function = u.function 
  AND peer.level = u.level 
  AND peer.countryCode = u.countryCode
  AND peer.userId <> u.userId

WITH u, br, funcScore, countryScore, count(peer) AS peerCount

// Calculate total recommendation score
WITH u, br, 
     funcScore + countryScore + 
     CASE 
       WHEN peerCount > 10 THEN 30
       WHEN peerCount > 5 THEN 25 
       WHEN peerCount > 0 THEN 15 
       ELSE 0 
     END AS totalScore,
     peerCount

WHERE totalScore >= 50

RETURN 
  br.roleId AS RecommendedRoleId,
  br.name AS RoleName,
  br.module AS Module,
  totalScore AS MatchScore,
  peerCount AS PeersWithRole,
  CASE 
    WHEN totalScore >= 70 THEN 'Strong Recommendation'
    WHEN totalScore >= 50 THEN 'Moderate Recommendation'
    ELSE 'Weak Recommendation'
  END AS RecommendationStrength,
  'Based on function (' + u.function + '), country (' + u.country + '), and peer analysis' AS Reason
ORDER BY totalScore DESC
LIMIT 5
```

### Query 4: Bulk Confidence Analysis for All Users

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// BULK CONFIDENCE ANALYSIS - ALL USER-ROLE ASSIGNMENTS
// ═══════════════════════════════════════════════════════════════════════════

MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)

// Function match
WITH u, br,
     CASE 
       WHEN u.function = 'Finance' AND br.module IN ['FIN', 'P2P'] THEN 100
       WHEN u.function = 'Sales & Marketing' AND br.module = 'S&D' THEN 100
       WHEN u.function = 'Manufacturing' AND br.module = 'DFE' THEN 100
       WHEN u.function = 'Procurement & Supply Chain' AND br.module = 'P2P' THEN 100
       ELSE 0 
     END AS functionScore

// Country match
OPTIONAL MATCH (br)-[:VALID_FOR_COUNTRY]->(c:Country)
WITH u, br, functionScore,
     CASE WHEN u.countryCode = c.isoCode THEN 100 WHEN c IS NULL THEN 50 ELSE 0 END AS countryScore

// Calculate confidence
WITH u, br, 
     (functionScore * 0.30 + countryScore * 0.20 + 50 * 0.50) AS confidence

RETURN 
  CASE 
    WHEN confidence >= 90 THEN 'HIGH (90-100%)'
    WHEN confidence >= 70 THEN 'MEDIUM (70-89%)'
    WHEN confidence >= 50 THEN 'LOW (50-69%)'
    ELSE 'ANOMALY (<50%)'
  END AS ConfidenceLevel,
  count(*) AS AssignmentCount,
  collect(DISTINCT u.userId)[0..5] AS SampleUsers
ORDER BY 
  CASE 
    WHEN confidence >= 90 THEN 1
    WHEN confidence >= 70 THEN 2
    WHEN confidence >= 50 THEN 3
    ELSE 4
  END
```

---

## SAP Data Points Required

### Overview

The following SAP tables and data points are required to build the knowledge graph and enable SOD detection, identity confidence scoring, and access analytics.

### SAP Tables Summary

| Category | Tables | Purpose |
|----------|--------|---------|
| User Master | USR02, USR21, ADRP, USR06 | User identity and status |
| Role Definitions | AGR_DEFINE, AGR_1251, AGR_TEXTS, AGR_AGRS | Role structure and authorizations |
| User-Role Assignments | AGR_USERS, AGR_PROF | Who has what roles |
| Transactions | TSTC, TSTCT, USOBT, USOBX | Transaction codes and auth requirements |
| Authorization Objects | TOBJ, TOBJT, TACTZ | Authorization object definitions |
| Usage Logs | STAD, SM21, CDHDR/CDPOS | Historical usage data |

---

### 1. User Master Data

#### Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **USR02** | User Logon Data | BNAME, USTYP, CLASS, GLTGV, GLTGB |
| **USR21** | User Address Keys | BNAME, PERSNUMBER, ADDRNUMBER |
| **ADRP** | Person Address | PERSNUMBER, NAME_FIRST, NAME_LAST |
| **USR06** | Additional User Data | BNAME, LIC_TYPE |

#### Field Descriptions

| Field | Table | Description | Graph Mapping |
|-------|-------|-------------|---------------|
| BNAME | USR02 | SAP Username | User.userId |
| USTYP | USR02 | User Type (A=Dialog, B=System, etc.) | User.userType |
| CLASS | USR02 | User Group | User.userGroup |
| GLTGV | USR02 | Valid From Date | User.validFrom |
| GLTGB | USR02 | Valid To Date | User.validTo |
| NAME_FIRST | ADRP | First Name | User.firstName |
| NAME_LAST | ADRP | Last Name | User.lastName |
| LIC_TYPE | USR06 | License Type | User.licenseType |

#### Extraction Query

```sql
SELECT 
    u.BNAME AS user_id,
    u.USTYP AS user_type,
    u.CLASS AS user_group,
    u.GLTGV AS valid_from,
    u.GLTGB AS valid_to,
    a.NAME_FIRST AS first_name,
    a.NAME_LAST AS last_name,
    u6.LIC_TYPE AS license_type
FROM USR02 u
INNER JOIN USR21 u21 ON u.BNAME = u21.BNAME
INNER JOIN ADRP a ON u21.PERSNUMBER = a.PERSNUMBER
LEFT JOIN USR06 u6 ON u.BNAME = u6.BNAME
WHERE u.USTYP = 'A'  -- Dialog users only
  AND u.GLTGB >= CURRENT_DATE  -- Active users
ORDER BY u.BNAME
```

---

### 2. Role Definitions

#### Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **AGR_DEFINE** | Role Definition | AGR_NAME, PARENT_AGR |
| **AGR_1251** | Role Authorization Data | AGR_NAME, OBJECT, AUTH, FIELD, LOW, HIGH |
| **AGR_TEXTS** | Role Descriptions | AGR_NAME, TEXT, SPRAS |
| **AGR_AGRS** | Composite Role Contents | AGR_NAME, CHILD_AGR |

#### Field Descriptions

| Field | Table | Description | Graph Mapping |
|-------|-------|-------------|---------------|
| AGR_NAME | AGR_DEFINE | Role Technical Name | BusinessRole.roleId / FunctionalRole.roleId |
| PARENT_AGR | AGR_DEFINE | Parent Role (for derived roles) | DerivedRole.masterRoleId |
| TEXT | AGR_TEXTS | Role Description | BusinessRole.description |
| OBJECT | AGR_1251 | Authorization Object | AuthObject.objectId |
| AUTH | AGR_1251 | Authorization Name | - |
| FIELD | AGR_1251 | Authorization Field | - |
| LOW | AGR_1251 | Field Value (From) | GRANTS_AUTH.fieldValues |
| HIGH | AGR_1251 | Field Value (To) | GRANTS_AUTH.fieldValues |
| CHILD_AGR | AGR_AGRS | Child Role in Composite | CONTAINS_ROLE relationship |

#### Extraction Query - Role Definitions

```sql
SELECT 
    d.AGR_NAME AS role_id,
    d.PARENT_AGR AS parent_role,
    t.TEXT AS description,
    CASE 
        WHEN d.AGR_NAME LIKE 'ZC:%' THEN 'BUSINESS'
        WHEN d.AGR_NAME LIKE 'ZRM:%' THEN 'FUNCTIONAL_MAINTAIN'
        WHEN d.AGR_NAME LIKE 'ZRD:%' THEN 'FUNCTIONAL_DISPLAY'
        WHEN d.AGR_NAME LIKE 'ZDM:%' THEN 'DERIVED_MAINTAIN'
        WHEN d.AGR_NAME LIKE 'ZDD:%' THEN 'DERIVED_DISPLAY'
        ELSE 'OTHER'
    END AS role_type
FROM AGR_DEFINE d
LEFT JOIN AGR_TEXTS t ON d.AGR_NAME = t.AGR_NAME AND t.SPRAS = 'E'
WHERE d.AGR_NAME LIKE 'Z%'
ORDER BY d.AGR_NAME
```

#### Extraction Query - Role Authorizations

```sql
SELECT 
    a.AGR_NAME AS role_id,
    a.OBJECT AS auth_object,
    a.AUTH AS authorization,
    a.FIELD AS field_name,
    a.LOW AS value_from,
    a.HIGH AS value_to
FROM AGR_1251 a
WHERE a.AGR_NAME LIKE 'Z%'
  AND a.DELETED = ''
ORDER BY a.AGR_NAME, a.OBJECT, a.FIELD
```

#### Extraction Query - Composite Role Structure

```sql
SELECT 
    a.AGR_NAME AS composite_role,
    a.CHILD_AGR AS child_role
FROM AGR_AGRS a
WHERE a.AGR_NAME LIKE 'ZC:%'
ORDER BY a.AGR_NAME, a.CHILD_AGR
```

---

### 3. User-Role Assignments

#### Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **AGR_USERS** | User Role Assignments | AGR_NAME, UNAME, FROM_DAT, TO_DAT |
| **AGR_PROF** | Role Profiles | AGR_NAME, PROFILE |

#### Field Descriptions

| Field | Table | Description | Graph Mapping |
|-------|-------|-------------|---------------|
| AGR_NAME | AGR_USERS | Role Name | HAS_BUSINESS_ROLE.roleId |
| UNAME | AGR_USERS | Username | User.userId |
| FROM_DAT | AGR_USERS | Assignment Start Date | HAS_BUSINESS_ROLE.validFrom |
| TO_DAT | AGR_USERS | Assignment End Date | HAS_BUSINESS_ROLE.validTo |
| CHANGE_DAT | AGR_USERS | Last Change Date | HAS_BUSINESS_ROLE.modifiedDate |
| CHANGE_USR | AGR_USERS | Changed By User | HAS_BUSINESS_ROLE.assignedBy |

#### Extraction Query

```sql
SELECT 
    au.UNAME AS user_id,
    au.AGR_NAME AS role_id,
    au.FROM_DAT AS valid_from,
    au.TO_DAT AS valid_to,
    au.CHANGE_DAT AS modified_date,
    au.CHANGE_TIM AS modified_time,
    au.CHANGE_USR AS modified_by
FROM AGR_USERS au
WHERE au.TO_DAT >= CURRENT_DATE  -- Active assignments only
  AND au.AGR_NAME LIKE 'Z%'
ORDER BY au.UNAME, au.AGR_NAME
```

---

### 4. Transaction Codes

#### Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **TSTC** | Transaction Codes | TCODE, PGMNA, DESSION |
| **TSTCT** | Transaction Texts | TCODE, TTEXT, SPRSL |
| **USOBT** | Transaction-Auth Object Relation | NAME, OBJECT, FIELD |
| **USOBX** | Check Indicator | NAME, OBJECT |

#### Field Descriptions

| Field | Table | Description | Graph Mapping |
|-------|-------|-------------|---------------|
| TCODE | TSTC | Transaction Code | Transaction.tcode |
| PGMNA | TSTC | Program Name | Transaction.program |
| TTEXT | TSTCT | Transaction Description | Transaction.description |
| NAME | USOBT | Transaction Code | REQUIRES_AUTH relationship |
| OBJECT | USOBT | Required Auth Object | AuthObject.objectId |
| FIELD | USOBT | Auth Object Field | - |

#### Key Transactions for P2P/O2C

| TCode | Description | Module | Critical |
|-------|-------------|--------|----------|
| ME21N | Create Purchase Order | MM | Yes |
| ME22N | Change Purchase Order | MM | No |
| ME23N | Display Purchase Order | MM | No |
| ME28 | Release Purchase Order | MM | Yes |
| MIGO | Goods Movement | MM | Yes |
| MIRO | Enter Incoming Invoice | MM | Yes |
| VA01 | Create Sales Order | SD | No |
| VA02 | Change Sales Order | SD | No |
| VA03 | Display Sales Order | SD | No |
| FB01 | Post Document | FI | Yes |
| FB03 | Display Document | FI | No |

#### Extraction Query

```sql
SELECT 
    t.TCODE AS tcode,
    tt.TTEXT AS description,
    t.PGMNA AS program,
    CASE 
        WHEN t.TCODE LIKE 'ME%' THEN 'MM'
        WHEN t.TCODE LIKE 'VA%' THEN 'SD'
        WHEN t.TCODE LIKE 'FB%' THEN 'FI'
        WHEN t.TCODE LIKE 'MI%' THEN 'MM'
        ELSE 'OTHER'
    END AS module
FROM TSTC t
INNER JOIN TSTCT tt ON t.TCODE = tt.TCODE AND tt.SPRSL = 'E'
WHERE t.TCODE IN (
    'ME21N', 'ME22N', 'ME23N', 'ME28', 'ME29N',
    'MIGO', 'MIRO', 'MIR7',
    'VA01', 'VA02', 'VA03',
    'FB01', 'FB02', 'FB03',
    'AJAB', 'FSP0', 'FK10N', 'FI03',
    'MD04', 'LT01'
)
ORDER BY t.TCODE
```

#### Transaction to Authorization Object Mapping

```sql
SELECT 
    u.NAME AS tcode,
    u.OBJECT AS auth_object,
    u.FIELD AS field_name,
    x.OKFLAG AS check_active
FROM USOBT u
INNER JOIN USOBX x ON u.NAME = x.NAME AND u.OBJECT = x.OBJECT
WHERE u.NAME IN ('ME21N', 'ME28', 'MIGO', 'MIRO')
ORDER BY u.NAME, u.OBJECT
```

---

### 5. Authorization Objects

#### Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **TOBJ** | Authorization Objects | OBJCT, FIEL1-FIEL10 |
| **TOBJT** | Object Texts | OBJCT, TTEXT, LANGU |
| **TACTZ** | Activity Values | ACTVT, ACTXT |

#### Key Authorization Objects for P2P

| Auth Object | Description | Key Fields |
|-------------|-------------|------------|
| M_BEST_EKG | PO: Purchasing Group | EKGRP |
| M_BEST_EKO | PO: Purchasing Organization | EKORG |
| M_BEST_BSA | PO: Document Type | BSART |
| M_BEST_WRK | PO: Plant | WERKS |
| M_EINK_FRG | PO Release: Release Code | FRGCO |
| M_MSEG_BWE | Goods Receipt: Movement Type | BWART |
| M_MSEG_WMB | Goods Receipt: Movement Indicator | KZBEW |
| M_RECH_WRK | Invoice: Plant | WERKS |
| M_RECH_EKG | Invoice: Purchasing Group | EKGRP |

#### Extraction Query

```sql
SELECT 
    o.OBJCT AS object_id,
    ot.TTEXT AS description,
    o.FIEL1 AS field1,
    o.FIEL2 AS field2,
    o.FIEL3 AS field3,
    o.FIEL4 AS field4,
    o.FIEL5 AS field5
FROM TOBJ o
INNER JOIN TOBJT ot ON o.OBJCT = ot.OBJCT AND ot.LANGU = 'E'
WHERE o.OBJCT LIKE 'M_%'  -- Material Management objects
   OR o.OBJCT LIKE 'F_%'  -- Finance objects
   OR o.OBJCT LIKE 'V_%'  -- Sales objects
ORDER BY o.OBJCT
```

---

### 6. Usage/Activity Logs (For Historical Analysis)

#### Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **STAD** | Statistical Records | TCODE, ACCOUNT, STARTDATE |
| **SM21** | System Log | USER, TCODE, DATE, TIME |
| **CDHDR** | Change Document Header | OBJECTCLAS, OBJECTID, CHANGENR |
| **CDPOS** | Change Document Items | CHANGENR, TABNAME, FNAME |

#### Usage Statistics Query

```sql
-- Note: STAD data is typically accessed via transaction ST03N
-- This is a conceptual query structure

SELECT 
    ACCOUNT AS user_id,
    TCODE AS transaction,
    COUNT(*) AS execution_count,
    MIN(STARTDATE) AS first_use,
    MAX(STARTDATE) AS last_use
FROM STAD
WHERE STARTDATE >= ADD_MONTHS(CURRENT_DATE, -3)  -- Last 3 months
  AND TCODE IN ('ME21N', 'ME28', 'MIGO', 'MIRO')
GROUP BY ACCOUNT, TCODE
ORDER BY ACCOUNT, execution_count DESC
```

---

## Data Extraction Methods

### Method 1: RFC/BAPI (Real-time Integration)

Best for: Real-time data synchronization, event-driven updates

```python
# Python example using pyrfc
from pyrfc import Connection

def get_user_roles(conn, username):
    """Get all roles assigned to a user"""
    result = conn.call('BAPI_USER_GET_DETAIL', USERNAME=username)
    return result['ACTIVITYGROUPS']

def get_role_details(conn, role_name):
    """Get role authorization details"""
    result = conn.call('PRGN_READ_AGR_DEFINITION', AGR_NAME=role_name)
    return result

# Connection setup
conn = Connection(
    ashost='sap-server.company.com',
    sysnr='00',
    client='100',
    user='RFC_USER',
    passwd='password'
)

# Example usage
roles = get_user_roles(conn, 'JSMITH')
for role in roles:
    print(f"Role: {role['AGR_NAME']}, Valid: {role['FROM_DAT']} - {role['TO_DAT']}")
```

### Method 2: OData Services (SAP Gateway)

Best for: REST API integration, web applications

```
# Available OData endpoints (configure in SAP Gateway)

# User Role Assignments
GET /sap/opu/odata/sap/API_USER_ROLE_ASSIGNMENT_SRV/UserRoleAssignments
    ?$filter=UserName eq 'JSMITH'

# Business Roles
GET /sap/opu/odata/sap/API_BUSINESS_ROLE_SRV/BusinessRoles
    ?$filter=RoleName eq 'ZC:FIN:FINANCE_MANAGER___:1000'

# Authorization Objects
GET /sap/opu/odata/sap/API_AUTHORIZATION_OBJECT_SRV/AuthorizationObjects
    ?$filter=RoleName eq 'ZRM:FI_:PERD_END_CLOSING_:0000'
```

### Method 3: Direct Table Extraction (Batch)

Best for: Initial data load, periodic full sync

```sql
-- Export to CSV for batch loading into Neo4j

-- Users
SELECT BNAME, USTYP, CLASS, GLTGV, GLTGB 
FROM USR02 
WHERE USTYP = 'A' AND GLTGB >= CURRENT_DATE
INTO OUTFILE '/tmp/users.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"';

-- Role Assignments
SELECT UNAME, AGR_NAME, FROM_DAT, TO_DAT 
FROM AGR_USERS 
WHERE TO_DAT >= CURRENT_DATE
INTO OUTFILE '/tmp/role_assignments.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"';

-- Role Definitions
SELECT AGR_NAME, PARENT_AGR 
FROM AGR_DEFINE 
WHERE AGR_NAME LIKE 'Z%'
INTO OUTFILE '/tmp/roles.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"';
```

---

## Data Mapping to Graph Nodes

### Complete Mapping Reference

| SAP Source | Graph Node Type | Key Field Mapping | Relationship |
|------------|-----------------|-------------------|--------------|
| USR02 + ADRP | User | BNAME → userId | - |
| AGR_DEFINE (ZC:*) | BusinessRole | AGR_NAME → roleId | - |
| AGR_DEFINE (ZRM:*, ZRD:*) | FunctionalRole | AGR_NAME → roleId | - |
| AGR_DEFINE (ZDM:*, ZDD:*) | DerivedRole | AGR_NAME → roleId | DERIVED_FROM → FunctionalRole |
| AGR_USERS | - | - | User -[HAS_BUSINESS_ROLE]→ BusinessRole |
| AGR_AGRS | - | - | BusinessRole -[CONTAINS_ROLE]→ FunctionalRole |
| TSTC + TSTCT | Transaction | TCODE → tcode | - |
| TOBJ + TOBJT | AuthObject | OBJCT → objectId | - |
| AGR_1251 | - | - | FunctionalRole -[GRANTS_AUTH]→ AuthObject |
| USOBT | - | - | Transaction -[REQUIRES_AUTH]→ AuthObject |

### Neo4j Load Script Example

```cypher
// Load Users from CSV
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: row.user_id})
SET u.firstName = row.first_name,
    u.lastName = row.last_name,
    u.userType = row.user_type,
    u.validFrom = date(row.valid_from),
    u.validTo = date(row.valid_to),
    u.status = CASE WHEN date(row.valid_to) >= date() THEN 'ACTIVE' ELSE 'INACTIVE' END;

// Load Business Roles from CSV
LOAD CSV WITH HEADERS FROM 'file:///roles.csv' AS row
WITH row WHERE row.role_id STARTS WITH 'ZC:'
MERGE (br:BusinessRole {roleId: row.role_id})
SET br.name = row.description,
    br.module = CASE 
        WHEN row.role_id CONTAINS ':FIN:' THEN 'FIN'
        WHEN row.role_id CONTAINS ':S&D:' THEN 'S&D'
        WHEN row.role_id CONTAINS ':DFE:' THEN 'DFE'
        WHEN row.role_id CONTAINS ':P2P:' THEN 'P2P'
        ELSE 'OTHER'
    END;

// Load User-Role Assignments from CSV
LOAD CSV WITH HEADERS FROM 'file:///role_assignments.csv' AS row
MATCH (u:User {userId: row.user_id})
MATCH (br:BusinessRole {roleId: row.role_id})
MERGE (u)-[r:HAS_BUSINESS_ROLE]->(br)
SET r.validFrom = date(row.valid_from),
    r.validTo = date(row.valid_to),
    r.status = CASE WHEN date(row.valid_to) >= date() THEN 'ACTIVE' ELSE 'INACTIVE' END;
```

---

## Required SAP Authorizations

The RFC/technical user needs the following authorizations for data extraction:

| Auth Object | Field | Value | Description |
|-------------|-------|-------|-------------|
| S_RFC | RFC_TYPE | FUGR | Function group access |
| S_RFC | RFC_NAME | SYST, BAPI*, PRGN* | Required function modules |
| S_TABU_DIS | DICBERCLS | SS, SC | Table access for security tables |
| S_USER_GRP | CLASS | * | User group access |
| S_USER_AGR | ACTVT | 03 | Display role assignments |
| S_USER_AUT | ACTVT | 03 | Display authorizations |

---

## Data Refresh Recommendations

| Data Type | Frequency | Method | Rationale |
|-----------|-----------|--------|-----------|
| User Master | Daily | RFC/OData | User changes are frequent |
| Role Definitions | Weekly | Batch | Roles change less frequently |
| User-Role Assignments | Daily | RFC/OData | Critical for SOD detection |
| Transaction Codes | Monthly | Batch | Rarely change |
| Authorization Objects | Monthly | Batch | Rarely change |
| Usage Logs | Weekly | Batch | For trend analysis |

---

## Summary

This document provides:

1. **Identity Confidence Percentage** methodology with 6 weighted criteria
2. **Cypher queries** for calculating confidence scores and detecting anomalies
3. **Predictive role recommendations** based on user attributes
4. **Complete SAP data extraction** requirements with tables, fields, and queries
5. **Data mapping** from SAP to Neo4j graph nodes
6. **Integration methods** (RFC, OData, Batch) with code examples

Use this document alongside the main README.md to implement the full EKG solution for identity and access management.
