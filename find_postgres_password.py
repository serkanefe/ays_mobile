import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# Yaygın PostgreSQL şifreleri
common_passwords = [
    "",  # Boş şifre
    "postgres",
    "password",
    "admin",
    "123456",
    "12345678",
    "postgres123",
    "admin123",
    "1234",
    "123123",
    "0000",
]

HOST = "localhost"
PORT = "5432"

print("PostgreSQL superuser şifresi bulunuyor...\n")

for pwd in common_passwords:
    try:
        print(f"Deneniyor: '{pwd}'", end=" ... ")
        conn = psycopg2.connect(
            dbname="postgres",
            user="postgres",
            password=pwd,
            host=HOST,
            port=PORT,
            connect_timeout=3
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        print("✓ BAŞARILI!")
        print(f"\n{'='*60}")
        print(f"PostgreSQL superuser şifresi: '{pwd}'")
        print(f"{'='*60}")
        print(f"\nVersiyon: {version}\n")
        
        # Şifre bulundu, user ve database oluştur
        print("User ve database oluşturuluyor...")
        conn = psycopg2.connect(
            dbname="postgres",
            user="postgres",
            password=pwd,
            host=HOST,
            port=PORT
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # 1. User oluştur
        print("\n1. 'ays' kullanıcısı kontrol ediliyor...")
        cursor.execute("SELECT 1 FROM pg_roles WHERE rolname='ays'")
        user_exists = cursor.fetchone()
        
        if not user_exists:
            print("   'ays' kullanıcısı oluşturuluyor...")
            cursor.execute("CREATE USER ays WITH PASSWORD 'ayspass'")
            print("   ✓ 'ays' kullanıcısı oluşturuldu")
        else:
            print("   ✓ 'ays' kullanıcısı zaten mevcut")
        
        # 2. Database oluştur
        print("\n2. 'ays' database'i kontrol ediliyor...")
        cursor.execute("SELECT 1 FROM pg_database WHERE datname='ays'")
        db_exists = cursor.fetchone()
        
        if not db_exists:
            print("   'ays' database'i oluşturuluyor...")
            cursor.execute("CREATE DATABASE ays OWNER ays")
            print("   ✓ 'ays' database'i oluşturuldu")
        else:
            print("   ✓ 'ays' database'i zaten mevcut")
        
        cursor.close()
        conn.close()
        
        # 3. ays database'ine bağlanıp yetkileri ver
        print("\n3. Yetkiler veriliyor...")
        conn = psycopg2.connect(
            dbname="ays",
            user="postgres",
            password=pwd,
            host=HOST,
            port=PORT
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        cursor.execute("GRANT ALL PRIVILEGES ON DATABASE ays TO ays")
        cursor.execute("GRANT ALL PRIVILEGES ON SCHEMA public TO ays")
        print("   ✓ Tüm yetkiler verildi")
        
        cursor.close()
        conn.close()
        
        print("\n" + "="*60)
        print("✓ PostgreSQL kurulumu başarıyla tamamlandı!")
        print("="*60)
        print("\nArtık API'yi PostgreSQL ile başlatabilirsiniz:")
        print("$env:DATABASE_URL='postgresql://ays:ayspass@localhost:5432/ays'; python api.py")
        
        exit(0)
        
    except psycopg2.OperationalError as e:
        print("✗ Başarısız")
    except Exception as e:
        print(f"✗ Hata: {str(e)[:30]}")

print("\n" + "="*60)
print("❌ Hiçbir şifre çalışmadı!")
print("="*60)
print("\nPostgreSQL kurulumunda belirlediğiniz şifreyi hatırlamaya çalışın.")
print("Eğer SQL script ile kurulumu yaptıysanız, o sırada belirlenen şifreyi kullanın.\n")
