#!/usr/bin/env python3
"""Check owners in PostgreSQL"""
import os
os.environ["DATABASE_URL"] = "postgresql://ays:ayspass@localhost:55432/ays"

from database import SessionLocal, Owner

session = SessionLocal()
owners = session.query(Owner).all()

print("="*60)
print(f"📊 OWNERS IN PostgreSQL ({len(owners)} total)")
print("="*60)

for owner in owners:
    print(f"\n✓ {owner.id}: {owner.full_name}")
    print(f"  Email: {owner.email}")
    print(f"  Phone: {owner.phone}")
    print(f"  Unit: {owner.unit_name}")
    print(f"  Type: {owner.owner_type}")
    print(f"  Active: {owner.is_active}")

session.close()

print("\n" + "="*60)
print("✅ Database check complete!")
print("="*60)
