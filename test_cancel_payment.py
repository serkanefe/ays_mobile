import os
os.environ['DATABASE_URL'] = 'postgresql://ays:ayspass@localhost:55432/ays'
from database import SessionLocal, Payment, Rent, Account
import requests
import json

session = SessionLocal()

# PAID rent'e ait payment bul
payment = session.query(Payment).filter(Payment.is_cancelled == False).first()
if not payment:
    print('Active payment yok')
    session.close()
    exit()

print(f'Payment ID: {payment.id}')
print(f'Rent ID: {payment.rent_id}')
print(f'Amount: {payment.amount}')
print(f'Account ID: {payment.account_id}')

# Account balance kontrol et
account = session.query(Account).filter(Account.id == payment.account_id).first()
print(f'Account balance BEFORE cancel: {account.balance}')

# Rent status kontrol et
rent = session.query(Rent).filter(Rent.id == payment.rent_id).first()
print(f'Rent status BEFORE cancel: {rent.status}')

session.close()

# API call yap
url = f'http://localhost:5000/api/payments/{payment.id}/cancel'
response = requests.put(url, json={'cancellation_reason': 'Test iptal'})
print(f'\nAPI Response: {response.status_code}')
print(f'Response: {response.json()}')

# Sonra kontrol et
session = SessionLocal()
payment = session.query(Payment).filter(Payment.id == payment.id).first()
account = session.query(Account).filter(Account.id == payment.account_id).first()
rent = session.query(Rent).filter(Rent.id == payment.rent_id).first()

print(f'\nAFTER cancel:')
print(f'Payment is_cancelled: {payment.is_cancelled}')
print(f'Account balance AFTER: {account.balance}')
print(f'Rent status AFTER: {rent.status}')

session.close()
