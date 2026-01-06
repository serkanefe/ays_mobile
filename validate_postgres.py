#!/usr/bin/env python3
"""Final PostgreSQL validation"""
import os
import sys

# Set DATABASE_URL before importing
os.environ["DATABASE_URL"] = "postgresql://ays:ayspass@localhost:55432/ays"

from database import SessionLocal, User, Owner
from sqlalchemy import inspect, create_engine

print("="*60)
print("PostgreSQL VALIDATION")
print("="*60)

# Get engine from database module
from database import engine

# 1. Check tables
print("\n1️⃣  Checking tables...")
inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"   Tables found: {len(tables)}")
for table in tables:
    print(f"      • {table}")

# 2. Check users
print("\n2️⃣  Checking users table...")
session = SessionLocal()
try:
    users = session.query(User).all()
    print(f"   Users count: {len(users)}")
    for user in users:
        print(f"      • {user.email} (Role: {user.role}, Active: {user.is_active})")
except Exception as e:
    print(f"   ❌ Error querying users: {e}")

# 3. Check owners
print("\n3️⃣  Checking owners table...")
try:
    owners = session.query(Owner).all()
    print(f"   Owners count: {len(owners)}")
    for owner in owners:
        print(f"      • {owner.full_name} ({owner.owner_type}) - {owner.unit_name}")
except Exception as e:
    print(f"   ❌ Error querying owners: {e}")

session.close()

print("\n" + "="*60)
print("✅ PostgreSQL validation complete!")
print("="*60)
print("\nConnection string: postgresql://ays:ayspass@localhost:55432/ays")
print("Backend URL: http://192.168.1.8:5000/api")
print("\nLogin credentials:")
print("   Email: manager1@example.com")
print("   Password: Test123")
