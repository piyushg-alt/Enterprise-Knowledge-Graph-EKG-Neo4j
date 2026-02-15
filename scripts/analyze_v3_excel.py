"""
V3 Excel Data Analysis Script
Enterprise Knowledge Graph (EKG) - Data Analysis and Transformation

This script analyzes the Pax Identity Auth Matrix - Role Build-V3.xlsx file
and generates reports and data for Neo4j graph loading.
"""

import pandas as pd
import json
from pathlib import Path
from collections import defaultdict
from datetime import datetime

# Configuration
EXCEL_FILE = "data/Pax Identity Auth Matrix - Role Build-V3.xlsx"
OUTPUT_DIR = "data/processed"


def load_excel_sheets(file_path: str) -> dict:
    """Load all sheets from the V3 Excel file."""
    print(f"Loading Excel file: {file_path}")
    
    sheets = {
        'user_mapping': 'User Mapping',
        'business_role_template': 'Business Role Template',
        'functional_role_matrix': 'Functional Role Matrix',
        'derive_role_matrix': 'Derive Role Matrix',
        'business_roles': 'Business Roles'
    }
    
    data = {}
    xl = pd.ExcelFile(file_path)
    
    for key, sheet_name in sheets.items():
        try:
            df = pd.read_excel(xl, sheet_name=sheet_name)
            data[key] = df
            print(f"  Loaded '{sheet_name}': {len(df)} rows")
        except Exception as e:
            print(f"  Warning: Could not load '{sheet_name}': {e}")
            data[key] = pd.DataFrame()
    
    return data


def analyze_user_mapping(df: pd.DataFrame) -> dict:
    """Analyze the User Mapping sheet."""
    print("\n=== User Mapping Analysis ===")
    
    # Clean column names
    df.columns = df.columns.str.strip()
    
    # Basic stats
    total_users = len(df)
    print(f"Total Users: {total_users}")
    
    # Country distribution
    country_dist = df['Country'].value_counts().to_dict()
    print(f"\nBy Country:")
    for country, count in country_dist.items():
        pct = (count / total_users) * 100
        print(f"  {country}: {count} ({pct:.1f}%)")
    
    # Function distribution
    function_dist = df['Function'].value_counts().to_dict()
    print(f"\nBy Function:")
    for func, count in function_dist.items():
        pct = (count / total_users) * 100
        print(f"  {func}: {count} ({pct:.1f}%)")
    
    # Level distribution
    level_dist = df['Level'].value_counts().to_dict()
    print(f"\nBy Level:")
    for level, count in level_dist.items():
        pct = (count / total_users) * 100
        print(f"  {level}: {count} ({pct:.1f}%)")
    
    # Role distribution
    role_dist = df['SAP Role ID'].value_counts().to_dict()
    print(f"\nBy SAP Role:")
    for role, count in list(role_dist.items())[:10]:
        print(f"  {role}: {count}")
    
    return {
        'total_users': total_users,
        'by_country': country_dist,
        'by_function': function_dist,
        'by_level': level_dist,
        'by_role': role_dist
    }


def analyze_functional_roles(df: pd.DataFrame) -> dict:
    """Analyze the Functional Role Matrix sheet."""
    print("\n=== Functional Role Matrix Analysis ===")
    
    # Find the header row (contains 'Tcode / Fiori APP')
    header_row = None
    for idx, row in df.iterrows():
        if 'Tcode / Fiori APP' in str(row.values):
            header_row = idx
            break
    
    if header_row is None:
        print("  Could not find header row")
        return {}
    
    # Extract transactions
    transactions = []
    for idx in range(header_row + 1, len(df)):
        row = df.iloc[idx]
        tcode = str(row.iloc[2]).strip() if pd.notna(row.iloc[2]) else None
        desc = str(row.iloc[3]).strip() if pd.notna(row.iloc[3]) else None
        access_type = str(row.iloc[4]).strip() if pd.notna(row.iloc[4]) else None
        critical = str(row.iloc[5]).strip() if pd.notna(row.iloc[5]) else 'N'
        
        if tcode and tcode not in ['nan', '']:
            transactions.append({
                'tcode': tcode,
                'description': desc,
                'access_type': access_type,
                'is_critical': critical == 'Y'
            })
    
    print(f"Total Transactions: {len(transactions)}")
    
    # Critical transactions
    critical_tcodes = [t for t in transactions if t['is_critical']]
    print(f"Critical Transactions: {len(critical_tcodes)}")
    for t in critical_tcodes:
        print(f"  {t['tcode']}: {t['description']}")
    
    return {
        'total_transactions': len(transactions),
        'transactions': transactions,
        'critical_transactions': critical_tcodes
    }


def analyze_derive_role_matrix(df: pd.DataFrame) -> dict:
    """Analyze the Derive Role Matrix sheet."""
    print("\n=== Derive Role Matrix Analysis ===")
    
    # Clean column names
    df.columns = df.columns.str.strip()
    
    # Filter valid rows
    valid_df = df[df['Business Role'].notna() & (df['Business Role'] != '')]
    
    total_derived = len(valid_df)
    print(f"Total Derived Roles: {total_derived}")
    
    # By Module
    module_dist = valid_df['Module'].value_counts().to_dict()
    print(f"\nBy Module:")
    for module, count in module_dist.items():
        print(f"  {module}: {count}")
    
    # By Country
    country_dist = valid_df['Country'].value_counts().to_dict()
    print(f"\nBy Country:")
    for country, count in country_dist.items():
        print(f"  {country}: {count}")
    
    # Extract unique business roles
    business_roles = valid_df['Business Role'].unique().tolist()
    print(f"\nUnique Business Roles: {len(business_roles)}")
    
    # Extract unique child roles
    child_roles = valid_df['Child Role'].unique().tolist()
    print(f"Unique Child Roles: {len(child_roles)}")
    
    return {
        'total_derived': total_derived,
        'by_module': module_dist,
        'by_country': country_dist,
        'business_roles': business_roles,
        'child_roles': child_roles
    }


def analyze_business_roles(df: pd.DataFrame) -> dict:
    """Analyze the Business Roles sheet."""
    print("\n=== Business Roles Analysis ===")
    
    # Clean column names
    df.columns = df.columns.str.strip()
    
    # Filter valid rows
    valid_df = df[df['Business Role (s)'].notna() & (df['Business Role (s)'] != '')]
    
    roles = []
    for _, row in valid_df.iterrows():
        role = {
            'name': row['Business Role (s)'],
            'assignment_region_specific': row.iloc[1] if pd.notna(row.iloc[1]) else None,
            'assignment_function': row.iloc[2] if pd.notna(row.iloc[2]) else None,
            'assignment_level': row.iloc[3] if pd.notna(row.iloc[3]) else None,
            'ownership_region_specific': row.iloc[4] if pd.notna(row.iloc[4]) else None,
            'ownership_function': row.iloc[5] if pd.notna(row.iloc[5]) else None,
            'ownership_level': row.iloc[6] if pd.notna(row.iloc[6]) else None,
            'approver_region_specific': row.iloc[7] if pd.notna(row.iloc[7]) else None,
            'approver_function': row.iloc[8] if pd.notna(row.iloc[8]) else None,
            'approver_level': row.iloc[9] if pd.notna(row.iloc[9]) else None
        }
        roles.append(role)
    
    print(f"Total Business Roles: {len(roles)}")
    for role in roles:
        print(f"  {role['name']}")
        print(f"    Assignment: {role['assignment_function']} / {role['assignment_level']}")
        print(f"    Ownership: {role['ownership_function']} / {role['ownership_level']}")
    
    return {
        'total_roles': len(roles),
        'roles': roles
    }


def extract_country_mapping(derive_df: pd.DataFrame) -> dict:
    """Extract country to entity code mapping."""
    print("\n=== Country Mapping ===")
    
    # Clean column names
    derive_df.columns = derive_df.columns.str.strip()
    
    # Extract unique country-code pairs from business role IDs
    country_mapping = {}
    
    for _, row in derive_df.iterrows():
        business_role = str(row.get('Business Role', ''))
        country = str(row.get('Country', ''))
        
        if business_role and ':' in business_role:
            # Extract entity code from role ID (last part before :0000)
            parts = business_role.split(':')
            if len(parts) >= 4:
                entity_code = parts[3]
                if country and country != 'nan':
                    country_mapping[country] = entity_code
    
    print("Country to Entity Code Mapping:")
    for country, code in sorted(country_mapping.items(), key=lambda x: x[1]):
        print(f"  {country}: {code}")
    
    return country_mapping


def generate_neo4j_import_data(data: dict, output_dir: str):
    """Generate CSV files for Neo4j import."""
    print("\n=== Generating Neo4j Import Files ===")
    
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # 1. Users CSV
    if 'user_mapping' in data and not data['user_mapping'].empty:
        users_df = data['user_mapping'].copy()
        users_df.columns = users_df.columns.str.strip()
        
        # Map columns
        users_export = users_df.rename(columns={
            'familyName': 'lastName',
            'FirstName': 'firstName',
            'userName': 'userId',
            'City': 'city',
            'Country': 'country',
            'Function': 'function',
            'Department': 'department',
            'Level': 'level',
            'SAP Role ID': 'businessRoleId'
        })
        
        # Add country code
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
        users_export['countryCode'] = users_export['country'].map(country_to_iso)
        
        users_file = f"{output_dir}/users.csv"
        users_export.to_csv(users_file, index=False)
        print(f"  Created: {users_file} ({len(users_export)} records)")
    
    # 2. Business Roles CSV
    if 'derive_role_matrix' in data and not data['derive_role_matrix'].empty:
        derive_df = data['derive_role_matrix'].copy()
        derive_df.columns = derive_df.columns.str.strip()
        
        # Extract unique business roles
        business_roles = derive_df[['Business Role', 'Business Role Description', 'Module', 'Country']].drop_duplicates()
        business_roles = business_roles.rename(columns={
            'Business Role': 'roleId',
            'Business Role Description': 'name',
            'Module': 'module',
            'Country': 'country'
        })
        
        roles_file = f"{output_dir}/business_roles.csv"
        business_roles.to_csv(roles_file, index=False)
        print(f"  Created: {roles_file} ({len(business_roles)} records)")
        
        # 3. Derived Roles CSV
        derived_roles = derive_df[['Child Role', 'Child Role Description', 'Business Role', 'Country']].drop_duplicates()
        derived_roles = derived_roles.rename(columns={
            'Child Role': 'roleId',
            'Child Role Description': 'name',
            'Business Role': 'parentRoleId',
            'Country': 'country'
        })
        
        derived_file = f"{output_dir}/derived_roles.csv"
        derived_roles.to_csv(derived_file, index=False)
        print(f"  Created: {derived_file} ({len(derived_roles)} records)")
    
    # 4. Countries CSV
    countries = [
        {'code': '1000', 'isoCode': 'UK', 'name': 'United Kingdom', 'region': 'EMEA'},
        {'code': '2000', 'isoCode': 'US', 'name': 'United States', 'region': 'Americas'},
        {'code': '3000', 'isoCode': 'AE', 'name': 'United Arab Emirates', 'region': 'EMEA'},
        {'code': '4000', 'isoCode': 'DE', 'name': 'Germany', 'region': 'EMEA'},
        {'code': '5000', 'isoCode': 'IN', 'name': 'India', 'region': 'APAC'},
        {'code': '6000', 'isoCode': 'RU', 'name': 'Russia', 'region': 'EMEA'},
        {'code': '7000', 'isoCode': 'CN', 'name': 'China', 'region': 'APAC'},
        {'code': '8000', 'isoCode': 'AU', 'name': 'Australia', 'region': 'APAC'},
        {'code': '9000', 'isoCode': 'SG', 'name': 'Singapore', 'region': 'APAC'},
        {'code': 'A000', 'isoCode': 'ZA', 'name': 'South Africa', 'region': 'EMEA'},
        {'code': 'B000', 'isoCode': 'KZ', 'name': 'Kazakhstan', 'region': 'EMEA'}
    ]
    countries_df = pd.DataFrame(countries)
    countries_file = f"{output_dir}/countries.csv"
    countries_df.to_csv(countries_file, index=False)
    print(f"  Created: {countries_file} ({len(countries_df)} records)")
    
    # 5. Transactions CSV
    transactions = [
        {'tcode': 'AJAB', 'description': 'Year-end closing', 'module': 'FI', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'AIFND_XC_SLG1', 'description': 'Monitor error', 'module': 'FI', 'accessType': 'Display', 'isCritical': False},
        {'tcode': 'FSP0', 'description': 'Display GL Account', 'module': 'FI', 'accessType': 'Display', 'isCritical': False},
        {'tcode': 'FK10N', 'description': 'Vendor Balance Display', 'module': 'FI', 'accessType': 'Display', 'isCritical': False},
        {'tcode': 'FI03', 'description': 'Display Bank Directory', 'module': 'FI', 'accessType': 'Display', 'isCritical': False},
        {'tcode': 'VA03', 'description': 'Display Sales Order', 'module': 'SD', 'accessType': 'Display', 'isCritical': False},
        {'tcode': 'VA01', 'description': 'Create Sales Order', 'module': 'SD', 'accessType': 'Maintain', 'isCritical': False},
        {'tcode': 'VA02', 'description': 'Edit Sales Order', 'module': 'SD', 'accessType': 'Maintain', 'isCritical': False},
        {'tcode': 'MD04', 'description': 'Current Stock list', 'module': 'MM', 'accessType': 'Display', 'isCritical': False},
        {'tcode': 'LT01', 'description': 'Create Transfer order', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': False},
        {'tcode': 'ME21N', 'description': 'Purchase Order Creation', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'ME28', 'description': 'PO Approver', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'MIGO', 'description': 'Goods Receipt', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'MIRO', 'description': 'Posting or Parking Invoice', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True}
    ]
    transactions_df = pd.DataFrame(transactions)
    transactions_file = f"{output_dir}/transactions.csv"
    transactions_df.to_csv(transactions_file, index=False)
    print(f"  Created: {transactions_file} ({len(transactions_df)} records)")
    
    # 6. SOD Rules CSV
    sod_rules = [
        {'ruleId': 'SOD_0001', 'name': 'PO Create vs Approve', 'function1': 'PO_CREATOR', 'function2': 'PO_RELEASER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0002', 'name': 'GR vs PO Create', 'function1': 'GR_PROCESSOR', 'function2': 'PO_CREATOR', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0003', 'name': 'GR vs PO Approve', 'function1': 'GR_PROCESSOR', 'function2': 'PO_RELEASER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0004', 'name': 'GR vs Invoice Approve', 'function1': 'GR_PROCESSOR', 'function2': 'BUDGET_APPROVER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0005', 'name': 'Invoice Post vs Approve', 'function1': 'AP_CLERK', 'function2': 'BUDGET_APPROVER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0006', 'name': 'Budget Approve vs PO Create', 'function1': 'BUDGET_APPROVER', 'function2': 'PO_CREATOR', 'riskLevel': 'MEDIUM'}
    ]
    sod_df = pd.DataFrame(sod_rules)
    sod_file = f"{output_dir}/sod_rules.csv"
    sod_df.to_csv(sod_file, index=False)
    print(f"  Created: {sod_file} ({len(sod_df)} records)")


def generate_analysis_report(analysis_results: dict, output_file: str):
    """Generate a comprehensive analysis report."""
    print(f"\n=== Generating Analysis Report: {output_file} ===")
    
    report = {
        'generated_at': datetime.now().isoformat(),
        'summary': {
            'total_users': analysis_results.get('user_analysis', {}).get('total_users', 0),
            'total_countries': len(analysis_results.get('user_analysis', {}).get('by_country', {})),
            'total_functions': len(analysis_results.get('user_analysis', {}).get('by_function', {})),
            'total_derived_roles': analysis_results.get('derive_analysis', {}).get('total_derived', 0),
            'total_business_roles': analysis_results.get('business_roles_analysis', {}).get('total_roles', 0)
        },
        'user_distribution': analysis_results.get('user_analysis', {}),
        'role_analysis': analysis_results.get('derive_analysis', {}),
        'business_roles': analysis_results.get('business_roles_analysis', {}),
        'transactions': analysis_results.get('functional_analysis', {})
    }
    
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2, default=str)
    
    print(f"  Report saved to: {output_file}")
    
    return report


def main():
    """Main execution function."""
    print("=" * 60)
    print("V3 Excel Data Analysis for Enterprise Knowledge Graph")
    print("=" * 60)
    
    # Check if file exists
    if not Path(EXCEL_FILE).exists():
        print(f"\nError: Excel file not found at {EXCEL_FILE}")
        print("Please place the V3 Excel file in the data/ directory")
        print("\nCreating sample output with embedded data...")
        
        # Create output directory
        Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
        
        # Generate sample data based on V3 Excel content
        generate_sample_data()
        return
    
    # Load Excel data
    data = load_excel_sheets(EXCEL_FILE)
    
    # Analyze each sheet
    analysis_results = {}
    
    if not data['user_mapping'].empty:
        analysis_results['user_analysis'] = analyze_user_mapping(data['user_mapping'])
    
    if not data['functional_role_matrix'].empty:
        analysis_results['functional_analysis'] = analyze_functional_roles(data['functional_role_matrix'])
    
    if not data['derive_role_matrix'].empty:
        analysis_results['derive_analysis'] = analyze_derive_role_matrix(data['derive_role_matrix'])
        analysis_results['country_mapping'] = extract_country_mapping(data['derive_role_matrix'])
    
    if not data['business_roles'].empty:
        analysis_results['business_roles_analysis'] = analyze_business_roles(data['business_roles'])
    
    # Generate Neo4j import files
    generate_neo4j_import_data(data, OUTPUT_DIR)
    
    # Generate analysis report
    report = generate_analysis_report(analysis_results, f"{OUTPUT_DIR}/analysis_report.json")
    
    print("\n" + "=" * 60)
    print("Analysis Complete!")
    print("=" * 60)
    print(f"\nOutput files generated in: {OUTPUT_DIR}/")
    print("\nFiles created:")
    print("  - users.csv")
    print("  - business_roles.csv")
    print("  - derived_roles.csv")
    print("  - countries.csv")
    print("  - transactions.csv")
    print("  - sod_rules.csv")
    print("  - analysis_report.json")


def generate_sample_data():
    """Generate sample data based on V3 Excel content when file is not available."""
    print("\nGenerating sample data from embedded V3 Excel content...")
    
    # Sample users from V3 Excel
    users = [
        {'lastName': 'Devlin', 'firstName': 'Jillian', 'userId': 'jdevlin', 'city': 'New York', 'country': 'United States', 'function': 'Sales & Marketing', 'department': 'Sales & Marketing', 'level': 'L4', 'businessRoleId': 'ZC:S&D:SALES_ANALYST_____:2000', 'countryCode': 'US'},
        {'lastName': 'Moore', 'firstName': 'Alexis', 'userId': 'amoore', 'city': 'Manchester', 'country': 'United Kingdom', 'function': 'Sales & Marketing', 'department': 'Sales & Marketing', 'level': 'L4', 'businessRoleId': 'ZC:S&D:SALES_ANALYST_____:1000', 'countryCode': 'UK'},
        {'lastName': 'Stevenson', 'firstName': 'Alison', 'userId': 'astevenson', 'city': 'Beijing', 'country': 'China', 'function': 'Manufacturing', 'department': 'Manufacturing', 'level': 'L3', 'businessRoleId': 'ZC:DFE:WAREHOUSE_MANAGER_:7000', 'countryCode': 'CN'},
        {'lastName': 'Bunker', 'firstName': 'Deacon', 'userId': 'dbunker', 'city': 'Boulder', 'country': 'United States', 'function': 'Manufacturing', 'department': 'Manufacturing', 'level': 'L3', 'businessRoleId': 'ZC:DFE:WAREHOUSE_MANAGER_:2000', 'countryCode': 'US'},
        {'lastName': 'Junker', 'firstName': 'Philipp', 'userId': 'pjunker', 'city': 'London', 'country': 'United Kingdom', 'function': 'Procurement & Supply Chain', 'department': 'Procurement & Supply Chain', 'level': 'L4', 'businessRoleId': 'ZC:P2P:PO_CREATOR________:1000', 'countryCode': 'UK'},
        {'lastName': 'Klasson', 'firstName': 'Patrik', 'userId': 'pklasson', 'city': 'Cologne', 'country': 'Germany', 'function': 'Procurement & Supply Chain', 'department': 'Procurement & Supply Chain', 'level': 'L4', 'businessRoleId': 'ZC:P2P:PO_CREATOR________:4000', 'countryCode': 'DE'},
        {'lastName': 'Ward', 'firstName': 'Sward', 'userId': 'sward', 'city': 'New York', 'country': 'United States', 'function': 'Finance', 'department': 'Finance', 'level': 'L2', 'businessRoleId': 'ZC:FIN:FINANCE_MANAGER___:2000', 'countryCode': 'US'}
    ]
    
    users_df = pd.DataFrame(users)
    users_df.to_csv(f"{OUTPUT_DIR}/users.csv", index=False)
    print(f"  Created: {OUTPUT_DIR}/users.csv ({len(users_df)} sample records)")
    
    # Countries
    countries = [
        {'code': '1000', 'isoCode': 'UK', 'name': 'United Kingdom', 'region': 'EMEA'},
        {'code': '2000', 'isoCode': 'US', 'name': 'United States', 'region': 'Americas'},
        {'code': '3000', 'isoCode': 'AE', 'name': 'United Arab Emirates', 'region': 'EMEA'},
        {'code': '4000', 'isoCode': 'DE', 'name': 'Germany', 'region': 'EMEA'},
        {'code': '5000', 'isoCode': 'IN', 'name': 'India', 'region': 'APAC'},
        {'code': '6000', 'isoCode': 'RU', 'name': 'Russia', 'region': 'EMEA'},
        {'code': '7000', 'isoCode': 'CN', 'name': 'China', 'region': 'APAC'},
        {'code': '8000', 'isoCode': 'AU', 'name': 'Australia', 'region': 'APAC'},
        {'code': '9000', 'isoCode': 'SG', 'name': 'Singapore', 'region': 'APAC'},
        {'code': 'A000', 'isoCode': 'ZA', 'name': 'South Africa', 'region': 'EMEA'},
        {'code': 'B000', 'isoCode': 'KZ', 'name': 'Kazakhstan', 'region': 'EMEA'}
    ]
    countries_df = pd.DataFrame(countries)
    countries_df.to_csv(f"{OUTPUT_DIR}/countries.csv", index=False)
    print(f"  Created: {OUTPUT_DIR}/countries.csv ({len(countries_df)} records)")
    
    # Business Roles
    business_roles = [
        {'roleId': 'ZC:FIN:FINANCE_MANAGER___:0000', 'name': 'FIN - Finance Manager - Master', 'module': 'FIN', 'country': None},
        {'roleId': 'ZC:S&D:SALES_ANALYST_____:0000', 'name': 'S&D - Sales Analyst - Master', 'module': 'S&D', 'country': None},
        {'roleId': 'ZC:DFE:WAREHOUSE_MANAGER_:0000', 'name': 'DFE - Warehouse Manager - Master', 'module': 'DFE', 'country': None},
        {'roleId': 'ZC:P2P:PO_CREATOR________:0000', 'name': 'P2P - PO-Creator - Master', 'module': 'P2P', 'country': None},
        {'roleId': 'ZC:P2P:PO_Releaser_______:0000', 'name': 'P2P - PO-Releaser - Master', 'module': 'P2P', 'country': None},
        {'roleId': 'ZC:FIN:GR_PROCESSOR______:0000', 'name': 'FIN - GR - Processor - Master', 'module': 'FIN', 'country': None},
        {'roleId': 'ZC:FIN:AP_CLERK__________:0000', 'name': 'FIN - AP-Clerk - Master', 'module': 'FIN', 'country': None},
        {'roleId': 'ZC:FIN:BUDGET_APPROVER___:0000', 'name': 'FIN - Budget-Approver - Master', 'module': 'FIN', 'country': None}
    ]
    roles_df = pd.DataFrame(business_roles)
    roles_df.to_csv(f"{OUTPUT_DIR}/business_roles.csv", index=False)
    print(f"  Created: {OUTPUT_DIR}/business_roles.csv ({len(roles_df)} records)")
    
    # Transactions
    transactions = [
        {'tcode': 'AJAB', 'description': 'Year-end closing', 'module': 'FI', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'ME21N', 'description': 'Purchase Order Creation', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'ME28', 'description': 'PO Approver', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'MIGO', 'description': 'Goods Receipt', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True},
        {'tcode': 'MIRO', 'description': 'Posting or Parking Invoice', 'module': 'MM', 'accessType': 'Maintain', 'isCritical': True}
    ]
    transactions_df = pd.DataFrame(transactions)
    transactions_df.to_csv(f"{OUTPUT_DIR}/transactions.csv", index=False)
    print(f"  Created: {OUTPUT_DIR}/transactions.csv ({len(transactions_df)} records)")
    
    # SOD Rules
    sod_rules = [
        {'ruleId': 'SOD_0001', 'name': 'PO Create vs Approve', 'function1': 'PO_CREATOR', 'function2': 'PO_RELEASER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0002', 'name': 'GR vs PO Create', 'function1': 'GR_PROCESSOR', 'function2': 'PO_CREATOR', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0003', 'name': 'GR vs PO Approve', 'function1': 'GR_PROCESSOR', 'function2': 'PO_RELEASER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0004', 'name': 'GR vs Invoice Approve', 'function1': 'GR_PROCESSOR', 'function2': 'BUDGET_APPROVER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0005', 'name': 'Invoice Post vs Approve', 'function1': 'AP_CLERK', 'function2': 'BUDGET_APPROVER', 'riskLevel': 'HIGH'},
        {'ruleId': 'SOD_0006', 'name': 'Budget Approve vs PO Create', 'function1': 'BUDGET_APPROVER', 'function2': 'PO_CREATOR', 'riskLevel': 'MEDIUM'}
    ]
    sod_df = pd.DataFrame(sod_rules)
    sod_df.to_csv(f"{OUTPUT_DIR}/sod_rules.csv", index=False)
    print(f"  Created: {OUTPUT_DIR}/sod_rules.csv ({len(sod_df)} records)")
    
    # Analysis Report
    report = {
        'generated_at': datetime.now().isoformat(),
        'summary': {
            'total_users': len(users),
            'total_countries': len(countries),
            'total_business_roles': len(business_roles),
            'total_transactions': len(transactions),
            'total_sod_rules': len(sod_rules)
        },
        'data_source': 'V3 Excel (embedded sample data)'
    }
    
    with open(f"{OUTPUT_DIR}/analysis_report.json", 'w') as f:
        json.dump(report, f, indent=2)
    print(f"  Created: {OUTPUT_DIR}/analysis_report.json")
    
    print("\nSample data generation complete!")


if __name__ == "__main__":
    main()
