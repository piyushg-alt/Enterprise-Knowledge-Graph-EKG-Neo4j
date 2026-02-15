# Neo4j Desktop Setup Guide for Aura Instance

## Step 1: Download Neo4j Desktop

1. Go to: **https://neo4j.com/download/**
2. Click **"Download Neo4j Desktop"**
3. Fill in the registration form (or sign in if you have an account)
4. Download the installer for Windows
5. **Important:** Copy the **Activation Key** shown after registration - you'll need it!

## Step 2: Install Neo4j Desktop

1. Run the downloaded installer (`neo4j-desktop-x.x.x-setup.exe`)
2. Follow the installation wizard
3. When prompted, enter your **Activation Key**
4. Complete the installation

## Step 3: Connect to Your Aura Instance

### Method 1: Using Remote Connection (Recommended)

1. Open **Neo4j Desktop**
2. Click **"Add"** button (top right) → Select **"Remote connection"**
3. Enter the following details:

   | Field | Value |
   |-------|-------|
   | **Name** | pax-ekg-neo4j-dev |
   | **Connect URL** | `neo4j+s://0d7d8d8c.databases.neo4j.io` |

4. Click **"Next"**
5. Select **"Username / Password"** authentication
6. Enter credentials:

   | Field | Value |
   |-------|-------|
   | **Username** | `neo4j` |
   | **Password** | `smSM_ZKdxzPfOK92eTimZvYdhjiVbAbfIbF8NWa6GF4` |

7. Click **"Save"**
8. Click **"Connect"** to establish the connection

### Method 2: Using Neo4j Browser Directly

1. Open **Neo4j Desktop**
2. After adding the remote connection, click on it
3. Click **"Open"** → **"Neo4j Browser"**
4. The browser will open with your Aura database connected

## Step 4: Visualize Your Data

Once connected in Neo4j Browser:

### Basic Queries to Explore Data

```cypher
// Show all nodes (limited to 25)
MATCH (n) RETURN n LIMIT 25

// Show database schema
CALL db.schema.visualization()

// Show all labels
CALL db.labels()

// Show all relationship types
CALL db.relationshipTypes()

// Count all nodes
MATCH (n) RETURN count(n)

// Count all relationships
MATCH ()-[r]->() RETURN count(r)
```

### Visualization Tips

1. **Graph View**: Results automatically display as interactive graphs
2. **Table View**: Click the table icon to see data in tabular format
3. **Zoom**: Use mouse scroll to zoom in/out on the graph
4. **Drag**: Click and drag nodes to rearrange the visualization
5. **Expand**: Double-click a node to see its connections

## Your Connection Details

Keep these handy for reference:

```
NEO4J_URI=neo4j+s://0d7d8d8c.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=smSM_ZKdxzPfOK92eTimZvYdhjiVbAbfIbF8NWa6GF4
NEO4J_DATABASE=neo4j
AURA_INSTANCEID=0d7d8d8c
AURA_INSTANCENAME=pax-ekg-neo4j-dev
```

## Alternative: Use Neo4j Aura Console

You can also access your database directly via the web:

1. Go to: **https://console.neo4j.io**
2. Sign in with your Neo4j Aura account
3. Select your instance **"pax-ekg-neo4j-dev"**
4. Click **"Open"** to launch Neo4j Browser in your web browser

## Troubleshooting

### Connection Issues
- Ensure your firewall allows outbound connections on port 7687
- Verify the URI starts with `neo4j+s://` (secure connection)
- Check that credentials are correct (password is case-sensitive)

### Empty Database
- Your database currently has 0 nodes and 0 relationships
- This is normal for a new instance
- You can start adding data using Cypher queries

## Quick Start: Add Sample Data

To test visualization, add some sample data:

```cypher
// Create sample nodes
CREATE (p1:Person {name: 'Alice', age: 30})
CREATE (p2:Person {name: 'Bob', age: 25})
CREATE (p3:Person {name: 'Charlie', age: 35})
CREATE (c:Company {name: 'TechCorp'})

// Create relationships
CREATE (p1)-[:KNOWS]->(p2)
CREATE (p2)-[:KNOWS]->(p3)
CREATE (p1)-[:WORKS_AT]->(c)
CREATE (p2)-[:WORKS_AT]->(c)

// View the graph
MATCH (n) RETURN n