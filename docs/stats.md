# User Reconciliation Statistics Report

**Generated:** February 24, 2026

--------------------------------------------------

## Executive Summary

This report presents the reconciliation analysis between Entra ID (Azure AD) users and SAP system users, mapping data based on **User Name** (SAP) and **displayName/mailNickname** (Entra).

--------------------------------------------------

## Key Metrics

| Metric | Value |
|--------|-------|
| Total Entra Users | 1,144 |
| Total Unique SAP Users | 63 |
| Total SAP Role Assignments | 112 |
| Users Matched (in both systems) | 63 |
| Users Only in Entra (no SAP role) | 1,081 |
| Users Only in SAP (not in Entra) | 0 |
| **Match Rate (SAP users found in Entra)** | **100.0%** |
| **Coverage Rate (Entra users with SAP roles)** | **5.5%** |

--------------------------------------------------

## Gap Analysis

### ✅ SAP to Entra Matching
All SAP users were successfully found in Entra!

--------------------------------------------------

## Department Breakdown

### Entra Users Without SAP Roles

| Department | User Count |
|------------|------------|
| Manufacturing | 896 |
| Procurement & Supply Chain | 48 |
| HR | 44 |
| IT | 43 |
| Finance | 27 |
| Sales & Marketing | 11 |
| Corporate Affairs | 7 |
| Executive | 1 |

--------------------------------------------------

## SAP Role Distribution

| Role Description | Assignments |
|------------------|-------------|
| P2P - PO-Creator - 2000 US | 44 |
| P2P - PO-Releaser - 2000 US | 44 |
| DFE - Warehouse Manager - 2000 US | 10 |
| P2P - PO-Creator - 1000 UK | 4 |
| P2P - PO-Releaser - 1000 UK | 4 |
| DFE - Warehouse Manager - 1000 UK | 2 |
| FIN - Budget-Approver - 2000 US | 1 |
| FIN - Finance Manager - 2000 US | 1 |
| S&D - Sales Analyst - 1000 UK | 1 |
| S&D - Sales Analyst - 2000 US | 1 |

--------------------------------------------------

## Files Generated

| File Name | Description | Records |
|-----------|-------------|---------|
| `merged_sap_entra_users.csv` | Combined SAP and Entra user data | 63 |
| `reconciliation_summary.csv` | High-level statistics | - |
| `matched_users_with_sap_roles.csv` | Users found in both systems | 63 |
| `entra_users_without_sap_roles.csv` | Entra users without SAP roles | 1,081 |
| `department_breakdown_no_sap.csv` | Department distribution | 8 |
| `sap_role_distribution.csv` | SAP role assignments | 10 |

--------------------------------------------------

## Methodology

1. **Data Sources:**
   - Entra Users: `entra_users_20260217_122150 (1).csv`
   - SAP Users: `entra_users_20260217_122150.csv`

2. **Matching Logic:**
   - SAP `User Name` field matched against Entra `mailNickname` field
   - Case-insensitive matching applied

3. **Analysis Performed:**
   - User presence reconciliation
   - Role assignment mapping
   - Gap identification
   - Department-wise breakdown

--------------------------------------------------

## Conclusions

- **100% of SAP users** have corresponding Entra accounts
- Only **5.5% of Entra users** have SAP role assignments
- The majority of users without SAP roles are in **Manufacturing** (896 users)
- Most SAP roles are related to **P2P (Procure-to-Pay)** processes

--------------------------------------------------
