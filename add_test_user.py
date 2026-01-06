# -*- coding: utf-8 -*-
from werkzeug.security import generate_password_hash
from database import SessionLocal, Owner

# Database'ye baglan
session = SessionLocal()

# Test kullanicisi ekle
test_owner = Owner(
    full_name="Manager",
    email="manager1@example.com",
    password=generate_password_hash("Test123"),
    phone="05551234567",
    identity_number="12345678901",
    unit_name="A - 101",
    unit_type="Mesken",
    share_ratio=0.085,
    owner_type="PERSON",
    role="Manager",
)

session.add(test_owner)
session.commit()
print("✅ Test user added: manager1@example.com / Test123")
session.close()
