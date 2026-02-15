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

