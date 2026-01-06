#!/usr/bin/env python3
"""Debug: Check user password in PostgreSQL"""
import os
os.environ["DATABASE_URL"] = "postgresql://ays:ayspass@localhost:55432/ays"

from database import SessionLocal, User
from werkzeug.security import check_password_hash

session = SessionLocal()
user = session.query(User).filter_by(email="manager1@example.com").first()

print("="*60)
print("🔍 USER CHECK")
print("="*60)

if user:
    print(f"\n✅ User found!")
    print(f"   Email: {user.email}")
    print(f"   Full Name: {user.full_name}")
    print(f"   Role: {user.role}")
    print(f"   Active: {user.is_active}")
    print(f"   Password Hash: {user.password[:50]}...")
    
    print(f"\n🔐 Password verification:")
    test_password = "Test123"
    is_valid = check_password_hash(user.password, test_password)
    print(f"   Password '{test_password}' is valid: {is_valid}")
    
    if not is_valid:
        print(f"\n❌ Password mismatch!")
        print(f"   Stored hash: {user.password}")
        print(f"   Testing against: {test_password}")
else:
    print(f"\n❌ User not found!")
    
    # List all users
    all_users = session.query(User).all()
    print(f"\nUsers in database ({len(all_users)} total):")
    for u in all_users:
        print(f"   • {u.email}")

session.close()
