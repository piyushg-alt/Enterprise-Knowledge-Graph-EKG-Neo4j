# Enterprise Knowledge Graph (EKG) for Identity & Access Management
## SOD Anomaly Detection using Neo4j

### Project Overview

This project implements a Neo4j-based Knowledge Graph solution for detecting Segregation of Duties (SOD) violations and access anomalies in enterprise identity management systems. The solution integrates data from multiple authoritative sources including SAP S4/HANA, Microsoft Entra ID (Azure AD), SuccessFactors HR, and process inventory systems.

---

## Table of Contents

1. [Business Context](#business-context)
2. [Problem Statement](#problem-statement)
3. [Solution Architecture](#solution-architecture)
4. [Data Sources](#data-sources)
5. [Graph Data Model](#graph-data-model)
6. [SOD Rules & Conflict Detection](#sod-rules--conflict-detection)
7. [Use Cases](#use-cases)
8. [Implementation Roadmap](#implementation-roadmap)
9. [Technical Stack](#technical-stack)
10. [Getting Started](#getting-started)

---

## Business Context

### Organization Profile (Reference Model)
- **Company**:  Organization
- **Size**: 1,000 employees and third parties
- **Industry**: Manufacturing (glass, metal, packaging for CPG)
- **Geographic Presence**: 11 countries (UK, US, UAE, Germany, India, Russia, China, Australia, Singapore, South Africa, Kazakhstan)
- **Key Functions**: Finance, Sales & Marketing, Manufacturing/DFE, Procurement & Supply Chain

### Functional Streams
| Stream | Code | Description |
|--------|------|-------------|
| Finance | FIN | Financial operations, AP/AR, Budget |
| Sales & Distribution | S&D | Sales order management |
| DFE (Plants) | DFE | Warehouse and plant operations |
| Procure to Pay | P2P | Purchase orders, goods receipt, invoicing |

---

## Problem Statement

> "Enterprises spend vast sums each year on access governance and identity management, yet data breaches remain widespread, with human error and outdated permissions cited as persistent root causes."

### Key Challenges
1. **Static Governance Systems**: Existing IAM systems are passive repositories dependent on data accuracy
2. **Stale Access**: Outdated permissions create security vulnerabilities
3. **SOD Violations**: Users accumulating conflicting access rights over time
4. **Manual Remediation**: Expensive and prolonged remediation cycles
5. **Lack of Intelligence**: No inherent capability to question or correct access configurations

### SOD Risk Examples
- **PO Creator + PO Approver**: Same user can create and approve purchase orders (fraud risk)
- **GR Processor + Invoice Approver**: Same user can receive goods and approve payment (embezzlement risk)
- **Invoice Poster + Budget Approver**: Same user can post and approve invoices (financial control bypass)

---

## Solution Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FOUNDATIONAL LAYER                                 │
├─────────────────┬─────────────────┬─────────────────┬───────────────────────┤
│  SuccessFactors │   Entra ID      │   Active        │                       │
│  (HR Data)      │   (Azure AD)    │   Directory     │   (Process Inventory) │
└────────┬────────┴────────┬────────┴────────┬────────┴───────────┬───────────┘
         │                 │                 │                     │
         └─────────────────┴─────────────────┴─────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         NEO4J KNOWLEDGE GRAPH                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Users     │──│   Roles     │──│Transactions │──│ Authorization Obj   │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Processes  │──│  Functions  │──│  Countries  │──│   SOD Rules         │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ANALYTICS & DETECTION LAYER                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │ SOD Violation   │  │ Anomaly         │  │ Risk Scoring                │  │
│  │ Detection       │  │ Detection       │  │ Engine                      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PRESENTATION & REMEDIATION                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │ MS Teams NLP    │  │ Visual Graph    │  │ Remediation                 │  │
│  │ Interface       │  │ Explorer        │  │ Workflows                   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Sources

### 1. Microsoft Entra ID (Azure AD)
**Purpose**: Identity provider, authentication, group memberships

| Attribute | Description | Usage |
|-----------|-------------|-------|
| UserPrincipalName | Unique user identifier | Primary key for user matching |
| DisplayName | User's full name | Display purposes |
| Department | Organizational department | Function mapping |
| JobTitle | User's job title | Role assignment logic |
| Manager | Reporting manager | Approval workflow |
| MemberOf | Group memberships | Birthright access groups |
| Country | User's country | Entity/region mapping |
| AccountEnabled | Active/Inactive status | Access validation |

**Integration Method**: Microsoft Graph API

### 2. SuccessFactors (HR System)
**Purpose**: Authoritative source for organizational hierarchy

| Attribute | Description | Usage |
|-----------|-------------|-------|
| Employee ID | Unique employee identifier | Cross-system correlation |
| Function | Business function | Role assignment logic |
| Cost Code | Financial cost center | Process ownership |
| Entity | Country/legal entity code | Derived role assignment |
| Level | Organizational level (L1-L4) | Approval hierarchy |
| Location | Physical work location | Plant/site access |
| Line Manager | Direct supervisor | Ownership chain |

### 3. SAP S4/HANA
**Purpose**: System of record for business transactions and authorizations

| Data Type | Tables/Sources | Description |
|-----------|----------------|-------------|
| Users | USR02, USR21 | SAP user master data |
| Roles | AGR_DEFINE, AGR_1251 | Role definitions |
| Role Assignments | AGR_USERS | User-role mappings |
| Transactions | TSTC, TSTCT | Transaction codes |
| Auth Objects | USOBT, USOBX | Authorization objects |
| Composite Roles | AGR_AGRS | Role hierarchies |

### 4. LeanIX/Signavio
**Purpose**: Process inventory and ownership

| Attribute | Description | Usage |
|-----------|-------------|-------|
| Process ID | Unique process identifier | Process hierarchy |
| Process Owner | Business owner | Approval routing |
| Application | Supporting application | System mapping |
| Criticality | Business criticality | Risk scoring |

---

## Graph Data Model

### Node Types

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// IDENTITY NODES
// ═══════════════════════════════════════════════════════════════════════════

// User Node - Represents an individual identity
(:User {
    userId: STRING,           // Unique identifier (e.g., "jdevlin")
    firstName: STRING,        // First name
    lastName: STRING,         // Last name (familyName)
    email: STRING,            // Email/UPN
    city: STRING,             // Work city
    country: STRING,          // Country name
    countryCode: STRING,      // ISO country code (UK, US, DE, etc.)
    function: STRING,         // Business function
    department: STRING,       // Department name
    level: STRING,            // Org level (L1, L2, L3, L4)
    managerId: STRING,        // Manager's userId
    status: STRING,           // ACTIVE, INACTIVE, TERMINATED
    source: STRING            // ENTRA, SUCCESSFACTORS, SAP
})

// ═══════════════════════════════════════════════════════════════════════════
// ORGANIZATIONAL NODES
// ═══════════════════════════════════════════════════════════════════════════

// Country/Entity Node
(:Country {
    code: STRING,             // Entity code (1000, 2000, 3000, etc.)
    isoCode: STRING,          // ISO code (UK, US, AE, DE, IN, etc.)
    name: STRING,             // Full country name
    region: STRING            // Geographic region
})

// Function Node
(:Function {
    code: STRING,             // Function code (FIN, S&D, DFE, P2P)
    name: STRING,             // Full name
    description: STRING       // Description
})

// Department Node
(:Department {
    code: STRING,             // Department code
    name: STRING,             // Department name
    functionCode: STRING      // Parent function
})

// Cost Center Node
(:CostCenter {
    code: STRING,             // Cost center code
    name: STRING,             // Cost center name
    countryCode: STRING,      // Associated country
    functionCode: STRING      // Associated function
})

// ═══════════════════════════════════════════════════════════════════════════
// ROLE HIERARCHY NODES
// ═══════════════════════════════════════════════════════════════════════════

// Business Role (Composite) - Top level role assigned to users
(:BusinessRole {
    roleId: STRING,           // e.g., "ZC:FIN:FINANCE_MANAGER___:1000"
    name: STRING,             // e.g., "FIN - Finance Manager - 1000 UK"
    description: STRING,      // Role description
    module: STRING,           // Finance, Sales, DFE, P2P
    countryCode: STRING,      // Country-specific code
    isMaster: BOOLEAN,        // Is this a master role template?
    criticality: STRING,      // HIGH, MEDIUM, LOW
    status: STRING            // ACTIVE, INACTIVE
})

// Functional Role - Technical role containing transactions
(:FunctionalRole {
    roleId: STRING,           // e.g., "ZRM:FI_:PERD_END_CLOSING_:0000"
    name: STRING,             // e.g., "FI - Period END Closing - Master"
    description: STRING,      // Role description
    type: STRING,             // ZRM (Maintain), ZRD (Display)
    module: STRING,           // FI, SD, MM, etc.
    isMaster: BOOLEAN         // Is this a master template?
})

// Derived Role - Country-specific instance of functional role
(:DerivedRole {
    roleId: STRING,           // e.g., "ZDM:FI_:PERD_END_CLOSING_:1000"
    name: STRING,             // e.g., "FI - Period END Closing - 1000 UK"
    masterRoleId: STRING,     // Reference to master functional role
    countryCode: STRING,      // Country code
    type: STRING              // ZDM (Derived Maintain), ZDD (Derived Display)
})

// ═══════════════════════════════════════════════════════════════════════════
// SAP AUTHORIZATION NODES
// ═══════════════════════════════════════════════════════════════════════════

// Transaction Code
(:Transaction {
    tcode: STRING,            // e.g., "ME21N", "MIGO", "MIRO"
    name: STRING,             // Transaction name
    description: STRING,      // Full description
    module: STRING,           // SAP module (MM, FI, SD)
    type: STRING,             // Tcode, Fiori, WF (Workflow)
    accessType: STRING,       // Display, Maintain, Create
    isCritical: BOOLEAN,      // Critical transaction flag
    system: STRING            // S4, ECC, etc.
})

// Authorization Object
(:AuthObject {
    objectId: STRING,         // e.g., "M_BEST_EKG", "M_EINK_FRG"
    name: STRING,             // Object name
    description: STRING,      // Description
    objectClass: STRING       // Authorization class
})

// ═══════════════════════════════════════════════════════════════════════════
// PROCESS HIERARCHY NODES
// ═══════════════════════════════════════════════════════════════════════════

// L1 Process - Top level process
(:L1Process {
    processId: STRING,        // e.g., "P2P"
    name: STRING,             // e.g., "Purchase to Pay"
    description: STRING,      // Process description
    owner: STRING             // Process owner userId
})

// L2 Process - Sub-process
(:L2Process {
    processId: STRING,        // e.g., "P2P_PO_CREATE_RELEASE"
    name: STRING,             // e.g., "Purchase Order Creation and Release"
    description: STRING,      // Description
    parentProcessId: STRING   // L1 Process reference
})

// L3 Functionality - Specific function/activity
(:L3Functionality {
    functionalityId: STRING,  // e.g., "P2P_PO_CREATE"
    name: STRING,             // e.g., "Purchase Order Creation"
    description: STRING,      // Description
    parentProcessId: STRING   // L2 Process reference
})

// ═══════════════════════════════════════════════════════════════════════════
// SOD & COMPLIANCE NODES
// ═══════════════════════════════════════════════════════════════════════════

// SOD Rule Definition
(:SODRule {
    ruleId: STRING,           // e.g., "SOD_0001"
    name: STRING,             // Rule name
    description: STRING,      // Rule description
    riskLevel: STRING,        // HIGH, MEDIUM, LOW
    conflictType: STRING,     // e.g., "Create vs Approve"
    status: STRING            // ACTIVE, INACTIVE
})

// SOD Conflict (Detected Violation)
(:SODConflict {
    conflictId: STRING,       // Unique conflict identifier
    ruleId: STRING,           // Reference to SOD rule
    userId: STRING,           // User with conflict
    detectedDate: DATETIME,   // When detected
    status: STRING,           // OPEN, MITIGATED, ACCEPTED, REMEDIATED
    riskScore: FLOAT,         // Calculated risk score
    mitigatingControl: STRING // Any compensating control
})

// Persona (Role-based access pattern)
(:Persona {
    personaId: STRING,        // e.g., "PROCUREMENT_AGENT"
    name: STRING,             // e.g., "Procurement Agent"
    description: STRING,      // Description
    department: STRING,       // Associated department
    typicalLevel: STRING      // Typical org level
})
```

### Relationships

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// USER RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// User organizational relationships
(:User)-[:WORKS_IN]->(:Country)
(:User)-[:BELONGS_TO_FUNCTION]->(:Function)
(:User)-[:BELONGS_TO_DEPARTMENT]->(:Department)
(:User)-[:ASSIGNED_TO_COST_CENTER]->(:CostCenter)
(:User)-[:REPORTS_TO]->(:User)  // Manager relationship

// User role assignments
(:User)-[:HAS_BUSINESS_ROLE {
    assignedDate: DATETIME,
    assignedBy: STRING,
    validFrom: DATE,
    validTo: DATE,
    status: STRING
}]->(:BusinessRole)

// ═══════════════════════════════════════════════════════════════════════════
// ROLE HIERARCHY RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// Business role contains functional/derived roles
(:BusinessRole)-[:CONTAINS_ROLE]->(:FunctionalRole)
(:BusinessRole)-[:CONTAINS_ROLE]->(:DerivedRole)

// Derived role is derived from master functional role
(:DerivedRole)-[:DERIVED_FROM]->(:FunctionalRole)

// Role country association
(:BusinessRole)-[:VALID_FOR_COUNTRY]->(:Country)
(:DerivedRole)-[:VALID_FOR_COUNTRY]->(:Country)

// ═══════════════════════════════════════════════════════════════════════════
// AUTHORIZATION RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// Functional role grants access to transactions
(:FunctionalRole)-[:GRANTS_ACCESS_TO {
    accessType: STRING,  // Display, Maintain, Create
    isCritical: BOOLEAN
}]->(:Transaction)

// Transaction requires authorization objects
(:Transaction)-[:REQUIRES_AUTH]->(:AuthObject)

// Role grants authorization
(:FunctionalRole)-[:GRANTS_AUTH {
    fieldValues: MAP  // Specific field values granted
}]->(:AuthObject)

// ═══════════════════════════════════════════════════════════════════════════
// PROCESS RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// Process hierarchy
(:L1Process)-[:HAS_SUBPROCESS]->(:L2Process)
(:L2Process)-[:HAS_FUNCTIONALITY]->(:L3Functionality)

// Functionality performed by persona
(:L3Functionality)-[:PERFORMED_BY]->(:Persona)

// Persona supported by role
(:Persona)-[:SUPPORTED_BY_ROLE]->(:FunctionalRole)

// Transaction belongs to functionality
(:Transaction)-[:BELONGS_TO_FUNCTIONALITY]->(:L3Functionality)

// ═══════════════════════════════════════════════════════════════════════════
// SOD RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// SOD rule involves functionalities
(:SODRule)-[:INVOLVES_FUNCTIONALITY {
    side: STRING  // "SIDE_A" or "SIDE_B"
}]->(:L3Functionality)

// SOD rule defines conflicting roles
(:SODRule)-[:DEFINES_CONFLICT_BETWEEN {
    side: STRING
}]->(:FunctionalRole)

// Roles conflict with each other
(:FunctionalRole)-[:CONFLICTS_WITH {
    ruleId: STRING,
    riskLevel: STRING,
    conflictType: STRING
}]->(:FunctionalRole)

// SOD conflict detected for user
(:SODConflict)-[:DETECTED_FOR]->(:User)
(:SODConflict)-[:VIOLATES_RULE]->(:SODRule)
(:SODConflict)-[:INVOLVES_ROLE]->(:FunctionalRole)

// ═══════════════════════════════════════════════════════════════════════════
// OWNERSHIP RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// Process ownership
(:User)-[:OWNS_PROCESS]->(:L1Process)
(:User)-[:OWNS_PROCESS]->(:L2Process)

// Role ownership
(:User)-[:OWNS_ROLE]->(:BusinessRole)
(:User)-[:OWNS_ROLE]->(:FunctionalRole)

// Data/Application ownership
(:User)-[:IS_DATA_OWNER_FOR]->(:Transaction)
(:User)-[:IS_APP_OWNER_FOR]->(:Transaction)
```

### Visual Graph Model

```
                                    ┌─────────────┐
                                    │   Country   │
                                    │  (Entity)   │
                                    └──────┬──────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
            ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
            │   Function    │      │  Cost Center  │      │  Department   │
            └───────┬───────┘      └───────────────┘      └───────────────┘
                    │                      │                      │
                    └──────────────────────┼──────────────────────┘
                                           │
                                           ▼
                                    ┌─────────────┐
                                    │    User     │◄────────────────────┐
                                    └──────┬──────┘                     │
                                           │                            │
                         ┌─────────────────┼─────────────────┐   REPORTS_TO
                         │                 │                 │          │
                         ▼                 ▼                 ▼          │
                 ┌───────────────┐ ┌───────────────┐ ┌───────────────┐  │
                 │ BusinessRole  │ │ BusinessRole  │ │ BusinessRole  │──┘
                 │ (Finance Mgr) │ │ (PO Creator)  │ │ (GR Processor)│
                 └───────┬───────┘ └───────┬───────┘ └───────┬───────┘
                         │                 │                 │
              ┌──────────┴──────────┐      │                 │
              ▼                     ▼      ▼                 ▼
      ┌───────────────┐     ┌───────────────┐       ┌───────────────┐
      │ DerivedRole   │     │ DerivedRole   │       │ DerivedRole   │
      │ (FI Display)  │     │ (PO Creator)  │       │ (GR Processor)│
      └───────┬───────┘     └───────┬───────┘       └───────┬───────┘
              │                     │                       │
              │    DERIVED_FROM     │                       │
              ▼                     ▼                       ▼
      ┌───────────────┐     ┌───────────────┐       ┌───────────────┐
      │FunctionalRole │     │FunctionalRole │       │FunctionalRole │
      │ (FI Display)  │     │ (PO Creator)  │◄─────►│ (GR Processor)│
      └───────┬───────┘     └───────┬───────┘       └───────┬───────┘
              │                     │  CONFLICTS_WITH       │
              │                     │                       │
              ▼                     ▼                       ▼
      ┌───────────────┐     ┌───────────────┐       ┌───────────────┐
      │  Transaction  │     │  Transaction  │       │  Transaction  │
      │   (FK10N)     │     │   (ME21N)     │       │   (MIGO)      │
      └───────┬───────┘     └───────┬───────┘       └───────┬───────┘
              │                     │                       │
              ▼                     ▼                       ▼
      ┌───────────────┐     ┌───────────────┐       ┌───────────────┐
      │  AuthObject   │     │  AuthObject   │       │  AuthObject   │
      │ (F_BKPF_BUK)  │     │ (M_BEST_EKG)  │       │ (M_MSEG_BWE)  │
      └───────────────┘     └───────────────┘       └───────────────┘
```

---

## SOD Rules & Conflict Detection

### Defined SOD Rules (from V3 Document)

| Rule ID | Functionality #1 | Functionality #2 | Risk Level | Description |
|---------|------------------|------------------|------------|-------------|
| SOD_0001 | Purchase Order Creation (ME21N) | Purchase Order Release/Approve (ME28) | HIGH | Prevent same user from creating and approving POs |
| SOD_0002 | Goods Receipt (MIGO) | Purchase Order Creation (ME21N) | HIGH | Prevent GR processor from creating POs |
| SOD_0003 | Goods Receipt (MIGO) | Purchase Order Release (ME28) | HIGH | Prevent GR processor from approving POs |
| SOD_0004 | Goods Receipt (MIGO) | Invoice Approval (Workflow) | HIGH | Prevent GR processor from approving invoices |
| SOD_0005 | Invoice Posting (MIRO) | Invoice Approval (Workflow) | HIGH | Prevent invoice poster from approving invoices |
| SOD_0006 | Invoice Approval (Workflow) | Purchase Order Creation (ME21N) | MEDIUM | Prevent budget approver from creating POs |

### Conflict Detection Cypher Queries

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// QUERY 1: Find all users with SOD violations
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)-[:CONTAINS_ROLE]->(fr1:FunctionalRole)
MATCH (u)-[:HAS_BUSINESS_ROLE]->(br2:BusinessRole)-[:CONTAINS_ROLE]->(fr2:FunctionalRole)
MATCH (fr1)-[c:CONFLICTS_WITH]->(fr2)
WHERE fr1 <> fr2
RETURN u.userId AS User, 
       u.firstName + ' ' + u.lastName AS Name,
       fr1.name AS Role1, 
       fr2.name AS Role2, 
       c.ruleId AS RuleViolated,
       c.riskLevel AS RiskLevel

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 2: Find PO Creator + PO Approver conflicts (SOD_0001)
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br1:BusinessRole)-[:CONTAINS_ROLE]->(fr1:FunctionalRole)
      -[:GRANTS_ACCESS_TO]->(t1:Transaction {tcode: 'ME21N'})
MATCH (u)-[:HAS_BUSINESS_ROLE]->(br2:BusinessRole)-[:CONTAINS_ROLE]->(fr2:FunctionalRole)
      -[:GRANTS_ACCESS_TO]->(t2:Transaction {tcode: 'ME28'})
RETURN u.userId AS User,
       u.country AS Country,
       br1.name AS CreatorRole,
       br2.name AS ApproverRole,
       'SOD_0001: PO Create vs Approve' AS Violation

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 3: Find users with critical transaction access
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)-[:CONTAINS_ROLE]->(fr:FunctionalRole)
      -[:GRANTS_ACCESS_TO]->(t:Transaction {isCritical: true})
RETURN u.userId AS User,
       u.function AS Function,
       u.country AS Country,
       collect(DISTINCT t.tcode) AS CriticalTransactions,
       count(DISTINCT t) AS CriticalCount
ORDER BY CriticalCount DESC

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 4: Detect anomalies - Users with roles outside their function
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)
WHERE NOT br.module CONTAINS u.function
  AND u.function IS NOT NULL
RETURN u.userId AS User,
       u.function AS UserFunction,
       br.name AS AssignedRole,
       br.module AS RoleModule,
       'Cross-Function Role Assignment' AS AnomalyType

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 5: Find users with roles in wrong country
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)-[:VALID_FOR_COUNTRY]->(c:Country)
WHERE u.countryCode <> c.isoCode
RETURN u.userId AS User,
       u.country AS UserCountry,
       br.name AS AssignedRole,
       c.name AS RoleCountry,
       'Country Mismatch' AS AnomalyType

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 6: Risk scoring - Users with multiple high-risk combinations
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)-[:CONTAINS_ROLE]->(fr:FunctionalRole)
      -[:GRANTS_ACCESS_TO]->(t:Transaction {isCritical: true})
WITH u, count(DISTINCT t) AS criticalCount
MATCH (u)-[:HAS_BUSINESS_ROLE]->(br2:BusinessRole)-[:CONTAINS_ROLE]->(fr2:FunctionalRole)
OPTIONAL MATCH (fr2)-[c:CONFLICTS_WITH]->(fr3:FunctionalRole)<-[:CONTAINS_ROLE]-(br3:BusinessRole)<-[:HAS_BUSINESS_ROLE]-(u)
WITH u, criticalCount, count(DISTINCT c) AS conflictCount
RETURN u.userId AS User,
       u.function AS Function,
       criticalCount AS CriticalTransactions,
       conflictCount AS SODConflicts,
       (criticalCount * 10 + conflictCount * 25) AS RiskScore
ORDER BY RiskScore DESC
LIMIT 20

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 7: Orphaned roles - Roles not assigned to any user
// ═══════════════════════════════════════════════════════════════════════════
MATCH (br:BusinessRole)
WHERE NOT EXISTS { MATCH (:User)-[:HAS_BUSINESS_ROLE]->(br) }
RETURN br.roleId AS RoleId,
       br.name AS RoleName,
       br.module AS Module,
       'Orphaned Role' AS Status

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 8: Users with excessive role assignments
// ═══════════════════════════════════════════════════════════════════════════
MATCH (u:User)-[:HAS_BUSINESS_ROLE]->(br:BusinessRole)
WITH u, count(br) AS roleCount, collect(br.name) AS roles
WHERE roleCount > 3
RETURN u.userId AS User,
       u.function AS Function,
       roleCount AS NumberOfRoles,
       roles AS AssignedRoles,
       'Excessive Roles' AS AnomalyType
ORDER BY roleCount DESC
```

---

## Use Cases

### Phase 1: Core SOD Detection (MVP)

| ID | Use Case | Description | Priority |
|----|----------|-------------|----------|
| 1.1 | Process & Ownership Mapping | Map processes to business units, cost centers, and identity attributes | HIGH |
| 1.2 | Identity to Role Mapping | Discover process lineage to business roles and transactions | HIGH |
| 1.3 | SOD Risk Assessment | Read SOD rulesets and identify conflicting entitlements | HIGH |
| 1.4 | Real-time Conflict Detection | Detect SOD violations at point of role assignment | HIGH |

### Phase 2: Advanced Analytics

| ID | Use Case | Description | Priority |
|----|----------|-------------|----------|
| 2.1 | NLP Query Interface | MS Teams integration for natural language queries | MEDIUM |
| 2.2 | Incidence Scoring | Generate risk scores for user-role combinations | MEDIUM |
| 2.3 | Ownership Updates | Prompt data/app owners for ownership updates | MEDIUM |
| 2.4 | Compliance Reporting | Generate audit-ready compliance reports | MEDIUM |

### Phase 3: Predictive & Auto-Remediation

| ID | Use Case | Description | Priority |
|----|----------|-------------|----------|
| 3.1 | Visual Knowledge Graph | Interactive graph visualization of access model | LOW |
| 3.2 | Remediation Workflows | Initiate remediation through graph interface | LOW |
| 3.3 | Predictive Access | ML-based prediction of appropriate role assignments | LOW |
| 3.4 | Auto-healing | Automatic remediation of low-risk violations | LOW |

### Persona-Based Use Cases

| Persona | Key Use Cases |
|---------|---------------|
| **End User** | Query own access, request new access, validate colleague access |
| **Process Owner** | Visualize access health, initiate remediation, approve changes |
| **Data/App Owner** | Review ownership, update configurations, approve access requests |
| **Auditor** | Monitor compliance, generate reports, investigate violations |
| **Administrator** | Configure rules, manage system, set access limits |

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

```
Week 1-2: Data Model & Infrastructure
├── Set up Neo4j database (AuraDB or self-hosted)
├── Define and create node labels and indexes
├── Create constraints for data integrity
└── Set up development environment

Week 3-4: Data Integration - Foundational Layer
├── Build Entra ID connector (Microsoft Graph API)
├── Build SuccessFactors connector (OData API)
├── Implement user data synchronization
└── Create organizational hierarchy in graph
```

### Phase 2: SAP Integration (Weeks 5-8)

```
Week 5-6: SAP Role & Authorization Data
├── Extract role definitions from SAP (AGR tables)
├── Extract transaction codes and auth objects
├── Map functional roles to transactions
└── Create role hierarchy in graph

Week 7-8: User-Role Assignments & SOD Rules
├── Import user-role assignments
├── Define SOD rules as graph relationships
├── Implement conflict detection queries
└── Create initial violation reports
```

### Phase 3: Analytics & Interface (Weeks 9-12)

```
Week 9-10: Detection & Reporting
├── Implement all SOD detection queries
├── Build risk scoring algorithm
├── Create anomaly detection queries
└── Develop compliance dashboards

Week 11-12: MVP Completion
├── Build basic API layer
├── Create sample visualizations
├── Document all queries and APIs
└── Prepare demo environment
```

### Deliverables by Phase

| Phase | Deliverables |
|-------|--------------|
| Phase 1 | Neo4j database with org structure, user data from Entra/SF |
| Phase 2 | Complete role hierarchy, SOD rules, conflict detection |
| Phase 3 | Working MVP with queries, basic UI, documentation |

---

## Technical Stack

### Core Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Graph Database | Neo4j (AuraDB or Enterprise) | Knowledge graph storage |
| Backend API | Python (FastAPI) or Node.js | API layer for queries |
| Data Integration | Apache Kafka / Azure Functions | Real-time data sync |
| Authentication | Microsoft Entra ID | SSO and authorization |
| Visualization | Neo4j Bloom / Custom React | Graph visualization |
| NLP Interface | Azure OpenAI / LangChain | Natural language queries |

### Integration Technologies

| Source System | Integration Method |
|---------------|-------------------|
| Microsoft Entra ID | Microsoft Graph API |
| SuccessFactors | OData API |
| SAP S4/HANA | RFC/BAPI, OData, or direct table extraction |
| LeanIX | REST API |
| Active Directory | LDAP / Microsoft Graph |

### Recommended Neo4j Configuration

```yaml
# Neo4j Configuration
neo4j:
  version: "5.x"
  edition: "enterprise"  # or AuraDB Professional
  
  # Memory settings (for self-hosted)
  heap_initial_size: "4G"
  heap_max_size: "8G"
  pagecache_size: "4G"
  
  # Plugins
  plugins:
    - apoc
    - graph-data-science
    
  # Indexes (create for performance)
  indexes:
    - "CREATE INDEX user_id FOR (u:User) ON (u.userId)"
    - "CREATE INDEX role_id FOR (r:BusinessRole) ON (r.roleId)"
    - "CREATE INDEX tcode FOR (t:Transaction) ON (t.tcode)"
    - "CREATE INDEX country_code FOR (c:Country) ON (c.code)"
```

---

## Getting Started

### Prerequisites

1. **Neo4j Database**
   - Neo4j Desktop (development) or
   - Neo4j AuraDB (cloud) or
   - Neo4j Enterprise (self-hosted)

2. **Python Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   pip install neo4j pandas openpyxl python-dotenv
   ```

3. **Access Credentials**
   - Microsoft Entra ID app registration
   - SuccessFactors API credentials
   - SAP system access (RFC user or OData)

### Quick Start

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd graph-dev
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

3. **Initialize Database**
   ```bash
   python scripts/init_database.py
   ```

4. **Load Sample Data**
   ```bash
   python scripts/load_sample_data.py
   ```

5. **Run SOD Detection**
   ```bash
   python scripts/detect_sod_violations.py
   ```

### Project Structure

```
graph-dev/
├── README.md                    # This documentation
├── docs/
│   ├── data_model.md           # Detailed data model
│   ├── sod_rules.md            # SOD rule definitions
│   └── api_reference.md        # API documentation
├── scripts/
│   ├── init_database.py        # Database initialization
│   ├── load_sample_data.py     # Sample data loader
│   ├── detect_sod_violations.py # SOD detection
│   └── connectors/
│       ├── entra_connector.py  # Entra ID integration
│       ├── sap_connector.py    # SAP integration
│       └── sf_connector.py     # SuccessFactors integration
├── cypher/
│   ├── schema.cypher           # Schema definitions
│   ├── constraints.cypher      # Constraints and indexes
│   ├── sod_rules.cypher        # SOD rule creation
│   └── queries/
│       ├── sod_detection.cypher
│       ├── anomaly_detection.cypher
│       └── reporting.cypher
├── data/
│   ├── sample/                 # Sample data files
│   └── mappings/               # Data mapping configurations
├── tests/
│   └── test_sod_detection.py   # Unit tests
└── requirements.txt            # Python dependencies
```

---

## Appendix

### A. Country/Entity Code Mapping

| Entity Code | ISO Code | Country | Region |
|-------------|----------|---------|--------|
| 1000 | UK | United Kingdom | EMEA |
| 2000 | US | United States | Americas |
| 3000 | AE | United Arab Emirates | EMEA |
| 4000 | DE | Germany | EMEA |
| 5000 | IN | India | APAC |
| 6000 | RU | Russia | EMEA |
| 7000 | CN | China | APAC |
| 8000 | AU | Australia | APAC |
| 9000 | SG | Singapore | APAC |
| A000 | ZA | South Africa | EMEA |
| B000 | KZ | Kazakhstan | EMEA |

### B. Role Naming Convention

```
Business Roles:    ZC:<Module>:<Role_Name>:<Entity_Code>
Functional Roles:  ZRM:<Module>:<Role_Name>:0000 (Master)
                   ZRD:<Module>:<Role_Name>:0000 (Display Master)
Derived Roles:     ZDM:<Module>:<Role_Name>:<Entity_Code> (Maintain)
                   ZDD:<Module>:<Role_Name>:<Entity_Code> (Display)
```

### C. Business Role Assignment Logic

| Business Role | Region Specific | Function | Org Level |
|---------------|-----------------|----------|-----------|
| Finance Manager | Yes | Finance | L2 |
| S&D Analyst | Yes | Sales & Marketing | L4 |
| Warehouse Manager | Yes | Manufacturing | L3 |
| PO Creator | Yes | Procurement | L4 |
| PO Releaser | Yes | Procurement | L4 |
| GR Processor | Yes | Finance | L4 |
| AP Clerk | Yes | Finance | L4 |
| Budget Approver | Yes | Finance | L2 |

### D. Critical Transactions

| Transaction | Description | Module | Risk Level |
|-------------|-------------|--------|------------|
| AJAB | Year-end closing | FI | HIGH |
| ME21N | Purchase Order Creation | MM | HIGH |
| ME28 | PO Approver | MM | HIGH |
| MIGO | Goods Receipt | MM | HIGH |
| MIRO | Invoice Posting | MM | HIGH |
| Workflow | Budget Approval | WF | HIGH |

---

## Identity Confidence Percentage & Predictive Access

### Overview

The Identity Confidence Percentage is a calculated score that determines how likely a user should have a specific role or access based on their identity attributes, organizational context, and peer analysis. This enables predictive access recommendations and anomaly detection.

### Confidence Score Calculation

The confidence score is calculated using multiple weighted criteria:

```
Identity Confidence % = Σ (Criterion Weight × Criterion Score) / Total Weight × 100
```

### Scoring Criteria & Weights

| Criterion | Weight | Description | Score Range |
|-----------|--------|-------------|-------------|
| **Function Match** | 30% | User's function matches role's intended function | 0-100 |
| **Country/Entity Match** | 20% | User's country matches role's country derivation | 0-100 |
| **Org Level Match** | 15% | User's org level (L1-L4) matches role's typical level | 0-100 |
| **Department Match** | 10% | User's department aligns with role's module | 0-100 |
| **Peer Analysis** | 15% | % of peers with same function/level who have this role | 0-100 |
| **Historical Usage** | 10% | User's actual usage of transactions in the role | 0-100 |

### Confidence Score Interpretation

| Score Range | Interpretation | Action |
|-------------|----------------|--------|
| **90-100%** | High Confidence | Auto-approve role assignment |
| **70-89%** | Medium Confidence | Standard approval workflow |
| **50-69%** | Low Confidence | Enhanced review required |
| **Below 50%** | Anomaly | Flag for investigation |

### Cypher Query: Calculate Identity Confidence

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// IDENTITY CONFIDENCE SCORE CALCULATION
// ═══════════════════════════════════════════════════════════════════════════

// Calculate confidence score for a user-role combination
WITH $userId AS userId, $roleId AS roleId

// Get user attributes
MATCH (u:User {userId: userId})
MATCH (br:BusinessRole {roleId: roleId})

// Function Match Score (30%)
WITH u, br,
     CASE WHEN br.module CONTAINS u.function OR u.function CONTAINS br.module 
          THEN 100 ELSE 0 END AS functionScore

// Country Match Score (20%)
OPTIONAL MATCH (br)-[:VALID_FOR_COUNTRY]->(c:Country)
WITH u, br, functionScore,
     CASE WHEN u.countryCode = c.isoCode THEN 100
          WHEN c IS NULL THEN 50  // Master role, partial match
          ELSE 0 END AS countryScore

// Org Level Match Score (15%)
WITH u, br, functionScore, countryScore,
     CASE 
       WHEN br.module = 'FIN' AND u.level IN ['L2'] THEN 100
       WHEN br.module = 'P2P' AND u.level IN ['L4'] THEN 100
       WHEN br.module = 'S&D' AND u.level IN ['L4'] THEN 100
       WHEN br.module = 'DFE' AND u.level IN ['L3'] THEN 100
       ELSE 50 
     END AS levelScore

// Peer Analysis Score (15%)
OPTIONAL MATCH (peer:User)-[:HAS_BUSINESS_ROLE]->(br)
WHERE peer.function = u.function AND peer.level = u.level AND peer.userId <> u.userId
WITH u, br, functionScore, countryScore, levelScore,
     CASE WHEN count(peer) > 0 THEN 100 ELSE 30 END AS peerScore

// Calculate Final Confidence Score
WITH u, br,
     (functionScore * 0.30 + 
      countryScore * 0.20 + 
      levelScore * 0.15 + 
      peerScore * 0.15 + 
      50 * 0.10 +  // Department match (default 50)
      50 * 0.10    // Historical usage (default 50)
     ) AS confidenceScore

RETURN u.userId AS User,
       u.firstName + ' ' + u.lastName AS Name,
       u.function AS Function,
       u.level AS Level,
       u.country AS Country,
       br.roleId AS RoleId,
       br.name AS RoleName,
       round(confidenceScore, 2) AS ConfidencePercentage,
       CASE 
         WHEN confidenceScore >= 90 THEN 'HIGH - Auto Approve'
         WHEN confidenceScore >= 70 THEN 'MEDIUM - Standard Approval'
         WHEN confidenceScore >= 50 THEN 'LOW - Enhanced Review'
         ELSE 'ANOMALY - Investigation Required'
       END AS Recommendation
```

### Predictive Role Recommendations

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// RECOMMEND ROLES FOR A USER BASED ON IDENTITY ATTRIBUTES
// ═══════════════════════════════════════════════════════════════════════════

MATCH (u:User {userId: $userId})
MATCH (br:BusinessRole)
WHERE br.status = 'ACTIVE'

// Calculate match scores
OPTIONAL MATCH (br)-[:VALID_FOR_COUNTRY]->(c:Country {isoCode: u.countryCode})
WITH u, br, c,
     CASE WHEN br.module CONTAINS u.function THEN 30 ELSE 0 END AS funcScore,
     CASE WHEN c IS NOT NULL THEN 20 ELSE 0 END AS countryScore

// Check peer assignments
OPTIONAL MATCH (peer:User)-[:HAS_BUSINESS_ROLE]->(br)
WHERE peer.function = u.function 
  AND peer.level = u.level 
  AND peer.countryCode = u.countryCode
  AND peer.userId <> u.userId
WITH u, br, funcScore, countryScore, count(peer) AS peerCount

// Calculate recommendation score
WITH u, br, 
     funcScore + countryScore + 
     CASE WHEN peerCount > 5 THEN 25 
          WHEN peerCount > 0 THEN 15 
          ELSE 0 END AS totalScore,
     peerCount

WHERE totalScore > 40
  AND NOT EXISTS { MATCH (u)-[:HAS_BUSINESS_ROLE]->(br) }

RETURN br.roleId AS RecommendedRole,
       br.name AS RoleName,
       br.module AS Module,
       totalScore AS MatchScore,
       peerCount AS PeersWithRole,
       'Based on function, country, and peer analysis' AS Reason
ORDER BY totalScore DESC
LIMIT 5
```

---

## SAP Data Points Required

### Overview

The following SAP tables and data points are required to build the knowledge graph and enable SOD detection, identity confidence scoring, and access analytics.

### SAP Tables & Data Extraction

#### 1. User Master Data

| Table | Description | Key Fields | Usage |
|-------|-------------|------------|-------|
| **USR02** | User Logon Data | BNAME, USTYP, CLASS, GLTGV, GLTGB | User status, validity dates |
| **USR21** | User Address Keys | BNAME, PERSNUMBER, ADDRNUMBER | Link to address/HR data |
| **ADRP** | Person Address | PERSNUMBER, NAME_FIRST, NAME_LAST | User names |
| **USR06** | Additional User Data | BNAME, LIC_TYPE | License type |

**Extraction Query (SE16/SQL):**
```sql
SELECT u.BNAME, u.USTYP, u.CLASS, u.GLTGV, u.GLTGB,
       a.NAME_FIRST, a.NAME_LAST
FROM USR02 u
JOIN USR21 u21 ON u.BNAME = u21.BNAME
JOIN ADRP a ON u21.PERSNUMBER = a.PERSNUMBER
WHERE u.USTYP = 'A'  -- Dialog users
  AND u.GLTGB >= CURRENT_DATE
```

#### 2. Role Definitions

| Table | Description | Key Fields | Usage |
|-------|-------------|------------|-------|
| **AGR_DEFINE** | Role Definition | AGR_NAME, PARENT_AGR | Role names, composite structure |
| **AGR_1251** | Role Authorization Data | AGR_NAME, OBJECT, AUTH, FIELD, LOW, HIGH | Auth object values |
| **AGR_TEXTS** | Role Descriptions | AGR_NAME, TEXT | Role descriptions |
| **AGR_AGRS** | Composite Role Contents | AGR_NAME, CHILD_AGR | Child roles in composite |

**Extraction Query:**
```sql
SELECT d.AGR_NAME, d.PARENT_AGR, t.TEXT,
       a.OBJECT, a.AUTH, a.FIELD, a.LOW, a.HIGH
FROM AGR_DEFINE d
LEFT JOIN AGR_TEXTS t ON d.AGR_NAME = t.AGR_NAME AND t.SPRAS = 'E'
LEFT JOIN AGR_1251 a ON d.AGR_NAME = a.AGR_NAME
WHERE d.AGR_NAME LIKE 'Z%'  -- Custom roles
```

#### 3. User-Role Assignments

| Table | Description | Key Fields | Usage |
|-------|-------------|------------|-------|
| **AGR_USERS** | User Role Assignments | AGR_NAME, UNAME, FROM_DAT, TO_DAT | Active assignments |
| **AGR_PROF** | Role Profiles | AGR_NAME, PROFILE | Generated profiles |

**Extraction Query:**
```sql
SELECT AGR_NAME, UNAME, FROM_DAT, TO_DAT, 
       CHANGE_DAT, CHANGE_TIM, CHANGE_USR
FROM AGR_USERS
WHERE TO_DAT >= CURRENT_DATE
  AND AGR_NAME LIKE 'Z%'
ORDER BY UNAME, AGR_NAME
```

#### 4. Transaction Codes

| Table | Description | Key Fields | Usage |
|-------|-------------|------------|-------|
| **TSTC** | Transaction Codes | TCODE, PGMNA, DESSION | Transaction definitions |
| **TSTCT** | Transaction Texts | TCODE, TTEXT | Transaction descriptions |
| **USOBT** | Transaction-Auth Object Relation | NAME, OBJECT, FIELD | Required auth objects |
| **USOBX** | Check Indicator | NAME, OBJECT | Active checks |

**Extraction Query:**
```sql
SELECT t.TCODE, tt.TTEXT, t.PGMNA,
       u.OBJECT, u.FIELD
FROM TSTC t
JOIN TSTCT tt ON t.TCODE = tt.TCODE AND tt.SPRSL = 'E'
LEFT JOIN USOBT u ON t.TCODE = u.NAME
WHERE t.TCODE IN ('ME21N','ME28','MIGO','MIRO','VA01','VA02','VA03')
```

#### 5. Authorization Objects

| Table | Description | Key Fields | Usage |
|-------|-------------|------------|-------|
| **TOBJ** | Authorization Objects | OBJCT, FIEL1-FIEL10 | Object definitions |
| **TOBJT** | Object Texts | OBJCT, TTEXT | Object descriptions |
| **TACTZ** | Activity Values | ACTVT, ACTXT | Activity descriptions |

**Extraction Query:**
```sql
SELECT o.OBJCT, ot.TTEXT, o.FIEL1, o.FIEL2, o.FIEL3
FROM TOBJ o
JOIN TOBJT ot ON o.OBJCT = ot.OBJCT AND ot.LANGU = 'E'
WHERE o.OBJCT LIKE 'M_%' OR o.OBJCT LIKE 'F_%'
```

#### 6. Usage/Activity Logs (Optional - for Historical Analysis)

| Table | Description | Key Fields | Usage |
|-------|-------------|------------|-------|
| **STAD** | Statistical Records | TCODE, ACCOUNT, STARTDATE | Transaction usage |
| **SM21** | System Log | USER, TCODE, DATE, TIME | User activity |
| **CDHDR/CDPOS** | Change Documents | OBJECTCLAS, OBJECTID, CHANGENR | Change history |

### Data Extraction Methods

#### Method 1: RFC/BAPI (Recommended for Real-time)

```python
# Python example using pyrfc
from pyrfc import Connection

conn = Connection(
    ashost='sap-server.company.com',
    sysnr='00',
    client='100',
    user='RFC_USER',
    passwd='password'
)

# Read user-role assignments
result = conn.call('BAPI_USER_GET_DETAIL', USERNAME='JSMITH')
roles = result['ACTIVITYGROUPS']
```

#### Method 2: OData Services (SAP Gateway)

```
# OData endpoints to configure in SAP Gateway
/sap/opu/odata/sap/API_USER_ROLE_ASSIGNMENT_SRV/
/sap/opu/odata/sap/API_BUSINESS_ROLE_SRV/
```

#### Method 3: Direct Table Extraction (Batch)

```sql
-- Export to CSV for batch loading
SELECT * FROM AGR_USERS INTO OUTFILE '/tmp/agr_users.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

### SAP Data Mapping to Graph Nodes

| SAP Source | Graph Node | Key Mapping |
|------------|------------|-------------|
| USR02 + ADRP | User | BNAME → userId |
| AGR_DEFINE (PARENT_AGR IS NULL) | BusinessRole | AGR_NAME → roleId |
| AGR_DEFINE (PARENT_AGR IS NOT NULL) | FunctionalRole | AGR_NAME → roleId |
| AGR_USERS | HAS_BUSINESS_ROLE relationship | AGR_NAME + UNAME |
| TSTC + TSTCT | Transaction | TCODE → tcode |
| TOBJ + TOBJT | AuthObject | OBJCT → objectId |
| AGR_1251 | GRANTS_AUTH relationship | AGR_NAME + OBJECT |
| USOBT | REQUIRES_AUTH relationship | NAME + OBJECT |

### Required SAP Authorizations for Extraction

The RFC user needs the following authorizations:

| Auth Object | Field | Value | Description |
|-------------|-------|-------|-------------|
| S_RFC | RFC_TYPE | FUGR | Function group access |
| S_RFC | RFC_NAME | SYST, BAPI* | Required function modules |
| S_TABU_DIS | DICBERCLS | SS, SC | Table access |
| S_USER_GRP | CLASS | * | User group access |
| S_USER_AGR | ACTVT | 03 | Display role assignments |

### Data Refresh Frequency

| Data Type | Recommended Frequency | Rationale |
|-----------|----------------------|-----------|
| User Master | Daily | User changes are frequent |
| Role Definitions | Weekly | Roles change less frequently |
| User-Role Assignments | Daily | Critical for SOD detection |
| Transaction Codes | Monthly | Rarely change |
| Usage Logs | Weekly | For trend analysis |

---

## References

- [Neo4j Documentation](https://neo4j.com/docs/)
- [Microsoft Graph API](https://docs.microsoft.com/en-us/graph/)
- [SAP Authorization Concept](https://help.sap.com/docs/)
- [ISACA SOD Guidelines](https://www.isaca.org/)

---

## License

Copyright © 2024 Pax Identity. All rights reserved.

---

## Contact

For questions or support, contact the Pax Identity team at [support@paxidentity.com](mailto:support@paxidentity.com)
