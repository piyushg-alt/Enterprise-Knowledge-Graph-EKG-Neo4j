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

// ═══════════════════════════════════════════════════════════════════════════
// PROCESS HIERARCHY NODES
// ═══════════════════════════════════════════════════════════════════════════

// L1 Process - Top level process

// L2 Process - Sub-process


// ═══════════════════════════════════════════════════════════════════════════
// SOD & COMPLIANCE NODES
// ═══════════════════════════════════════════════════════════════════════════
})

// SOD Conflict (Detected Violation)

```

### Relationships

```cypher
// ═══════════════════════════════════════════════════════════════════════════
// USER RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ROLE HIERARCHY RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// AUTHORIZATION RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// PROCESS RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// SOD RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════════
// OWNERSHIP RELATIONSHIPS
// ═══════════════════════════════════════════════════════════════════════════

```

### Visual Graph Model
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
// Cypher QUERY 1: Find all users with SOD violations
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// QUERY 2: Find PO Creator + PO Approver conflicts (SOD_0001)
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Cypher QUERY 3: Find users with critical transaction access
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Cypher QUERY 4: Detect anomalies - Users with roles outside their function
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Cypher QUERY 5: Find users with roles in wrong country
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Cypher QUERY 6: Risk scoring - Users with multiple high-risk combinations
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
//Cypher QUERY 7: Orphaned roles - Roles not assigned to any user
// ═══════════════════════════════════════════════════════════════════════════

// Cypher QUERY 8: Users with excessive role assignments - Cypher Query

---

## Use Cases

###  Core SOD Detection 

### Phase 2: Advanced Analyticsv-If required 

### Phase 3: Predictive & Auto-Remediation


### Persona-Based Use Cases














