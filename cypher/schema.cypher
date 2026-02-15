// ═══════════════════════════════════════════════════════════════════════════
// NEO4J SCHEMA FOR EKG - IDENTITY & ACCESS MANAGEMENT
// SOD Anomaly Detection Graph Database Schema
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// CONSTRAINTS - Ensure data integrity
// ═══════════════════════════════════════════════════════════════════════════

// User constraints
CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.userId IS UNIQUE;

// Country constraints
CREATE CONSTRAINT country_code_unique IF NOT EXISTS
FOR (c:Country) REQUIRE c.code IS UNIQUE;

CREATE CONSTRAINT country_iso_unique IF NOT EXISTS
FOR (c:Country) REQUIRE c.isoCode IS UNIQUE;

// Function constraints
CREATE CONSTRAINT function_code_unique IF NOT EXISTS
FOR (f:Function) REQUIRE f.code IS UNIQUE;

// Role constraints
CREATE CONSTRAINT business_role_id_unique IF NOT EXISTS
FOR (br:BusinessRole) REQUIRE br.roleId IS UNIQUE;

CREATE CONSTRAINT functional_role_id_unique IF NOT EXISTS
FOR (fr:FunctionalRole) REQUIRE fr.roleId IS UNIQUE;

CREATE CONSTRAINT derived_role_id_unique IF NOT EXISTS
FOR (dr:DerivedRole) REQUIRE dr.roleId IS UNIQUE;

// Transaction constraints
CREATE CONSTRAINT transaction_tcode_unique IF NOT EXISTS
FOR (t:Transaction) REQUIRE t.tcode IS UNIQUE;

// Authorization Object constraints
CREATE CONSTRAINT auth_object_id_unique IF NOT EXISTS
FOR (ao:AuthObject) REQUIRE ao.objectId IS UNIQUE;

// Process constraints
CREATE CONSTRAINT l1_process_id_unique IF NOT EXISTS
FOR (p:L1Process) REQUIRE p.processId IS UNIQUE;

CREATE CONSTRAINT l2_process_id_unique IF NOT EXISTS
FOR (p:L2Process) REQUIRE p.processId IS UNIQUE;

CREATE CONSTRAINT l3_functionality_id_unique IF NOT EXISTS
FOR (f:L3Functionality) REQUIRE f.functionalityId IS UNIQUE;

// SOD Rule constraints
CREATE CONSTRAINT sod_rule_id_unique IF NOT EXISTS
FOR (sr:SODRule) REQUIRE sr.ruleId IS UNIQUE;

// Persona constraints
CREATE CONSTRAINT persona_id_unique IF NOT EXISTS
FOR (p:Persona) REQUIRE p.personaId IS UNIQUE;

// ═══════════════════════════════════════════════════════════════════════════
// INDEXES - Optimize query performance
// ═══════════════════════════════════════════════════════════════════════════

// User indexes
CREATE INDEX user_country IF NOT EXISTS FOR (u:User) ON (u.countryCode);
CREATE INDEX user_function IF NOT EXISTS FOR (u:User) ON (u.function);
CREATE INDEX user_department IF NOT EXISTS FOR (u:User) ON (u.department);
CREATE INDEX user_level IF NOT EXISTS FOR (u:User) ON (u.level);
CREATE INDEX user_status IF NOT EXISTS FOR (u:User) ON (u.status);
CREATE INDEX user_email IF NOT EXISTS FOR (u:User) ON (u.email);

// Role indexes
CREATE INDEX business_role_module IF NOT EXISTS FOR (br:BusinessRole) ON (br.module);
CREATE INDEX business_role_country IF NOT EXISTS FOR (br:BusinessRole) ON (br.countryCode);
CREATE INDEX functional_role_module IF NOT EXISTS FOR (fr:FunctionalRole) ON (fr.module);
CREATE INDEX functional_role_type IF NOT EXISTS FOR (fr:FunctionalRole) ON (fr.type);
CREATE INDEX derived_role_country IF NOT EXISTS FOR (dr:DerivedRole) ON (dr.countryCode);

// Transaction indexes
CREATE INDEX transaction_module IF NOT EXISTS FOR (t:Transaction) ON (t.module);
CREATE INDEX transaction_critical IF NOT EXISTS FOR (t:Transaction) ON (t.isCritical);
CREATE INDEX transaction_type IF NOT EXISTS FOR (t:Transaction) ON (t.type);

// SOD indexes
CREATE INDEX sod_rule_risk IF NOT EXISTS FOR (sr:SODRule) ON (sr.riskLevel);
CREATE INDEX sod_rule_status IF NOT EXISTS FOR (sr:SODRule) ON (sr.status);

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Countries/Entities
// ═══════════════════════════════════════════════════════════════════════════

// Create Countries
MERGE (c:Country {code: '1000'})
SET c.isoCode = 'UK', c.name = 'United Kingdom', c.region = 'EMEA';

MERGE (c:Country {code: '2000'})
SET c.isoCode = 'US', c.name = 'United States', c.region = 'Americas';

MERGE (c:Country {code: '3000'})
SET c.isoCode = 'AE', c.name = 'United Arab Emirates', c.region = 'EMEA';

MERGE (c:Country {code: '4000'})
SET c.isoCode = 'DE', c.name = 'Germany', c.region = 'EMEA';

MERGE (c:Country {code: '5000'})
SET c.isoCode = 'IN', c.name = 'India', c.region = 'APAC';

MERGE (c:Country {code: '6000'})
SET c.isoCode = 'RU', c.name = 'Russia', c.region = 'EMEA';

MERGE (c:Country {code: '7000'})
SET c.isoCode = 'CN', c.name = 'China', c.region = 'APAC';

MERGE (c:Country {code: '8000'})
SET c.isoCode = 'AU', c.name = 'Australia', c.region = 'APAC';

MERGE (c:Country {code: '9000'})
SET c.isoCode = 'SG', c.name = 'Singapore', c.region = 'APAC';

MERGE (c:Country {code: 'A000'})
SET c.isoCode = 'ZA', c.name = 'South Africa', c.region = 'EMEA';

MERGE (c:Country {code: 'B000'})
SET c.isoCode = 'KZ', c.name = 'Kazakhstan', c.region = 'EMEA';

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Functions
// ═══════════════════════════════════════════════════════════════════════════

MERGE (f:Function {code: 'FIN'})
SET f.name = 'Finance', f.description = 'Financial operations, AP/AR, Budget management';

MERGE (f:Function {code: 'S&D'})
SET f.name = 'Sales & Distribution', f.description = 'Sales order management and distribution';

MERGE (f:Function {code: 'DFE'})
SET f.name = 'Manufacturing/DFE', f.description = 'Warehouse and plant operations';

MERGE (f:Function {code: 'P2P'})
SET f.name = 'Procure to Pay', f.description = 'Purchase orders, goods receipt, invoicing';

MERGE (f:Function {code: 'MFG'})
SET f.name = 'Manufacturing', f.description = 'Manufacturing operations';

MERGE (f:Function {code: 'PSC'})
SET f.name = 'Procurement & Supply Chain', f.description = 'Procurement and supply chain management';

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Transactions (from Functional Role Matrix)
// ═══════════════════════════════════════════════════════════════════════════

// Finance Transactions
MERGE (t:Transaction {tcode: 'AJAB'})
SET t.name = 'Year-end closing',
    t.description = 'Year-end closing transaction',
    t.module = 'FI',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = true,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'AIFND_XC_SLG1'})
SET t.name = 'Monitor error',
    t.description = 'Monitor error logs',
    t.module = 'FI',
    t.type = 'Tcode',
    t.accessType = 'Display',
    t.isCritical = false,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'FSP0'})
SET t.name = 'Display GL Account',
    t.description = 'Display General Ledger Account',
    t.module = 'FI',
    t.type = 'Tcode',
    t.accessType = 'Display',
    t.isCritical = false,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'FK10N'})
SET t.name = 'Vendor Balance Display',
    t.description = 'Display Vendor Balance',
    t.module = 'FI',
    t.type = 'Tcode',
    t.accessType = 'Display',
    t.isCritical = false,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'FI03'})
SET t.name = 'Display Bank Directory',
    t.description = 'Display Bank Directory',
    t.module = 'FI',
    t.type = 'Tcode',
    t.accessType = 'Display',
    t.isCritical = false,
    t.system = 'S4';

// Sales Transactions
MERGE (t:Transaction {tcode: 'VA03'})
SET t.name = 'Display Sales Order',
    t.description = 'Display Sales Order',
    t.module = 'SD',
    t.type = 'Tcode',
    t.accessType = 'Display',
    t.isCritical = false,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'VA01'})
SET t.name = 'Create Sales Order',
    t.description = 'Create Sales Order',
    t.module = 'SD',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = false,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'VA02'})
SET t.name = 'Edit Sales Order',
    t.description = 'Edit/Change Sales Order',
    t.module = 'SD',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = false,
    t.system = 'S4';

// Warehouse/Plant Transactions
MERGE (t:Transaction {tcode: 'MD04'})
SET t.name = 'Current Stock list',
    t.description = 'Display Current Stock/Requirements List',
    t.module = 'MM',
    t.type = 'Tcode',
    t.accessType = 'Display',
    t.isCritical = false,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'LT01'})
SET t.name = 'Create Transfer order',
    t.description = 'Create Transfer Order',
    t.module = 'WM',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = false,
    t.system = 'S4';

// P2P Transactions (Critical for SOD)
MERGE (t:Transaction {tcode: 'ME21N'})
SET t.name = 'Purchase Order Creation',
    t.description = 'Create Purchase Order',
    t.module = 'MM',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = true,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'ME28'})
SET t.name = 'PO Approver',
    t.description = 'Release/Approve Purchase Order',
    t.module = 'MM',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = true,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'MIGO'})
SET t.name = 'Goods Receipt',
    t.description = 'Goods Movement - Receipt',
    t.module = 'MM',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = true,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'MIRO'})
SET t.name = 'Posting or Parking Invoice',
    t.description = 'Enter Incoming Invoice',
    t.module = 'MM',
    t.type = 'Tcode',
    t.accessType = 'Maintain',
    t.isCritical = true,
    t.system = 'S4';

MERGE (t:Transaction {tcode: 'WF_APPROVE'})
SET t.name = 'Workflow Approval',
    t.description = 'Workflow-based Budget/Invoice Approval',
    t.module = 'WF',
    t.type = 'WF',
    t.accessType = 'Maintain',
    t.isCritical = true,
    t.system = 'S4';

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Authorization Objects (from V3 Document)
// ═══════════════════════════════════════════════════════════════════════════

// PO Creator Auth Objects
MERGE (ao:AuthObject {objectId: 'M_BEST_EKG'})
SET ao.name = 'Purchasing Document: Purchasing Group', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_BEST_EKO'})
SET ao.name = 'Purchasing Document: Purchasing Organization', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_BEST_BSA'})
SET ao.name = 'Purchasing Document: Document Type', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_BEST_WRK'})
SET ao.name = 'Purchasing Document: Plant', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_BEST_AKT'})
SET ao.name = 'Purchasing Document: Activity Type', ao.objectClass = 'MM';

// PO Releaser Auth Objects
MERGE (ao:AuthObject {objectId: 'M_EINK_FRG'})
SET ao.name = 'Release Code for Purchasing Documents', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_EINK_EKO'})
SET ao.name = 'Purchasing: Purchasing Organization', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_EINK_WRK'})
SET ao.name = 'Purchasing: Plant', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_EINK_EKG'})
SET ao.name = 'Purchasing: Purchasing Group', ao.objectClass = 'MM';

// GR Processor Auth Objects
MERGE (ao:AuthObject {objectId: 'M_MSEG_WMG'})
SET ao.name = 'Goods Movement: Movement Type', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_MSEG_WMA'})
SET ao.name = 'Goods Movement: Activity Type', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_MSEG_BWE'})
SET ao.name = 'Goods Movement: Movement Indicator', ao.objectClass = 'MM';

// Invoice Auth Objects
MERGE (ao:AuthObject {objectId: 'M_RECH_WRK'})
SET ao.name = 'Invoice Verification: Plant', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_RECH_AKZ'})
SET ao.name = 'Invoice Verification: Activity Type', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_RECH_EKG'})
SET ao.name = 'Invoice Verification: Purchasing Group', ao.objectClass = 'MM';

MERGE (ao:AuthObject {objectId: 'M_RECH_SPG'})
SET ao.name = 'Invoice Verification: Blocking Reason', ao.objectClass = 'MM';

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Functional Roles (Master Templates)
// ═══════════════════════════════════════════════════════════════════════════

// Finance Functional Roles
MERGE (fr:FunctionalRole {roleId: 'ZRM:FI_:PERD_END_CLOSING_:0000'})
SET fr.name = 'FI - Period END Closing - Master',
    fr.description = 'Period end closing activities',
    fr.type = 'ZRM',
    fr.module = 'FI',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRD:FI_:DISPLAY_FINANCE__:0000'})
SET fr.name = 'FI - Display Finance - Master',
    fr.description = 'Display-only access to finance data',
    fr.type = 'ZRD',
    fr.module = 'FI',
    fr.isMaster = true;

// Sales Functional Roles
MERGE (fr:FunctionalRole {roleId: 'ZRD:SD_:Display_Sales____:0000'})
SET fr.name = 'SD - Display Sales - Master',
    fr.description = 'Display-only access to sales data',
    fr.type = 'ZRD',
    fr.module = 'SD',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRM:SD_:REQUISITIONER____:0000'})
SET fr.name = 'SD - Requisitioner - Master',
    fr.description = 'Sales requisitioner activities',
    fr.type = 'ZRM',
    fr.module = 'SD',
    fr.isMaster = true;

// DFE/Warehouse Functional Roles
MERGE (fr:FunctionalRole {roleId: 'ZRD:DFE:Display_Plant____:0000'})
SET fr.name = 'DFE - Display Plant - Master',
    fr.description = 'Display-only access to plant data',
    fr.type = 'ZRD',
    fr.module = 'DFE',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRM:DFE:Warehouse_Admin__:0000'})
SET fr.name = 'DFE - Warehouse Administration - Master',
    fr.description = 'Warehouse administration activities',
    fr.type = 'ZRM',
    fr.module = 'DFE',
    fr.isMaster = true;

// P2P Functional Roles (Critical for SOD)
MERGE (fr:FunctionalRole {roleId: 'ZRM:P2P:PO_CREATOR_______:0000'})
SET fr.name = 'P2P - PO Creator - Master',
    fr.description = 'Purchase Order creation',
    fr.type = 'ZRM',
    fr.module = 'P2P',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRM:P2P:PO_RELEASER______:0000'})
SET fr.name = 'P2P - PO Releaser - Master',
    fr.description = 'Purchase Order release/approval',
    fr.type = 'ZRM',
    fr.module = 'P2P',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRM:FI_:GR_PROCESSOR_____:0000'})
SET fr.name = 'FI - GR Processor - Master',
    fr.description = 'Goods Receipt processing',
    fr.type = 'ZRM',
    fr.module = 'FI',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRM:FI_:AP_CLERK_________:0000'})
SET fr.name = 'FI - AP CLERK - Master',
    fr.description = 'Accounts Payable clerk activities',
    fr.type = 'ZRM',
    fr.module = 'FI',
    fr.isMaster = true;

MERGE (fr:FunctionalRole {roleId: 'ZRM:FI_:Budget_Approver__:0000'})
SET fr.name = 'FI - Budget Approver - Master',
    fr.description = 'Budget and invoice approval',
    fr.type = 'ZRM',
    fr.module = 'FI',
    fr.isMaster = true;

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Process Hierarchy
// ═══════════════════════════════════════════════════════════════════════════

// L1 Processes
MERGE (p:L1Process {processId: 'P2P'})
SET p.name = 'Purchase to Pay',
    p.description = 'End-to-end procurement process from requisition to payment';

MERGE (p:L1Process {processId: 'O2C'})
SET p.name = 'Order to Cash',
    p.description = 'End-to-end sales process from order to cash collection';

MERGE (p:L1Process {processId: 'R2R'})
SET p.name = 'Record to Report',
    p.description = 'Financial recording and reporting process';

// L2 Processes - P2P
MERGE (p:L2Process {processId: 'P2P_PO_MGMT'})
SET p.name = 'Purchase Order Creation and Release',
    p.description = 'PO creation, modification, and approval',
    p.parentProcessId = 'P2P';

MERGE (p:L2Process {processId: 'P2P_RECEIPTS'})
SET p.name = 'Receipts Processing',
    p.description = 'Goods receipt and service entry',
    p.parentProcessId = 'P2P';

MERGE (p:L2Process {processId: 'P2P_INVOICE'})
SET p.name = 'Invoice Processing',
    p.description = 'Invoice receipt, verification, and payment',
    p.parentProcessId = 'P2P';

// L3 Functionalities - P2P
MERGE (f:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
SET f.name = 'Purchase Order Creation',
    f.description = 'Create new purchase orders',
    f.parentProcessId = 'P2P_PO_MGMT';

MERGE (f:L3Functionality {functionalityId: 'P2P_PO_RELEASE'})
SET f.name = 'Purchase Order Release/Approve',
    f.description = 'Release and approve purchase orders',
    f.parentProcessId = 'P2P_PO_MGMT';

MERGE (f:L3Functionality {functionalityId: 'P2P_GR'})
SET f.name = 'Goods Receipt',
    f.description = 'Post goods receipt against PO',
    f.parentProcessId = 'P2P_RECEIPTS';

MERGE (f:L3Functionality {functionalityId: 'P2P_INV_POST'})
SET f.name = 'Invoice Posting/Parking',
    f.description = 'Post or park incoming invoices',
    f.parentProcessId = 'P2P_INVOICE';

MERGE (f:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
SET f.name = 'Invoice Approval',
    f.description = 'Approve invoices for payment',
    f.parentProcessId = 'P2P_INVOICE';

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - Personas
// ═══════════════════════════════════════════════════════════════════════════

MERGE (p:Persona {personaId: 'PROCUREMENT_AGENT'})
SET p.name = 'Procurement Agent',
    p.description = 'Creates and manages purchase orders',
    p.department = 'Procurement & Supply Chain',
    p.typicalLevel = 'L4';

MERGE (p:Persona {personaId: 'PO_APPROVER'})
SET p.name = 'PO Approver',
    p.description = 'Approves and releases purchase orders',
    p.department = 'Procurement & Supply Chain',
    p.typicalLevel = 'L3';

MERGE (p:Persona {personaId: 'GR_PROCESSOR'})
SET p.name = 'GR Processor',
    p.description = 'Processes goods receipts',
    p.department = 'Finance',
    p.typicalLevel = 'L4';

MERGE (p:Persona {personaId: 'AP_CLERK'})
SET p.name = 'AP Clerk',
    p.description = 'Posts and parks invoices',
    p.department = 'Finance',
    p.typicalLevel = 'L4';

MERGE (p:Persona {personaId: 'BUDGET_APPROVER'})
SET p.name = 'Budget Approver',
    p.description = 'Approves invoices and budgets',
    p.department = 'Finance',
    p.typicalLevel = 'L2';

MERGE (p:Persona {personaId: 'WAREHOUSE_MANAGER'})
SET p.name = 'Warehouse Manager',
    p.description = 'Manages warehouse operations',
    p.department = 'Manufacturing',
    p.typicalLevel = 'L3';

MERGE (p:Persona {personaId: 'SALES_ANALYST'})
SET p.name = 'Sales Analyst',
    p.description = 'Analyzes sales data and creates orders',
    p.department = 'Sales & Marketing',
    p.typicalLevel = 'L4';

MERGE (p:Persona {personaId: 'FINANCE_MANAGER'})
SET p.name = 'Finance Manager',
    p.description = 'Manages financial operations',
    p.department = 'Finance',
    p.typicalLevel = 'L2';

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE DATA - SOD Rules
// ═══════════════════════════════════════════════════════════════════════════

MERGE (sr:SODRule {ruleId: 'SOD_0001'})
SET sr.name = 'PO Creation vs PO Release',
    sr.description = 'Prevent same user from creating and approving purchase orders',
    sr.riskLevel = 'HIGH',
    sr.conflictType = 'Create vs Approve',
    sr.status = 'ACTIVE';

MERGE (sr:SODRule {ruleId: 'SOD_0002'})
SET sr.name = 'Goods Receipt vs PO Creation',
    sr.description = 'Prevent GR processor from creating purchase orders',
    sr.riskLevel = 'HIGH',
    sr.conflictType = 'Receipt vs Create',
    sr.status = 'ACTIVE';

MERGE (sr:SODRule {ruleId: 'SOD_0003'})
SET sr.name = 'Goods Receipt vs PO Release',
    sr.description = 'Prevent GR processor from approving purchase orders',
    sr.riskLevel = 'HIGH',
    sr.conflictType = 'Receipt vs Approve',
    sr.status = 'ACTIVE';

MERGE (sr:SODRule {ruleId: 'SOD_0004'})
SET sr.name = 'Goods Receipt vs Invoice Approval',
    sr.description = 'Prevent GR processor from approving invoices',
    sr.riskLevel = 'HIGH',
    sr.conflictType = 'Receipt vs Approve',
    sr.status = 'ACTIVE';

MERGE (sr:SODRule {ruleId: 'SOD_0005'})
SET sr.name = 'Invoice Posting vs Invoice Approval',
    sr.description = 'Prevent invoice poster from approving invoices',
    sr.riskLevel = 'HIGH',
    sr.conflictType = 'Post vs Approve',
    sr.status = 'ACTIVE';

MERGE (sr:SODRule {ruleId: 'SOD_0006'})
SET sr.name = 'Invoice Approval vs PO Creation',
    sr.description = 'Prevent budget approver from creating purchase orders',
    sr.riskLevel = 'MEDIUM',
    sr.conflictType = 'Approve vs Create',
    sr.status = 'ACTIVE';

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Functional Role to Transaction mappings
// ═══════════════════════════════════════════════════════════════════════════

// Period End Closing Role -> Transactions
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:PERD_END_CLOSING_:0000'})
MATCH (t:Transaction {tcode: 'AJAB'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: true}]->(t);

MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:PERD_END_CLOSING_:0000'})
MATCH (t:Transaction {tcode: 'AIFND_XC_SLG1'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Display', isCritical: false}]->(t);

// Display Finance Role -> Transactions
MATCH (fr:FunctionalRole {roleId: 'ZRD:FI_:DISPLAY_FINANCE__:0000'})
MATCH (t:Transaction {tcode: 'FSP0'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Display', isCritical: false}]->(t);

MATCH (fr:FunctionalRole {roleId: 'ZRD:FI_:DISPLAY_FINANCE__:0000'})
MATCH (t:Transaction {tcode: 'FK10N'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Display', isCritical: false}]->(t);

MATCH (fr:FunctionalRole {roleId: 'ZRD:FI_:DISPLAY_FINANCE__:0000'})
MATCH (t:Transaction {tcode: 'FI03'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Display', isCritical: false}]->(t);

// Display Sales Role -> Transactions
MATCH (fr:FunctionalRole {roleId: 'ZRD:SD_:Display_Sales____:0000'})
MATCH (t:Transaction {tcode: 'VA03'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Display', isCritical: false}]->(t);

// Requisitioner Role -> Transactions
MATCH (fr:FunctionalRole {roleId: 'ZRM:SD_:REQUISITIONER____:0000'})
MATCH (t:Transaction {tcode: 'VA01'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: false}]->(t);

MATCH (fr:FunctionalRole {roleId: 'ZRM:SD_:REQUISITIONER____:0000'})
MATCH (t:Transaction {tcode: 'VA02'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: false}]->(t);

// Display Plant Role -> Transactions
MATCH (fr:FunctionalRole {roleId: 'ZRD:DFE:Display_Plant____:0000'})
MATCH (t:Transaction {tcode: 'MD04'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Display', isCritical: false}]->(t);

// Warehouse Admin Role -> Transactions
MATCH (fr:FunctionalRole {roleId: 'ZRM:DFE:Warehouse_Admin__:0000'})
MATCH (t:Transaction {tcode: 'LT01'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: false}]->(t);

// PO Creator Role -> Transactions (Critical for SOD)
MATCH (fr:FunctionalRole {roleId: 'ZRM:P2P:PO_CREATOR_______:0000'})
MATCH (t:Transaction {tcode: 'ME21N'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: true}]->(t);

// PO Releaser Role -> Transactions (Critical for SOD)
MATCH (fr:FunctionalRole {roleId: 'ZRM:P2P:PO_RELEASER______:0000'})
MATCH (t:Transaction {tcode: 'ME28'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: true}]->(t);

// GR Processor Role -> Transactions (Critical for SOD)
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:GR_PROCESSOR_____:0000'})
MATCH (t:Transaction {tcode: 'MIGO'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: true}]->(t);

// AP Clerk Role -> Transactions (Critical for SOD)
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:AP_CLERK_________:0000'})
MATCH (t:Transaction {tcode: 'MIRO'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: true}]->(t);

// Budget Approver Role -> Transactions (Critical for SOD)
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:Budget_Approver__:0000'})
MATCH (t:Transaction {tcode: 'WF_APPROVE'})
MERGE (fr)-[:GRANTS_ACCESS_TO {accessType: 'Maintain', isCritical: true}]->(t);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Transaction to Authorization Object mappings
// ═══════════════════════════════════════════════════════════════════════════

// ME21N (PO Creation) requires these auth objects
MATCH (t:Transaction {tcode: 'ME21N'})
MATCH (ao:AuthObject {objectId: 'M_BEST_EKG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME21N'})
MATCH (ao:AuthObject {objectId: 'M_BEST_EKO'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME21N'})
MATCH (ao:AuthObject {objectId: 'M_BEST_BSA'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME21N'})
MATCH (ao:AuthObject {objectId: 'M_BEST_WRK'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME21N'})
MATCH (ao:AuthObject {objectId: 'M_BEST_AKT'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

// ME28 (PO Release) requires these auth objects
MATCH (t:Transaction {tcode: 'ME28'})
MATCH (ao:AuthObject {objectId: 'M_EINK_FRG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME28'})
MATCH (ao:AuthObject {objectId: 'M_EINK_EKO'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME28'})
MATCH (ao:AuthObject {objectId: 'M_EINK_WRK'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'ME28'})
MATCH (ao:AuthObject {objectId: 'M_EINK_EKG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

// MIGO (Goods Receipt) requires these auth objects
MATCH (t:Transaction {tcode: 'MIGO'})
MATCH (ao:AuthObject {objectId: 'M_MSEG_WMG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'MIGO'})
MATCH (ao:AuthObject {objectId: 'M_MSEG_WMA'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'MIGO'})
MATCH (ao:AuthObject {objectId: 'M_MSEG_BWE'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'MIGO'})
MATCH (ao:AuthObject {objectId: 'M_BEST_EKG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

// MIRO (Invoice Posting) requires these auth objects
MATCH (t:Transaction {tcode: 'MIRO'})
MATCH (ao:AuthObject {objectId: 'M_RECH_WRK'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'MIRO'})
MATCH (ao:AuthObject {objectId: 'M_RECH_AKZ'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

// WF_APPROVE (Invoice Approval) requires these auth objects
MATCH (t:Transaction {tcode: 'WF_APPROVE'})
MATCH (ao:AuthObject {objectId: 'M_RECH_EKG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'WF_APPROVE'})
MATCH (ao:AuthObject {objectId: 'M_RECH_SPG'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

MATCH (t:Transaction {tcode: 'WF_APPROVE'})
MATCH (ao:AuthObject {objectId: 'M_RECH_WRK'})
MERGE (t)-[:REQUIRES_AUTH]->(ao);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Process Hierarchy
// ═══════════════════════════════════════════════════════════════════════════

// L1 -> L2 Process relationships
MATCH (l1:L1Process {processId: 'P2P'})
MATCH (l2:L2Process {processId: 'P2P_PO_MGMT'})
MERGE (l1)-[:HAS_SUBPROCESS]->(l2);

MATCH (l1:L1Process {processId: 'P2P'})
MATCH (l2:L2Process {processId: 'P2P_RECEIPTS'})
MERGE (l1)-[:HAS_SUBPROCESS]->(l2);

MATCH (l1:L1Process {processId: 'P2P'})
MATCH (l2:L2Process {processId: 'P2P_INVOICE'})
MERGE (l1)-[:HAS_SUBPROCESS]->(l2);

// L2 -> L3 Functionality relationships
MATCH (l2:L2Process {processId: 'P2P_PO_MGMT'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
MERGE (l2)-[:HAS_FUNCTIONALITY]->(l3);

MATCH (l2:L2Process {processId: 'P2P_PO_MGMT'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_PO_RELEASE'})
MERGE (l2)-[:HAS_FUNCTIONALITY]->(l3);

MATCH (l2:L2Process {processId: 'P2P_RECEIPTS'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_GR'})
MERGE (l2)-[:HAS_FUNCTIONALITY]->(l3);

MATCH (l2:L2Process {processId: 'P2P_INVOICE'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_INV_POST'})
MERGE (l2)-[:HAS_FUNCTIONALITY]->(l3);

MATCH (l2:L2Process {processId: 'P2P_INVOICE'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
MERGE (l2)-[:HAS_FUNCTIONALITY]->(l3);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Functionality to Persona
// ═══════════════════════════════════════════════════════════════════════════

MATCH (l3:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
MATCH (p:Persona {personaId: 'PROCUREMENT_AGENT'})
MERGE (l3)-[:PERFORMED_BY]->(p);

MATCH (l3:L3Functionality {functionalityId: 'P2P_PO_RELEASE'})
MATCH (p:Persona {personaId: 'PO_APPROVER'})
MERGE (l3)-[:PERFORMED_BY]->(p);

MATCH (l3:L3Functionality {functionalityId: 'P2P_GR'})
MATCH (p:Persona {personaId: 'GR_PROCESSOR'})
MERGE (l3)-[:PERFORMED_BY]->(p);

MATCH (l3:L3Functionality {functionalityId: 'P2P_INV_POST'})
MATCH (p:Persona {personaId: 'AP_CLERK'})
MERGE (l3)-[:PERFORMED_BY]->(p);

MATCH (l3:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
MATCH (p:Persona {personaId: 'BUDGET_APPROVER'})
MERGE (l3)-[:PERFORMED_BY]->(p);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Persona to Functional Role
// ═══════════════════════════════════════════════════════════════════════════

MATCH (p:Persona {personaId: 'PROCUREMENT_AGENT'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:P2P:PO_CREATOR_______:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'PO_APPROVER'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:P2P:PO_RELEASER______:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'GR_PROCESSOR'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:GR_PROCESSOR_____:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'AP_CLERK'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:AP_CLERK_________:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'BUDGET_APPROVER'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:Budget_Approver__:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'WAREHOUSE_MANAGER'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:DFE:Warehouse_Admin__:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'SALES_ANALYST'})
MATCH (fr:FunctionalRole {roleId: 'ZRD:SD_:Display_Sales____:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

MATCH (p:Persona {personaId: 'FINANCE_MANAGER'})
MATCH (fr:FunctionalRole {roleId: 'ZRM:FI_:PERD_END_CLOSING_:0000'})
MERGE (p)-[:SUPPORTED_BY_ROLE]->(fr);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Transaction to Functionality
// ═══════════════════════════════════════════════════════════════════════════

MATCH (t:Transaction {tcode: 'ME21N'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
MERGE (t)-[:BELONGS_TO_FUNCTIONALITY]->(l3);

MATCH (t:Transaction {tcode: 'ME28'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_PO_RELEASE'})
MERGE (t)-[:BELONGS_TO_FUNCTIONALITY]->(l3);

MATCH (t:Transaction {tcode: 'MIGO'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_GR'})
MERGE (t)-[:BELONGS_TO_FUNCTIONALITY]->(l3);

MATCH (t:Transaction {tcode: 'MIRO'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_INV_POST'})
MERGE (t)-[:BELONGS_TO_FUNCTIONALITY]->(l3);

MATCH (t:Transaction {tcode: 'WF_APPROVE'})
MATCH (l3:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
MERGE (t)-[:BELONGS_TO_FUNCTIONALITY]->(l3);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - SOD Rule to Functionality (Conflict Definition)
// ═══════════════════════════════════════════════════════════════════════════

// SOD_0001: PO Creation vs PO Release
MATCH (sr:SODRule {ruleId: 'SOD_0001'})
MATCH (l3a:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_A'}]->(l3a);

MATCH (sr:SODRule {ruleId: 'SOD_0001'})
MATCH (l3b:L3Functionality {functionalityId: 'P2P_PO_RELEASE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_B'}]->(l3b);

// SOD_0002: Goods Receipt vs PO Creation
MATCH (sr:SODRule {ruleId: 'SOD_0002'})
MATCH (l3a:L3Functionality {functionalityId: 'P2P_GR'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_A'}]->(l3a);

MATCH (sr:SODRule {ruleId: 'SOD_0002'})
MATCH (l3b:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_B'}]->(l3b);

// SOD_0003: Goods Receipt vs PO Release
MATCH (sr:SODRule {ruleId: 'SOD_0003'})
MATCH (l3a:L3Functionality {functionalityId: 'P2P_GR'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_A'}]->(l3a);

MATCH (sr:SODRule {ruleId: 'SOD_0003'})
MATCH (l3b:L3Functionality {functionalityId: 'P2P_PO_RELEASE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_B'}]->(l3b);

// SOD_0004: Goods Receipt vs Invoice Approval
MATCH (sr:SODRule {ruleId: 'SOD_0004'})
MATCH (l3a:L3Functionality {functionalityId: 'P2P_GR'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_A'}]->(l3a);

MATCH (sr:SODRule {ruleId: 'SOD_0004'})
MATCH (l3b:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_B'}]->(l3b);

// SOD_0005: Invoice Posting vs Invoice Approval
MATCH (sr:SODRule {ruleId: 'SOD_0005'})
MATCH (l3a:L3Functionality {functionalityId: 'P2P_INV_POST'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_A'}]->(l3a);

MATCH (sr:SODRule {ruleId: 'SOD_0005'})
MATCH (l3b:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_B'}]->(l3b);

// SOD_0006: Invoice Approval vs PO Creation
MATCH (sr:SODRule {ruleId: 'SOD_0006'})
MATCH (l3a:L3Functionality {functionalityId: 'P2P_INV_APPROVE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_A'}]->(l3a);

MATCH (sr:SODRule {ruleId: 'SOD_0006'})
MATCH (l3b:L3Functionality {functionalityId: 'P2P_PO_CREATE'})
MERGE (sr)-[:INVOLVES_FUNCTIONALITY {side: 'SIDE_B'}]->(l3b);

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIPS - Functional Role Conflicts (CONFLICTS_WITH)
// ═══════════════════════════════════════════════════════════════════════════

// SOD_0001: PO Creator CONFLICTS_WITH PO Releaser
MATCH (fr1:FunctionalRole {roleId: 'ZRM:P2P:PO_CREATOR_______:0000'})
MATCH (fr2:FunctionalRole {roleId: 'ZRM:P2P:PO_RELEASER______:0000'})
MERGE (fr1)-[:CONFLICTS_WITH {
    ruleId: 'SOD_0001',
    riskLevel: 'HIGH',
    conflictType: 'Create vs Approve'
}]->(fr2);

// SOD_0002: GR Processor CONFLICTS_WITH PO Creator
MATCH (fr1:FunctionalRole {roleId: 'ZRM:FI_:GR_PROCESSOR_____:0000'})
MATCH (fr2:FunctionalRole {roleId: 'ZRM:P2P:PO_CREATOR_______:0000'})
MERGE (fr1)-[:CONFLICTS_WITH {
    ruleId: 'SOD_0002',
    riskLevel: 'HIGH',
    conflictType: 'Receipt vs Create'
}]->(fr2);

// SOD_0003: GR Processor CONFLICTS_WITH PO Releaser
MATCH (fr1:FunctionalRole {roleId: 'ZRM:FI_:GR_PROCESSOR_____:0000'})
MATCH (fr2:FunctionalRole {roleId: 'ZRM:P2P:PO_RELEASER______:0000'})
MERGE (fr1)-[:CONFLICTS_WITH {
    ruleId: 'SOD_0003',
    riskLevel: 'HIGH',
    conflictType: 'Receipt vs Approve'
}]->(fr2);

// SOD_0004: GR Processor CONFLICTS_WITH Budget Approver
MATCH (fr1:FunctionalRole {roleId: 'ZRM:FI_:GR_PROCESSOR_____:0000'})
MATCH (fr2:FunctionalRole {roleId: 'ZRM:FI_:Budget_Approver__:0000'})
MERGE (fr1)-[:CONFLICTS_WITH {
    ruleId: 'SOD_0004',
    riskLevel: 'HIGH',
    conflictType: 'Receipt vs Approve'
}]->(fr2);

// SOD_0005: AP Clerk CONFLICTS_WITH Budget Approver
MATCH (fr1:FunctionalRole {roleId: 'ZRM:FI_:AP_CLERK_________:0000'})
MATCH (fr2:FunctionalRole {roleId: 'ZRM:FI_:Budget_Approver__:0000'})
MERGE (fr1)-[:CONFLICTS_WITH {
    ruleId: 'SOD_0005',
    riskLevel: 'HIGH',
    conflictType: 'Post vs Approve'
}]->(fr2);

// SOD_0006: Budget Approver CONFLICTS_WITH PO Creator
MATCH (fr1:FunctionalRole {roleId: 'ZRM:FI_:Budget_Approver__:0000'})
MATCH (fr2:FunctionalRole {roleId: 'ZRM:P2P:PO_CREATOR_______:0000'})
MERGE (fr1)-[:CONFLICTS_WITH {
    ruleId: 'SOD_0006',
    riskLevel: 'MEDIUM',
    conflictType: 'Approve vs Create'
}]->(fr2);

// ═══════════════════════════════════════════════════════════════════════════
// END OF SCHEMA
// ═══════════════════════════════════════════════════════════════════════════
