from database import SessionLocal, Owner
from werkzeug.security import check_password_hash

session = SessionLocal()
owner = session.query(Owner).filter_by(email='manager1@example.com', is_active=True).first()

if owner:
    print(f"Kullanıcı bulundu: {owner.email}")
    print(f"Aktif: {owner.is_active}")
    print(f"Role: {owner.role}")
    
    # Test123 şifresini kontrol et
    is_valid = check_password_hash(owner.password, 'Test123')
    print(f"Şifre 'Test123' geçerli mi: {is_valid}")
else:
    print("manager1@example.com kullanıcısı bulunamadı veya aktif değil")

# Tüm kullanıcıları listele
all_owners = session.query(Owner).all()
print(f"\nToplam {len(all_owners)} malik:")
for o in all_owners:
    print(f"  - {o.email} ({o.role}, aktif={o.is_active})")

session.close()
