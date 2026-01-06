@echo off
setlocal
REM PostgreSQL bağlantı bilgileri
set DATABASE_URL=postgresql://ays:ayspass@localhost:5432/ays
echo DATABASE_URL=%DATABASE_URL%
python api.py
pause
