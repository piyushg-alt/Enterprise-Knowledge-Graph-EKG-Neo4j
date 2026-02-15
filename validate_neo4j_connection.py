"""
Neo4j Aura Instance Connection Validator
Validates connectivity to the Neo4j Aura instance and verifies database accessibility.
"""

from neo4j import GraphDatabase
import sys

# Neo4j Aura connection details
NEO4J_URI = "neo4j+s://0d7d8d8c.databases.neo4j.io"
NEO4J_USERNAME = "neo4j"
NEO4J_PASSWORD = "smSM_ZKdxzPfOK92eTimZvYdhjiVbAbfIbF8NWa6GF4"
NEO4J_DATABASE = "neo4j"
AURA_INSTANCEID = "0d7d8d8c"
AURA_INSTANCENAME = "pax-ekg-neo4j-dev"

def validate_connection():
    """Validate connection to Neo4j Aura instance."""
    print("=" * 60)
    print("Neo4j Aura Instance Connection Validator")
    print("=" * 60)
    print(f"\nInstance Details:")
    print(f"  - Instance ID: {AURA_INSTANCEID}")
    print(f"  - Instance Name: {AURA_INSTANCENAME}")
    print(f"  - URI: {NEO4J_URI}")
    print(f"  - Database: {NEO4J_DATABASE}")
    print(f"  - Username: {NEO4J_USERNAME}")
    print()
    
    driver = None
    try:
        print("Step 1: Creating driver connection...")
        driver = GraphDatabase.driver(
            NEO4J_URI,
            auth=(NEO4J_USERNAME, NEO4J_PASSWORD)
        )
        print("  ✓ Driver created successfully")
        
        print("\nStep 2: Verifying connectivity...")
        driver.verify_connectivity()
        print("  ✓ Connectivity verified")
        
        print("\nStep 3: Testing database access...")
        with driver.session(database=NEO4J_DATABASE) as session:
            # Get server info
            result = session.run("CALL dbms.components() YIELD name, versions, edition")
            record = result.single()
            print(f"  ✓ Connected to Neo4j {record['name']}")
            print(f"    - Version: {record['versions'][0]}")
            print(f"    - Edition: {record['edition']}")
            
            # Get database info
            result = session.run("CALL db.info() YIELD name, id")
            record = result.single()
            print(f"  ✓ Database Info:")
            print(f"    - Name: {record['name']}")
            print(f"    - ID: {record['id']}")
            
            # Get node count
            result = session.run("MATCH (n) RETURN count(n) as nodeCount")
            record = result.single()
            print(f"  ✓ Node count: {record['nodeCount']}")
            
            # Get relationship count
            result = session.run("MATCH ()-[r]->() RETURN count(r) as relCount")
            record = result.single()
            print(f"  ✓ Relationship count: {record['relCount']}")
            
            # Get labels
            result = session.run("CALL db.labels() YIELD label RETURN collect(label) as labels")
            record = result.single()
            labels = record['labels']
            print(f"  ✓ Labels ({len(labels)}): {', '.join(labels) if labels else 'None'}")
            
            # Get relationship types
            result = session.run("CALL db.relationshipTypes() YIELD relationshipType RETURN collect(relationshipType) as types")
            record = result.single()
            types = record['types']
            print(f"  ✓ Relationship Types ({len(types)}): {', '.join(types) if types else 'None'}")
        
        print("\n" + "=" * 60)
        print("VALIDATION RESULT: SUCCESS")
        print("=" * 60)
        print(f"\n✓ Neo4j Aura instance '{AURA_INSTANCENAME}' is AVAILABLE and ACCESSIBLE")
        print(f"✓ All connection tests passed successfully")
        return True
        
    except Exception as e:
        print(f"\n✗ ERROR: {type(e).__name__}: {str(e)}")
        print("\n" + "=" * 60)
        print("VALIDATION RESULT: FAILED")
        print("=" * 60)
        return False
        
    finally:
        if driver:
            driver.close()
            print("\nDriver connection closed.")

if __name__ == "__main__":
    success = validate_connection()
    sys.exit(0 if success else 1)