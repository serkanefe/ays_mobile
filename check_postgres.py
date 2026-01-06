#!/usr/bin/env python3
"""Check PostgreSQL connection and tables"""
import os
from sqlalchemy import create_engine, inspect

DATABASE_URL = "postgresql://ays:ayspass@localhost:55432/ays"

try:
    engine = create_engine(DATABASE_URL)
    
    # Test connection
    from sqlalchemy import text
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✅ PostgreSQL connection successful!")
    
    # List tables
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    
    print(f"\n📊 Tables in database ({len(tables)} total):")
    for table in tables:
        print(f"   • {table}")
    
    if "users" in tables:
        # Check users
        from database import User, SessionLocal
        session = SessionLocal()
        user_count = session.query(User).count()
        print(f"\n👥 Users in database: {user_count}")
        users = session.query(User).all()
        for user in users:
            print(f"   • {user.email} ({user.role})")
        session.close()
    
    print("\n✅ Database setup complete!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
