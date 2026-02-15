# Data Requirements Analysis
## Enterprise Knowledge Graph (EKG) - Required Datasets from SAP and Entra ID

---

## Table of Contents

1. [Overview](#overview)
2. [Data Sources Summary](#data-sources-summary)
3. [Entra ID (Azure AD) Data Requirements](#entra-id-azure-ad-data-requirements)
4. [SAP S4/HANA Data Requirements](#sap-s4hana-data-requirements)
5. [SuccessFactors Data Requirements](#successfactors-data-requirements)
6. [Data Analysis from V3 Excel](#data-analysis-from-v3-excel)
7. [Data Mapping & Transformation](#data-mapping--transformation)

---

## Overview

This document analyzes the data requirements for the Enterprise Knowledge Graph based on the V3 Authorization Matrix Excel file and defines the exact datasets needed from each source system.

### Source Systems

| System | Purpose | Data Type |
|--------|---------|-----------|
| **Entra ID (Azure AD)** | Identity Provider | Users, Groups, Authentication |
| **SAP S4/HANA** | ERP System | Roles, Transactions, Authorizations |
| **SuccessFactors** | HR System | Org Structure, Job Catalog |
| **LeanIX/Signavio** | Process Inventory | Process Ownership |

---

## Data Sources Summary

### From V3 Excel Analysis

The V3 Excel file contains the following sheets with critical data:

| Sheet Name | Records | Key Data |
|------------|---------|----------|
| **User Mapping** | 127 users | User attributes, role assignments |
| **Business Role Template** | 8 business roles | Role-to-functional role mapping |
| **Functional Role Matrix** | 11 functional roles | Role-to-transaction mapping |
| **Derive Role Matrix** | 110 derived roles | Country-specific role derivations |
| **Business Roles** | 8 roles | Assignment and approval logic |

---

## Entra ID (Azure AD) Data Requirements

### Required User Attributes

Based on the User Mapping sheet analysis, the following attributes are needed from Entra ID:

| Entra ID Attribute | V3 Excel Column | Graph Property | Required |
|--------------------|-----------------|----------------|----------|
| `id` | - | User.entraId | Yes |
| `userPrincipalName` | userName | User.userId | Yes |
| `givenName` | FirstName | User.firstName | Yes |
| `surname` | familyName | User.lastName | Yes |
| `displayName` | - | User.displayName | Yes |
| `mail` | - | User.email | Yes |
| `jobTitle` | - | User.jobTitle | No |
| `department` | Department | User.department | Yes |
| `officeLocation` | City | User.city | No |
| `country` | Country | User.country | Yes |
| `companyName` | - | User.company | No |
| `manager.id` | - | User.managerId | Yes |
| `accountEnabled` | - | User.status | Yes |

### Required Group Data

| Entra ID Attribute | Graph Property | Purpose |
|--------------------|----------------|---------|
| `id` | Group.groupId | Unique identifier |
| `displayName` | Group.name | Group name |
| `description` | Group.description | Group description |
| `groupTypes` | Group.type | Security/M365 |
| `members` | MEMBER_OF relationship | User membership |

### Microsoft Graph API Queries

```http
# Get all users with required attributes
GET https://graph.microsoft.com/v1.0/users
    ?$select=id,userPrincipalName,givenName,surname,displayName,mail,
             jobTitle,department,officeLocation,country,companyName,accountEnabled
    &$expand=manager($select=id,displayName)
    &$filter=accountEnabled eq true

# Get all security groups
GET https://graph.microsoft.com/v1.0/groups
    ?$select=id,displayName,description,groupTypes,securityEnabled
    &$filter=securityEnabled eq true

# Get group members
GET https://graph.microsoft.com/v1.0/groups/{group-id}/members
    ?$select=id,userPrincipalName,displayName
```

### Entra ID Export Format (Expected CSV)

```csv
id,userPrincipalName,givenName,surname,displayName,mail,jobTitle,department,officeLocation,country,companyName,managerId,accountEnabled
abc123,jdevlin@company.com,Jillian,Devlin,Jillian Devlin,jdevlin@company.com,Sales Analyst,Sales & Marketing,New York,United States,XYZ Corp,mgr456,true
```

---

## SAP S4/HANA Data Requirements

### Based on V3 Excel Analysis

#### 1. Transaction Codes (from Functional Role Matrix)

| TCode | Description | Module | Access Type | Critical |
|-------|-------------|--------|-------------|----------|
| AJAB | Year-end closing | FI | Maintain | Yes |
| AIFND_XC_SLG1 | Monitor error | FI | Display | No |
| FSP0 | Display GL Account | FI | Display | No |
| FK10N | Vendor Balance Display | FI | Display | No |
| FI03 | Display Bank Directory | FI | Display | No |
| VA03 | Display Sales Order | SD | Display | No |
| VA01 | Create Sales Order | SD | Maintain | No |
| VA02 | Edit Sales Order | SD | Maintain | No |
| MD04 | Current Stock list | MM | Display | No |
| LT01 | Create Transfer order | MM | Maintain | No |
| ME21N | Purchase Order Creation | MM | Maintain | Yes |
| ME28 | PO Approver | MM | Maintain | Yes |
| MIGO | Goods Receipt | MM | Maintain | Yes |
| MIRO | Posting or Parking Invoice | MM | Maintain | Yes |

#### 2. Functional Roles (from Functional Role Matrix)

| Role ID | Description | Type | Module |
|---------|-------------|------|--------|
| ZRM:FI_:PERD_END_CLOSING_:0000 | FI - Period END Closing - Master | Maintain | FI |
| ZRD:FI_:DISPLAY_FINANCE__:0000 | FI - Display Finance - Master | Display | FI |
| ZRD:SD_:Display_Sales____:0000 | SD - Display Sales - Master | Display | SD |
| ZRM:SD_:REQUISITIONER____:0000 | SD - Requisitioner - Master | Maintain | SD |
| ZRD:DFE:Display_Plant____:0000 | DFE - Display - Master | Display | DFE |
| ZRM:DFE:Warehouse_Admin__:0000 | DFE - Warehouse - Master | Maintain | DFE |
| ZRM:P2P:PO_CREATOR_______:0000 | P2P - PO Creator - Master | Maintain | P2P |
| ZRM:P2P:PO_RELEASER______:0000 | P2P - PO Releaser - Master | Maintain | P2P |
| ZRM:FI_:GR_PROCESSOR_____:0000 | FI - GR Processor - Master | Maintain | FI |
| ZRM:FI_:AP_CLERK_________:0000 | FI - AP CLERK - Master | Maintain | FI |
| ZRM:FI_:Budget_Approver__:0000 | FI - Budget Approver - Master | Maintain | FI |

#### 3. Business Roles (from Business Role Template)

| Role ID | Description | Module |
|---------|-------------|--------|
| ZC:FIN:FINANCE_MANAGER___:0000 | FIN - Finance Manager - Master | FIN |
| ZC:S&D:SALES_ANALYST_____:0000 | S&D - Sales Analyst - Master | S&D |
| ZC:DFE:WAREHOUSE_MANAGER_:0000 | DFE - Warehouse Manager - Master | DFE |
| ZC:P2P:PO_CREATOR________:0000 | P2P - PO-Creator - Master | P2P |
| ZC:P2P:PO_Releaser_______:0000 | P2P - PO-Releaser - Master | P2P |
| ZC:FIN:GR_PROCESSOR______:0000 | FIN - GR - Processor - Master | FIN |
| ZC:FIN:AP_CLERK__________:0000 | FIN - AP-Clerk - Master | FIN |
| ZC:FIN:BUDGET_APPROVER___:0000 | FIN - Budget-Approver - Master | FIN |

#### 4. Country/Entity Codes (from Derive Role Matrix)

| Entity Code | Country | ISO Code |
|-------------|---------|----------|
| 1000 | United Kingdom | UK |
| 2000 | United States | US |
| 3000 | United Arab Emirates | AE |
| 4000 | Germany | DE |
| 5000 | India | IN |
| 6000 | Russia | RU |
| 7000 | China | CN |
| 8000 | Australia | AU |
| 9000 | Singapore | SG |
| A000 | South Africa | ZA |
| B000 | Kazakhstan | KZ |

### SAP Tables Required

| Table | Data | Export Format |
|-------|------|---------------|
| AGR_DEFINE | Role definitions | CSV |
| AGR_USERS | User-role assignments | CSV |
| AGR_1251 | Role authorizations | CSV |
| AGR_AGRS | Composite role structure | CSV |
| TSTC/TSTCT | Transaction codes | CSV |
| USR02 | User master | CSV |

---

## SuccessFactors Data Requirements

### Required Employee Attributes

Based on the User Mapping sheet:

| SF Attribute | V3 Excel Column | Graph Property | Required |
|--------------|-----------------|----------------|----------|
| userId | userName | User.userId | Yes |
| firstName | FirstName | User.firstName | Yes |
| lastName | familyName | User.lastName | Yes |
| department | Department | User.department | Yes |
| division | Function | User.function | Yes |
| location | City | User.city | Yes |
| country | Country | User.country | Yes |
| jobCode | Level | User.level | Yes |
| managerId | - | User.managerId | Yes |
| costCenter | - | User.costCenter | No |

### Function Mapping (from V3 Excel)

| Function Value | Standardized Function |
|----------------|----------------------|
| Sales & Marketing | Sales & Marketing |
| Manufacturing | Manufacturing |
| Procurement & Supply Chain | Procurement & Supply Chain |
| Finance | Finance |

### Level Mapping (from Business Roles sheet)

| Level | Description | Typical Roles |
|-------|-------------|---------------|
| L1 | Executive | - |
| L2 | Senior Manager | Finance Manager, Budget Approver |
| L3 | Manager | Warehouse Manager |
| L4 | Individual Contributor | Analyst, Creator, Clerk |

---

## Data Analysis from V3 Excel

### User Distribution Analysis

#### By Country
| Country | User Count | Percentage |
|---------|------------|------------|
| United States | 68 | 53.5% |
| India | 23 | 18.1% |
| South Africa | 14 | 11.0% |
| Kazakhstan | 14 | 11.0% |
| United Kingdom | 5 | 3.9% |
| Germany | 1 | 0.8% |
| China | 2 | 1.6% |

#### By Function
| Function | User Count | Percentage |
|----------|------------|------------|
| Procurement & Supply Chain | 103 | 81.1% |
| Manufacturing | 20 | 15.7% |
| Sales & Marketing | 4 | 3.1% |
| Finance | 1 | 0.8% |

#### By Role Assignment
| Business Role | User Count |
|---------------|------------|
| PO Creator | 103 |
| Warehouse Manager | 20 |
| Sales Analyst | 4 |
| Finance Manager | 1 |

### Role Hierarchy Analysis

```
Business Role (Composite)
└── Functional Role (Master)
    └── Derived Role (Country-specific)
        └── Transactions
            └── Authorization Objects
```

#### Example: Finance Manager Role Hierarchy

```
ZC:FIN:FINANCE_MANAGER___:1000 (Business Role - UK)
├── ZDM:FI_:PERD_END_CLOSING_:1000 (Derived from ZRM:FI_:PERD_END_CLOSING_:0000)
│   └── AJAB (Year-end closing)
│       └── Auth Objects: F_BKPF_*, F_FAGL_*
└── ZDD:FI_:DISPLAY_FINANCE__:1000 (Derived from ZRD:FI_:DISPLAY_FINANCE__:0000)
    ├── FSP0 (Display GL Account)
    ├── FK10N (Vendor Balance Display)
    └── FI03 (Display Bank Directory)
```

---

## Data Mapping & Transformation

### User Data Transformation

```python
# Mapping from V3 Excel to Graph Node
user_mapping = {
    'familyName': 'lastName',
    'FirstName': 'firstName',
    'userName': 'userId',
    'City': 'city',
    'Country': 'country',
    'Function': 'function',
    'Department': 'department',
    'Level': 'level',
    'SAP Role ID': 'businessRoleId'
}

# Country to ISO Code mapping
country_to_iso = {
    'United States': 'US',
    'United Kingdom': 'UK',
    'United Arab Emirates': 'AE',
    'Germany': 'DE',
    'India': 'IN',
    'Russia': 'RU',
    'China': 'CN',
    'Australia': 'AU',
    'Singapore': 'SG',
    'South Africa': 'ZA',
    'Kazakhstan': 'KZ'
}

# Entity code mapping
iso_to_entity = {
    'UK': '1000',
    'US': '2000',
    'AE': '3000',
    'DE': '4000',
    'IN': '5000',
    'RU': '6000',
    'CN': '7000',
    'AU': '8000',
    'SG': '9000',
    'ZA': 'A000',
    'KZ': 'B000'
}
```

### Role Data Transformation

```python
# Role type detection from role ID
def get_role_type(role_id):
    if role_id.startswith('ZC:'):
        return 'BUSINESS'
    elif role_id.startswith('ZRM:'):
        return 'FUNCTIONAL_MAINTAIN'
    elif role_id.startswith('ZRD:'):
        return 'FUNCTIONAL_DISPLAY'
    elif role_id.startswith('ZDM:'):
        return 'DERIVED_MAINTAIN'
    elif role_id.startswith('ZDD:'):
        return 'DERIVED_DISPLAY'
    return 'OTHER'

# Module extraction from role ID
def get_module(role_id):
    parts = role_id.split(':')
    if len(parts) >= 2:
        module_code = parts[1].strip('_')
        module_map = {
            'FIN': 'Finance',
            'FI_': 'Finance',
            'S&D': 'Sales & Distribution',
            'SD_': 'Sales & Distribution',
            'DFE': 'Plant/Warehouse',
            'P2P': 'Procure to Pay'
        }
        return module_map.get(module_code, module_code)
    return 'Unknown'
```

---

## Summary of Required Data Exports

### From Entra ID

| Export | Format | Fields | Frequency |
|--------|--------|--------|-----------|
| Users | CSV/JSON | id, upn, name, department, country, manager | Daily |
| Groups | CSV/JSON | id, name, type, members | Weekly |
| Group Memberships | CSV/JSON | userId, groupId | Daily |

### From SAP S4/HANA

| Export | Format | Source Table | Frequency |
|--------|--------|--------------|-----------|
| Users | CSV | USR02 + ADRP | Daily |
| Roles | CSV | AGR_DEFINE | Weekly |
| Role Assignments | CSV | AGR_USERS | Daily |
| Role Authorizations | CSV | AGR_1251 | Weekly |
| Transactions | CSV | TSTC + TSTCT | Monthly |

### From SuccessFactors

| Export | Format | API Endpoint | Frequency |
|--------|--------|--------------|-----------|
| Employees | CSV/JSON | /odata/v2/User | Daily |
| Org Structure | CSV/JSON | /odata/v2/Position | Weekly |
| Job Catalog | CSV/JSON | /odata/v2/JobCode | Monthly |

---

## Next Steps

1. **Set up data connectors** for each source system
2. **Create ETL pipelines** for data transformation
3. **Load data into Neo4j** using the defined schema
4. **Validate data quality** and relationships
5. **Run SOD detection queries** to verify implementation