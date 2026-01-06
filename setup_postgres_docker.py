#!/usr/bin/env python3
"""Create PostgreSQL database and user for AYS"""
import subprocess
import sys
import time

def run_psql_cmd(cmd_list):
    """Run psql command via docker"""
    docker_cmd = ["docker", "exec", "-it", "ays-postgres", "psql", "-U", "postgres"] + cmd_list
    try:
        result = subprocess.run(docker_cmd, capture_output=True, text=True, timeout=10)
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return 1, "", str(e)

print("🔧 PostgreSQL setup başladı...\n")

# 1. Create role
print("1️⃣  Creating 'ays' role...")
returncode, stdout, stderr = run_psql_cmd(["-c", "CREATE ROLE ays WITH LOGIN PASSWORD 'ayspass';"])
if returncode == 0:
    print("   ✅ Role created (or already exists)")
elif "already exists" in stderr.lower():
    print("   ⚠️  Role already exists")
else:
    print(f"   ❌ Error: {stderr}")

time.sleep(1)

# 2. Create database
print("2️⃣  Creating 'ays' database...")
returncode, stdout, stderr = run_psql_cmd(["-c", "CREATE DATABASE ays OWNER ays;"])
if returncode == 0:
    print("   ✅ Database created")
elif "already exists" in stderr.lower():
    print("   ⚠️  Database already exists")
else:
    print(f"   ❌ Error: {stderr}")

time.sleep(1)

# 3. Grant privileges
print("3️⃣  Granting privileges...")
returncode, stdout, stderr = run_psql_cmd(["-d", "ays", "-c", "GRANT ALL PRIVILEGES ON DATABASE ays TO ays;"])
if returncode == 0:
    print("   ✅ Privileges granted")
else:
    print(f"   ⚠️  {stderr}")

time.sleep(1)

# 4. Test connection
print("4️⃣  Testing connection...")
returncode, stdout, stderr = run_psql_cmd(["-U", "ays", "-d", "ays", "-c", "SELECT 1;"])
if returncode == 0:
    print("   ✅ Connection successful!")
else:
    print(f"   ⚠️  Connection test result: {stderr[:100]}")

print("\n" + "="*50)
print("✅ PostgreSQL setup complete!")
print("="*50)
print("\n🔗 Connection string:")
print("   postgresql://ays:ayspass@localhost:55432/ays")
print("\n⚡ Next steps:")
print("   1. Set environment variable:")
print('      $env:DATABASE_URL="postgresql://ays:ayspass@localhost:55432/ays"')
print("   2. Restart backend: python api.py")
print("   3. Flutter app will auto-reconnect")
