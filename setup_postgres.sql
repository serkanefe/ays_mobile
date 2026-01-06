-- AYS Mobile PostgreSQL Setup Script
-- pgAdmin veya psql ile çalıştırın

-- 1. Database ve user oluştur
CREATE USER ays WITH PASSWORD 'ayspass';
CREATE DATABASE ays OWNER ays;

-- 2. ays database'ine bağlan ve yetkileri ver
\c ays
GRANT ALL PRIVILEGES ON DATABASE ays TO ays;
GRANT ALL PRIVILEGES ON SCHEMA public TO ays;

-- 3. Tablolar otomatik olarak Python tarafından oluşturulacak
-- Bu script sadece database ve user hazırlığı için
