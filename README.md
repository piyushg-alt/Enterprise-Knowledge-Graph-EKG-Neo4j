# Enterprise Knowledge Graph (EKG) for Identity & Access Management
## Anomaly Detection using Neo4j

### Project Overview

This project implements a Neo4j-based Knowledge Graph solution for detecting Segregation of Duties (SOD) violations and access anomalies in enterprise identity management systems. The solution integrates data from multiple authoritative sources including SAP S4/HANA, Microsoft Entra ID (Azure AD), and process inventory systems.

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

## Data Flow

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
---

### 2. SAP S4/HANA
**Purpose**: System of record for business transactions and authorizations

| Data Type | Tables/Sources | Description |
|-----------|----------------|-------------|
| Users | USR02, USR21 | SAP user master data |
| Roles | AGR_DEFINE, AGR_1251 | Role definitions |
| Role Assignments | AGR_USERS | User-role mappings |
| Transactions | TSTC, TSTCT | Transaction codes |
| Auth Objects | USOBT, USOBX | Authorization objects |
| Composite Roles | AGR_AGRS | Role hierarchies |

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














