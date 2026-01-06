#!/usr/bin/env python3
"""Create AYS database and user"""
import os
from sqlalchemy import create_engine, text

# Host Postgres'e admin olarak bağlan
admin_url = "postgresql://postgres:postgres@localhost:5432/postgres"
engine = create_engine(admin_url)

try:
    with engine.connect() as conn:
        conn.execution_options(isolation_level="AUTOCOMMIT")
        
        # Rol zaten varsa atla
        try:
            conn.execute(text("CREATE ROLE ays WITH LOGIN PASSWORD 'ayspass';"))
            print("✓ Created role 'ays'")
        except Exception as e:
            if "already exists" in str(e):
                print("⚠ Role 'ays' already exists")
            else:
                raise
        
        # Database zaten varsa atla
        try:
            conn.execute(text("CREATE DATABASE ays OWNER ays;"))
            print("✓ Created database 'ays'")
        except Exception as e:
            if "already exists" in str(e):
                print("⚠ Database 'ays' already exists")
            else:
                raise
        
        # Privileges
        conn.execute(text("GRANT ALL PRIVILEGES ON DATABASE ays TO ays;"))
        print("✓ Granted privileges to 'ays'")
        
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    engine.dispose()

print("\n✅ Setup complete!")
