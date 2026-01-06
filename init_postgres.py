#!/usr/bin/env python
import os
os.environ['DATABASE_URL'] = 'postgresql://ays:ayspass@localhost:55432/ays'

from database import init_db, SessionLocal, User, Owner

init_db()
print("✅ Database initialized with new schema")

# Verify users
session = SessionLocal()
users = session.query(User).all()
print(f"📋 Users: {len(users)}")
for user in users:
    print(f"   - {user.email}")

# Verify owners
owners = session.query(Owner).all()
print(f"📋 Owners: {len(owners)}")
for owner in owners:
    print(f"   - {owner.full_name} (Role: {owner.role}, Unit: {owner.unit_type})")
session.close()
