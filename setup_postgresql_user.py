import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# PostgreSQL superuser bilgileri
# NOT: PostgreSQL'i kurarken belirlediğiniz şifreyi girin
SUPERUSER = "postgres"
SUPERUSER_PASSWORD = "BURAYA_SUPERUSER_ŞIFRENIZI_YAZIN"  # PostgreSQL kurulumundaki şifre
HOST = "localhost"
PORT = "5432"

print("PostgreSQL'e bağlanılıyor...")
try:
    # Superuser olarak bağlan
    conn = psycopg2.connect(
        dbname="postgres",
        user=SUPERUSER,
        password=SUPERUSER_PASSWORD,
        host=HOST,
        port=PORT
    )
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cursor = conn.cursor()
    
    # 1. User var mı kontrol et
    print("\n1. 'ays' kullanıcısı kontrol ediliyor...")
    cursor.execute("SELECT 1 FROM pg_roles WHERE rolname='ays'")
    user_exists = cursor.fetchone()
    
    if not user_exists:
        print("   'ays' kullanıcısı oluşturuluyor...")
        cursor.execute("CREATE USER ays WITH PASSWORD 'ayspass'")
        print("   ✓ 'ays' kullanıcısı oluşturuldu")
    else:
        print("   ✓ 'ays' kullanıcısı zaten mevcut")
    
    # 2. Database var mı kontrol et
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
        user=SUPERUSER,
        password=SUPERUSER_PASSWORD,
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
    
    print("\n" + "="*50)
    print("✓ PostgreSQL kurulumu başarıyla tamamlandı!")
    print("="*50)
    print("\nArtık API'yi PostgreSQL ile başlatabilirsiniz:")
    print("$env:DATABASE_URL='postgresql://ays:ayspass@localhost:5432/ays'; python api.py")
    
except psycopg2.OperationalError as e:
    print(f"\n❌ Bağlantı hatası: {e}")
    print("\nMuhtemelen:")
    print("1. SUPERUSER_PASSWORD değişkenine yanlış şifre girdiniz")
    print("2. PostgreSQL servisi çalışmıyor olabilir")
    print("3. Port 5432 kullanımda değil (55432 olabilir)")
except Exception as e:
    print(f"\n❌ Beklenmeyen hata: {e}")
