#!/usr/bin/env python
import os
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

os.environ['DATABASE_URL'] = 'postgresql://ays:ayspass@localhost:55432/ays'

# Connect to PostgreSQL
conn = psycopg2.connect(
    host='localhost',
    port=55432,
    database='ays',
    user='ays',
    password='ayspass'
)
conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
cursor = conn.cursor()

try:
    # Drop tables
    cursor.execute("DROP TABLE IF EXISTS payments CASCADE;")
    cursor.execute("DROP TABLE IF EXISTS rents CASCADE;")
    cursor.execute("DROP TABLE IF EXISTS owners CASCADE;")
    cursor.execute("DROP TABLE IF EXISTS users CASCADE;")
    print("[OK] Tables dropped")
    
    cursor.close()
    conn.close()
    
    # Now initialize with new schema
    from database import init_db, SessionLocal, Owner
    
    init_db()
    print("[OK] Database initialized with new schema")
    
    # Verify
    session = SessionLocal()
    owners = session.query(Owner).all()
    print(f"[OK] Owners: {len(owners)}")
    for owner in owners:
        print(f"   - {owner.full_name} ({owner.email}) Role: {owner.role}")
    session.close()
    
except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
