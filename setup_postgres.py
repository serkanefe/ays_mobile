#!/usr/bin/env python3
"""
PostgreSQL setup script - admin kullanıcı ve veritabanı oluştur
"""
import subprocess
import sys

# Host üzerinde Postgres'e root olarak bağlan
try:
    # ays kullanıcı ve database oluştur
    print("Creating 'ays' role and database...")
    
    cmd1 = [
        "psql",
        "-U", "postgres",
        "-h", "localhost",
        "-c", "CREATE ROLE ays WITH LOGIN PASSWORD 'ayspass';"
    ]
    
    cmd2 = [
        "psql",
        "-U", "postgres", 
        "-h", "localhost",
        "-c", "CREATE DATABASE ays OWNER ays;"
    ]
    
    cmd3 = [
        "psql",
        "-U", "postgres",
        "-h", "localhost",
        "-d", "ays",
        "-c", "GRANT ALL PRIVILEGES ON DATABASE ays TO ays;"
    ]
    
    for cmd in [cmd1, cmd2, cmd3]:
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                print(f"Warning: {result.stderr}")
        except Exception as e:
            print(f"Warning: {e}")
    
    print("✓ PostgreSQL setup complete!")
    print("\nNow run:")
    print("  $env:DATABASE_URL=\"postgresql://ays:ayspass@localhost:5432/ays\"")
    print("  C:\\.venv\\Scripts\\activate")
    print("  python api.py")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
