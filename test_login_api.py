#!/usr/bin/env python3
"""Test login response format"""
import json
import requests

url = "http://192.168.1.8:5000/api/auth/login"
payload = {
    "email": "manager1@example.com",
    "password": "Test123"
}

print("Testing login endpoint directly...")
print(f"POST {url}")
print(f"Body: {json.dumps(payload)}\n")

try:
    response = requests.post(url, json=payload, timeout=5)
    print(f"Status Code: {response.status_code}")
    print(f"Response Headers: {dict(response.headers)}\n")
    print(f"Response Body:")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
