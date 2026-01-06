#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys
os.environ['DATABASE_URL'] = 'postgresql://ays:ayspass@localhost:55432/ays'

from database import SessionLocal, User
from werkzeug.security import check_password_hash

session = SessionLocal()
user = session.query(User).filter_by(email="manager1@example.com").first()

if user:
    print(f"[OK] User found: {user.email}")
    print(f"   Full name: {user.full_name}")
    print(f"   Role: {user.role}")
    print(f"   Password hash: {user.password[:20]}...")
    
    # Test password
    is_valid = check_password_hash(user.password, "Test123")
    print(f"   Password valid for 'Test123': {is_valid}")
else:
    print("[ERROR] User not found: manager1@example.com")
    print("\nAll users in DB:")
    users = session.query(User).all()
    for u in users:
        print(f"   - {u.email}")

session.close()
