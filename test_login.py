#!/usr/bin/env python3
"""Test login endpoint directly"""
import os
import requests
import json

os.environ["DATABASE_URL"] = "postgresql://ays:ayspass@localhost:55432/ays"

# Test login
url = "http://192.168.1.8:5000/api/auth/login"
payload = {
    "email": "manager1@example.com",
    "password": "Test123"
}

print("🧪 Testing login endpoint...")
print(f"URL: {url}")
print(f"Payload: {json.dumps(payload, indent=2)}\n")

try:
    response = requests.post(url, json=payload, timeout=5)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"❌ Error: {e}")
