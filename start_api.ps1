# AYS API - PostgreSQL ile baslat
Write-Host "AYS API baslatiliyor..." -ForegroundColor Green
Write-Host "Veritabani: PostgreSQL (localhost:55432)" -ForegroundColor Cyan
Write-Host ""

# PostgreSQL baglanti bilgisi
$env:DATABASE_URL = 'postgresql://ays:ayspass@localhost:55432/ays'

# API'yi baslat (virtualenv python'u kullan)
./.venv/Scripts/python.exe api.py
