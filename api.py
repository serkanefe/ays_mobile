# -*- coding: utf-8 -*-
from flask import Flask, request, jsonify, make_response, send_file
from flask_cors import CORS
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import func
from database import (
  SessionLocal,
  init_db,
  Owner,
  Rent,
  Payment,
  Settings,
  Category,
  Account,
  Transaction,
  Expense,
)
import shutil
import os
from datetime import datetime
from decimal import Decimal, InvalidOperation
from flask_socketio import SocketIO, emit

init_db()

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins='*', async_mode='threading')

# CORS: tüm kaynaktan gelen istekleri kabul et
CORS(app, 
     resources={r"/*": {"origins": "*"}},
     allow_headers=["Content-Type", "Authorization"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
     supports_credentials=True)

ALLOW_NEGATIVE_BALANCE = os.environ.get("ALLOW_NEGATIVE_BALANCE", "false").lower() == "true"


def _to_decimal(value):
  if value is None:
    return None
  try:
    return Decimal(str(value))
  except (InvalidOperation, ValueError, TypeError):
    return None


def _json_account(acc: Account):
  return {
    'id': acc.id,
    'name': acc.name,
    'type': acc.type,
    'balance': float(acc.balance or 0),
    'is_active': acc.is_active,
    'created_at': acc.created_at.isoformat() if acc.created_at else None,
    'updated_at': acc.updated_at.isoformat() if acc.updated_at else None,
  }


def _json_transaction(tx: Transaction):
  return {
    'id': tx.id,
    'account_id': tx.account_id,
    'related_account': tx.related_account,
    'type': tx.type,
    'source': tx.source,
    'related_id': tx.related_id,
    'amount': float(tx.amount or 0),
    'description': tx.description,
    'is_canceled': tx.is_canceled,
    'created_by': tx.created_by,
    'created_at': tx.created_at.isoformat() if tx.created_at else None,
  }


def _json_expense(exp: Expense, category: Category = None, account: Account = None):
  cat = category if category is not None else getattr(exp, 'category', None)
  acc = account if account is not None else getattr(exp, 'account', None)
  return {
    'id': exp.id,
    'name': exp.name,
    'category_id': exp.category_id,
    'category_name': cat.name if cat else None,
    'account_id': exp.account_id,
    'account_name': acc.name if acc else None,
    'account_type': acc.type if acc else None,
    'amount': float(exp.amount or 0),
    'payee': exp.payee,
    'receipt_no': exp.receipt_no,
    'maintenance_agreement_id': exp.maintenance_agreement_id,
    'date': exp.expense_date.isoformat() if exp.expense_date else None,
    'created_at': exp.created_at.isoformat() if exp.created_at else None,
    'updated_at': exp.updated_at.isoformat() if exp.updated_at else None,
  }

@app.before_request
def handle_preflight():
  """OPTIONS isteğini handle et (CORS preflight)"""
  if request.method == "OPTIONS":
    response = make_response()
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add("Access-Control-Allow-Headers", "Content-Type,Authorization")
    response.headers.add("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS")
    response.headers.add("Access-Control-Max-Age", "3600")
    return response, 200

@app.route('/api/test', methods=['GET', 'POST', 'OPTIONS'])
def test():
  return jsonify({'status': 'ok', 'method': request.method})

@app.route('/api/auth/login', methods=['POST'])
def login():
  data = request.json or {}
  email = data.get('email')
  password = data.get('password')
  print(f"[LOGIN] Email: {email}, Password: {password[:3] if password else 'None'}...")  # Debug
  if not email or not password:
    return jsonify({'success': False, 'message': 'E-posta ve şifre gerekli'}), 400
  session = SessionLocal()
  owner = session.query(Owner).filter_by(email=email, is_active=True).first()
  print(f"[LOGIN] Owner found: {owner is not None}")  # Debug
  if owner:
    print(f"[LOGIN] Checking password hash...")  # Debug
    is_valid = check_password_hash(owner.password, password)
    print(f"[LOGIN] Password valid: {is_valid}")  # Debug
  
  if owner and check_password_hash(owner.password, password):
    user_data = {
      'id': owner.id,
      'email': owner.email,
      'full_name': owner.full_name,
      'role': owner.role,
      'token': 'dev-token',
      'is_active': owner.is_active,
    }
    print(f"[LOGIN] [OK] Login success for {email}")  # Debug
    session.close()
    return jsonify({'success': True, 'user': user_data})
  print(f"[LOGIN] [ERROR] Login failed for {email}")  # Debug
  session.close()
  return jsonify({'success': False, 'message': 'E-posta veya şifre hatalı'}), 401

@app.route('/api/owners', methods=['GET'])
def get_owners():
  session = SessionLocal()
  owners = session.query(Owner).filter(Owner.is_active == True).all()
  result = []
  for o in owners:
    total_rent = sum(r.amount for r in o.rents)
    total_paid = sum(p.amount for p in o.payments)
    result.append({
      'id': o.id,
      'full_name': o.full_name,
      'email': o.email,
      'phone': o.phone,
      'identity_number': o.identity_number,
      'unit_name': o.unit_name,
      'unit_type': o.unit_type,
      'share_ratio': o.share_ratio * 100 if o.share_ratio else 0,  # 0-1 aralığını yüzdeye dönüştür
      'owner_type': o.owner_type,
      'role': o.role,
      'tenant_name': o.tenant_name,
      'tenant_email': o.tenant_email,
      'is_active': o.is_active,
      'total_rent': total_rent,
      'total_paid': total_paid,
      'remaining_debt': max(total_rent - total_paid, 0),
    })
  session.close()
  return jsonify({'owners': result})

@app.route('/api/owners', methods=['POST'])
def create_owner():
  data = request.json or {}
  session = SessionLocal()
  
  # Password: Flutter'dan geliyorsa kullan, yoksa geçici şifre oluştur
  password = data.get('password') or 'Temp123'
  password_hash = generate_password_hash(password)
  
  # Share ratio: yüzde olarak gelse de float'a dönüştür
  share_ratio = None
  if data.get('share_ratio'):
    try:
      share_ratio = float(data.get('share_ratio')) / 100  # Yüzdeyi 0-1 aralığına dönüştür
    except (ValueError, TypeError):
      share_ratio = None
  
  owner = Owner(
    full_name=data.get('full_name', ''),
    email=data.get('email', ''),
    password=password_hash,
    phone=data.get('phone'),
    identity_number=data.get('identity_number'),
    unit_name=data.get('unit_name'),
    unit_type=data.get('unit_type'),
    share_ratio=share_ratio,
    owner_type=data.get('owner_type', 'PERSON'),
    role=data.get('role', 'Malik'),
    tenant_name=data.get('tenant_name'),
    tenant_email=data.get('tenant_email'),
    is_active=True,
  )
  session.add(owner)
  session.commit()
  session.refresh(owner)
  
  owner_data = {
    'id': owner.id,
    'full_name': owner.full_name,
    'email': owner.email,
    'phone': owner.phone,
    'identity_number': owner.identity_number,
    'unit_name': owner.unit_name,
    'unit_type': owner.unit_type,
    'share_ratio': owner.share_ratio * 100 if owner.share_ratio else 0,
    'owner_type': owner.owner_type,
    'role': owner.role,
    'tenant_name': owner.tenant_name,
    'tenant_email': owner.tenant_email,
    'is_active': owner.is_active,
    'total_rent': 0,
    'total_paid': 0,
    'remaining_debt': 0,
  }
  
  session.close()
  return jsonify({'success': True, 'owner': owner_data}), 201

@app.route('/api/owners/<int:owner_id>', methods=['GET'])
def owner_detail(owner_id):
  session = SessionLocal()
  o = session.query(Owner).filter_by(id=owner_id).first()
  if not o:
    session.close()
    return jsonify({'success': False, 'message': 'Malik bulunamadı'}), 404
  total_rent = sum(r.amount for r in o.rents)
  total_paid = sum(p.amount for p in o.payments)
  result = {
    'id': o.id,
    'full_name': o.full_name,
    'email': o.email,
    'phone': o.phone,
    'identity_number': o.identity_number,
    'unit_name': o.unit_name,
    'share_ratio': o.share_ratio,
    'owner_type': o.owner_type,
    'is_active': o.is_active,
    'total_rent': total_rent,
    'total_paid': total_paid,
    'remaining_debt': max(total_rent - total_paid, 0),
  }
  session.close()
  return jsonify({'owner': result})

@app.route('/api/owners/<int:owner_id>', methods=['PUT'])
def update_owner(owner_id):
  data = request.json or {}
  session = SessionLocal()
  o = session.query(Owner).filter_by(id=owner_id).first()
  if not o:
    session.close()
    return jsonify({'success': False, 'message': 'Malik bulunamadı'}), 404
  for field in ['full_name', 'email', 'phone', 'identity_number', 'unit_name', 'share_ratio', 'owner_type']:
    if field in data and data[field] is not None:
      setattr(o, field, data[field])
  if 'is_active' in data:
    o.is_active = bool(data['is_active'])
  session.commit()
  session.close()
  return jsonify({'success': True, 'message': 'Güncellendi'})

@app.route('/api/owners/<int:owner_id>', methods=['DELETE'])
def delete_owner(owner_id):
  session = SessionLocal()
  o = session.query(Owner).filter_by(id=owner_id).first()
  if not o:
    session.close()
    return jsonify({'success': False, 'message': 'Malik bulunamadı'}), 404
  o.is_active = False
  session.commit()
  session.close()
  return jsonify({'success': True, 'message': 'Pasif edildi'})

@app.route('/api/owners/<int:owner_id>/financial-summary', methods=['GET'])
def owner_financial_summary(owner_id):
  session = SessionLocal()
  o = session.query(Owner).filter_by(id=owner_id).first()
  if not o:
    session.close()
    return jsonify({'success': False, 'message': 'Malik bulunamadı'}), 404
  total_rent = sum(r.amount for r in o.rents)
  total_paid = sum(p.amount for p in o.payments)
  session.close()
  return jsonify({
    'owner_id': owner_id,
    'total_rent': total_rent,
    'total_paid': total_paid,
    'remaining_debt': max(total_rent - total_paid, 0),
    'currency': 'TRY'
  })

@app.route('/api/dashboard/stats', methods=['GET'])
def dashboard_stats():
  try:
    session = SessionLocal()
    try:
      # Malik sayısı
      owners_count = session.query(Owner).filter(Owner.is_active == True).count()
      
      # Ödenmemiş aidat sayısı
      unpaid_rents_count = session.query(Rent).filter(Rent.status == 'UNPAID').count()
      
      # Toplam borç (ödenmemiş aidatlar)
      unpaid_rents = session.query(Rent).filter(Rent.status == 'UNPAID').all()
      total_debt = sum(r.amount for r in unpaid_rents) if unpaid_rents else 0
      
      # Bu ay tahsilat (ödenmemiş/iptal olmayan ödemeler)
      this_month = datetime.utcnow()
      monthly_payments = session.query(Payment).filter(
        Payment.is_cancelled == False,
        Payment.payment_date >= datetime(this_month.year, this_month.month, 1)
      ).all()
      monthly_collection = sum(p.amount for p in monthly_payments) if monthly_payments else 0
      
      session.close()
      return jsonify({
        'totalUnits': owners_count,
        'unpaidRents': unpaid_rents_count,
        'totalDebt': float(total_debt),
        'monthlyCollection': float(monthly_collection),
      })
    finally:
      session.close()
  except Exception as e:
    print(f"Dashboard error: {e}")
    return jsonify({'totalUnits': 0, 'unpaidRents': 0, 'totalDebt': 0.0, 'monthlyCollection': 0.0})


# EXPENSES API
@app.route('/api/expenses', methods=['GET'])
def list_expenses():
  session = SessionLocal()
  try:
    q = session.query(Expense, Account, Category)
    q = q.join(Account, Expense.account_id == Account.id)
    q = q.join(Category, Expense.category_id == Category.id)

    if request.args.get('account_id'):
      try:
        q = q.filter(Expense.account_id == int(request.args.get('account_id')))
      except ValueError:
        pass

    if request.args.get('category_id'):
      try:
        q = q.filter(Expense.category_id == int(request.args.get('category_id')))
      except ValueError:
        pass

    expenses = q.order_by(Expense.expense_date.desc(), Expense.id.desc()).all()
    result = [_json_expense(exp, cat, acc) for exp, acc, cat in expenses]
    return jsonify({'expenses': result})
  finally:
    session.close()


@app.route('/api/expenses', methods=['POST'])
def create_expense_record():
  data = request.json or {}
  name = (data.get('name') or '').strip()
  category_id = data.get('category_id')
  account_id = data.get('account_id')
  amount = _to_decimal(data.get('amount'))
  receipt_no = data.get('receipt_no')
  payee = data.get('payee')
  maintenance_agreement_id = data.get('maintenance_agreement_id')
  date_str = data.get('date')

  if not name or not category_id or not account_id or amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'name, category_id, account_id ve pozitif amount gerekli'}), 400

  try:
    category_id = int(category_id)
    account_id = int(account_id)
  except (TypeError, ValueError):
    return jsonify({'success': False, 'message': 'category_id ve account_id sayısal olmalı'}), 400

  expense_date = None
  if date_str:
    try:
      expense_date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except ValueError:
      return jsonify({'success': False, 'message': 'Geçersiz tarih formatı'}), 400

  session = SessionLocal()
  try:
    acc = session.query(Account).filter(Account.id == account_id, Account.is_active == True).with_for_update().first()
    cat = session.query(Category).filter(Category.id == category_id, Category.is_active == True).first()
    if not acc:
      session.close()
      return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404
    if not cat:
      session.close()
      return jsonify({'success': False, 'message': 'Kategori bulunamadı'}), 404

    _apply_balance(acc, -amount)

    exp = Expense(
      name=name,
      category_id=category_id,
      account_id=account_id,
      amount=amount,
      payee=payee,
      receipt_no=receipt_no,
      expense_date=expense_date,
      maintenance_agreement_id=maintenance_agreement_id,
    )
    session.add(exp)
    session.flush()  # id için

    tx = Transaction(
      account_id=acc.id,
      type='EXPENSE',
      source='EXPENSE',
      related_id=exp.id,
      amount=amount,
      description=name,
      created_by=data.get('created_by'),
    )
    session.add(tx)
    session.commit()
    session.refresh(exp)
    session.refresh(acc)
    return jsonify({'success': True, 'expense': _json_expense(exp, cat, acc), 'account': _json_account(acc)}), 201
  except Exception as e:
    session.rollback()
    return jsonify({'success': False, 'message': str(e)}), 400
  finally:
    session.close()


@app.route('/api/expenses/<int:expense_id>', methods=['PUT'])
def update_expense_record(expense_id):
  data = request.json or {}
  session = SessionLocal()
  try:
    exp = session.query(Expense).filter(Expense.id == expense_id).with_for_update().first()
    if not exp:
      session.close()
      return jsonify({'success': False, 'message': 'Gider bulunamadı'}), 404

    new_name = (data.get('name') or exp.name).strip()
    try:
      new_category_id = int(data.get('category_id', exp.category_id))
      new_account_id = int(data.get('account_id', exp.account_id))
    except (TypeError, ValueError):
      session.close()
      return jsonify({'success': False, 'message': 'category_id ve account_id sayısal olmalı'}), 400
    new_amount = _to_decimal(data.get('amount', exp.amount))
    if not new_name or not new_category_id or not new_account_id or new_amount is None or new_amount <= 0:
      session.close()
      return jsonify({'success': False, 'message': 'Geçerli name, category_id, account_id ve amount gerekli'}), 400

    date_str = data.get('date')
    if date_str:
      try:
        exp.expense_date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
      except ValueError:
        session.close()
        return jsonify({'success': False, 'message': 'Geçersiz tarih formatı'}), 400

    old_account = session.query(Account).filter(Account.id == exp.account_id, Account.is_active == True).with_for_update().first()
    if not old_account:
      session.close()
      return jsonify({'success': False, 'message': 'Mevcut hesap bulunamadı'}), 404

    cat = session.query(Category).filter(Category.id == new_category_id, Category.is_active == True).first()
    if not cat:
      session.close()
      return jsonify({'success': False, 'message': 'Kategori bulunamadı'}), 404

    if new_account_id == exp.account_id:
      delta = new_amount - exp.amount
      _apply_balance(old_account, -delta)
      target_account = old_account
    else:
      new_account = session.query(Account).filter(Account.id == new_account_id, Account.is_active == True).with_for_update().first()
      if not new_account:
        session.close()
        return jsonify({'success': False, 'message': 'Yeni hesap bulunamadı'}), 404
      _apply_balance(old_account, exp.amount)
      _apply_balance(new_account, -new_amount)
      target_account = new_account
      exp.account_id = new_account_id

    exp.name = new_name
    exp.category_id = new_category_id
    exp.amount = new_amount
    exp.payee = data.get('payee', exp.payee)
    exp.receipt_no = data.get('receipt_no', exp.receipt_no)
    exp.maintenance_agreement_id = data.get('maintenance_agreement_id', exp.maintenance_agreement_id)

    # İlişkili transaction güncelle
    tx = session.query(Transaction).filter(
      Transaction.source == 'EXPENSE', Transaction.related_id == exp.id, Transaction.is_canceled == False
    ).with_for_update().first()
    if tx:
      tx.account_id = exp.account_id
      tx.amount = new_amount
      tx.description = exp.name
    else:
      tx = Transaction(
        account_id=exp.account_id,
        type='EXPENSE',
        source='EXPENSE',
        related_id=exp.id,
        amount=new_amount,
        description=exp.name,
        created_by=data.get('created_by'),
      )
      session.add(tx)

    session.commit()
    session.refresh(exp)
    session.refresh(target_account)
    return jsonify({'success': True, 'expense': _json_expense(exp, cat, target_account), 'account': _json_account(target_account)})
  except Exception as e:
    session.rollback()
    return jsonify({'success': False, 'message': str(e)}), 400
  finally:
    session.close()


@app.route('/api/expenses/<int:expense_id>', methods=['DELETE'])
def delete_expense_record(expense_id):
  session = SessionLocal()
  try:
    exp = session.query(Expense).filter(Expense.id == expense_id).with_for_update().first()
    if not exp:
      session.close()
      return jsonify({'success': False, 'message': 'Gider bulunamadı'}), 404

    acc = session.query(Account).filter(Account.id == exp.account_id, Account.is_active == True).with_for_update().first()
    if acc:
      _apply_balance(acc, exp.amount)

    tx = session.query(Transaction).filter(
      Transaction.source == 'EXPENSE', Transaction.related_id == exp.id, Transaction.is_canceled == False
    ).with_for_update().first()
    if tx:
      tx.is_canceled = True

    session.delete(exp)
    session.commit()
    response = {'success': True, 'message': 'Gider silindi'}
    if acc:
      response['account'] = _json_account(acc)
    return jsonify(response)
  except Exception as e:
    session.rollback()
    return jsonify({'success': False, 'message': str(e)}), 400
  finally:
    session.close()


# ACCOUNTS API
@app.route('/api/accounts', methods=['GET'])
def list_accounts():
  session = SessionLocal()
  is_active = request.args.get('is_active')
  q = session.query(Account)
  if is_active is not None:
    q = q.filter(Account.is_active == (is_active.lower() == 'true'))
  accounts = q.order_by(Account.id.desc()).all()
  result = [_json_account(a) for a in accounts]
  session.close()
  return jsonify({'accounts': result})


@app.route('/api/accounts', methods=['POST'])
def create_account():
  data = request.json or {}
  name = (data.get('name') or '').strip()
  acc_type = (data.get('type') or '').upper()
  initial_balance = _to_decimal(data.get('balance') or 0) or Decimal('0')

  if not name or acc_type not in ('CASH', 'BANK'):
    return jsonify({'success': False, 'message': 'Geçerli isim ve tip (CASH/BANK) gerekli'}), 400

  session = SessionLocal()
  try:
    existing = session.query(Account).filter(Account.name == name, Account.is_active == True).first()
    if existing:
      session.close()
      return jsonify({'success': False, 'message': 'Bu adla aktif hesap zaten var'}), 409

    acc = Account(name=name, type=acc_type, balance=initial_balance)
    session.add(acc)
    session.commit()
    session.refresh(acc)
    result = _json_account(acc)
    session.close()
    return jsonify({'success': True, 'account': result}), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/accounts/<int:account_id>', methods=['GET'])
def get_account(account_id):
  session = SessionLocal()
  acc = session.query(Account).filter(Account.id == account_id).first()
  if not acc:
    session.close()
    return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404
  result = _json_account(acc)
  session.close()
  return jsonify({'success': True, 'account': result})


@app.route('/api/accounts/<int:account_id>', methods=['PUT'])
def update_account(account_id):
  data = request.json or {}
  session = SessionLocal()
  acc = session.query(Account).filter(Account.id == account_id).first()
  if not acc:
    session.close()
    return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404

  new_name = data.get('name')
  new_type = data.get('type')

  if new_name:
    existing = session.query(Account).filter(Account.name == new_name, Account.id != account_id, Account.is_active == True).first()
    if existing:
      session.close()
      return jsonify({'success': False, 'message': 'Bu adla başka aktif hesap var'}), 409
    acc.name = new_name

  if new_type:
    t = new_type.upper()
    if t not in ('CASH', 'BANK'):
      session.close()
      return jsonify({'success': False, 'message': 'Tip CASH veya BANK olmalı'}), 400
    acc.type = t

  if 'is_active' in data:
    acc.is_active = bool(data.get('is_active'))

  acc.updated_at = datetime.utcnow()
  session.commit()
  result = _json_account(acc)
  session.close()
  return jsonify({'success': True, 'account': result})


@app.route('/api/accounts/<int:account_id>', methods=['DELETE'])
def deactivate_account(account_id):
  session = SessionLocal()
  acc = session.query(Account).filter(Account.id == account_id).first()
  if not acc:
    session.close()
    return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404
  acc.is_active = False
  acc.updated_at = datetime.utcnow()
  session.commit()
  result = _json_account(acc)
  session.close()
  return jsonify({'success': True, 'account': result, 'message': 'Hesap pasif edildi'})


# TRANSACTIONS API
@app.route('/api/transactions', methods=['GET'])
def list_transactions():
  session = SessionLocal()
  q = session.query(Transaction)
  if request.args.get('account_id'):
    try:
      aid = int(request.args.get('account_id'))
      q = q.filter(Transaction.account_id == aid)
    except ValueError:
      pass
  if request.args.get('type'):
    q = q.filter(Transaction.type == request.args.get('type').upper())
  if request.args.get('source'):
    q = q.filter(Transaction.source == request.args.get('source').upper())
  if request.args.get('is_canceled'):
    q = q.filter(Transaction.is_canceled == (request.args.get('is_canceled').lower() == 'true'))

  txs = q.order_by(Transaction.created_at.desc()).all()
  result = [_json_transaction(t) for t in txs]
  session.close()
  return jsonify({'transactions': result})


def _apply_balance(acc: Account, delta: Decimal):
  new_balance = (acc.balance or Decimal('0')) + delta
  if not ALLOW_NEGATIVE_BALANCE and new_balance < 0:
    raise ValueError('Bakiye negatif olamaz')
  acc.balance = new_balance


@app.route('/api/transactions/income', methods=['POST'])
def create_income():
  data = request.json or {}
  account_id = data.get('account_id')
  amount = _to_decimal(data.get('amount'))
  if not account_id or amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'account_id ve pozitif amount gerekli'}), 400

  session = SessionLocal()
  try:
    acc = session.query(Account).filter(Account.id == account_id, Account.is_active == True).with_for_update().first()
    if not acc:
      session.close()
      return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404

    _apply_balance(acc, amount)
    tx = Transaction(
      account_id=acc.id,
      type='INCOME',
      source=(data.get('source') or 'MANUAL').upper(),
      amount=amount,
      description=data.get('description'),
      created_by=data.get('created_by'),
    )
    session.add(tx)
    session.commit()
    session.refresh(tx)
    result = _json_transaction(tx)
    session.close()
    return jsonify({'success': True, 'transaction': result, 'account': _json_account(acc)}), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/transactions/expense', methods=['POST'])
def create_expense():
  data = request.json or {}
  account_id = data.get('account_id')
  amount = _to_decimal(data.get('amount'))
  if not account_id or amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'account_id ve pozitif amount gerekli'}), 400

  session = SessionLocal()
  try:
    acc = session.query(Account).filter(Account.id == account_id, Account.is_active == True).with_for_update().first()
    if not acc:
      session.close()
      return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404

    _apply_balance(acc, -amount)
    tx = Transaction(
      account_id=acc.id,
      type='EXPENSE',
      source=(data.get('source') or 'MANUAL').upper(),
      amount=amount,
      description=data.get('description'),
      created_by=data.get('created_by'),
    )
    session.add(tx)
    session.commit()
    session.refresh(tx)
    result = _json_transaction(tx)
    session.close()
    return jsonify({'success': True, 'transaction': result, 'account': _json_account(acc)}), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/transactions/transfer', methods=['POST'])
def create_transfer():
  data = request.json or {}
  src_id = data.get('source_account_id')
  dst_id = data.get('target_account_id')
  amount = _to_decimal(data.get('amount'))

  if not src_id or not dst_id or src_id == dst_id:
    return jsonify({'success': False, 'message': 'Farklı kaynak ve hedef hesap gerekli'}), 400
  if amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'Pozitif amount gerekli'}), 400

  session = SessionLocal()
  try:
    src = session.query(Account).filter(Account.id == src_id, Account.is_active == True).with_for_update().first()
    dst = session.query(Account).filter(Account.id == dst_id, Account.is_active == True).with_for_update().first()
    if not src or not dst:
      session.close()
      return jsonify({'success': False, 'message': 'Kaynak veya hedef hesap bulunamadı'}), 404

    _apply_balance(src, -amount)
    _apply_balance(dst, amount)

    tx = Transaction(
      account_id=src.id,
      related_account=dst.id,
      type='TRANSFER',
      source='TRANSFER',
      amount=amount,
      description=data.get('description'),
      created_by=data.get('created_by'),
    )
    session.add(tx)
    session.commit()
    session.refresh(tx)
    result = _json_transaction(tx)
    session.close()
    return jsonify({
      'success': True,
      'transaction': result,
      'source_account': _json_account(src),
      'target_account': _json_account(dst)
    }), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/transactions/<int:tx_id>', methods=['DELETE'])
def cancel_transaction(tx_id):
  session = SessionLocal()
  try:
    tx = session.query(Transaction).filter(Transaction.id == tx_id).with_for_update().first()
    if not tx:
      session.close()
      return jsonify({'success': False, 'message': 'İşlem bulunamadı'}), 404
    if tx.is_canceled:
      session.close()
      return jsonify({'success': False, 'message': 'İşlem zaten iptal'}), 400

    acc = session.query(Account).filter(Account.id == tx.account_id).with_for_update().first()
    if not acc:
      session.close()
      return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404

    if tx.type == 'INCOME':
      _apply_balance(acc, -tx.amount)
    elif tx.type == 'EXPENSE':
      _apply_balance(acc, tx.amount)
    elif tx.type == 'TRANSFER':
      src = acc
      dst = session.query(Account).filter(Account.id == tx.related_account).with_for_update().first()
      if not dst:
        session.close()
        return jsonify({'success': False, 'message': 'Transfer hedef hesabı bulunamadı'}), 404
      _apply_balance(src, tx.amount)
      _apply_balance(dst, -tx.amount)
    else:
      session.close()
      return jsonify({'success': False, 'message': 'Bilinmeyen işlem tipi'}), 400

    tx.is_canceled = True
    session.commit()
    result = _json_transaction(tx)
    session.close()
    return jsonify({'success': True, 'transaction': result})
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400

# RENTS API
@app.route('/api/rents', methods=['GET'])
def list_rents():
  session = SessionLocal()
  try:
    rents = session.query(Rent).all()
    result = []
    for rent in rents:
      result.append({
        'id': rent.id,
        'owner_id': rent.owner_id,
        'owner_name': rent.owner.full_name if rent.owner else None,
        'month': rent.month,
        'year': rent.year,
        'amount': float(rent.amount) if rent.amount else 0,
        'due_date': rent.due_date.isoformat() if rent.due_date else None,
        'status': rent.status,
        'late_fee': float(rent.late_fee) if rent.late_fee else 0,
        'category_id': rent.category_id,
        'description': rent.description,
        'created_at': rent.created_at.isoformat() if rent.created_at else None,
        'updated_at': rent.updated_at.isoformat() if rent.updated_at else None,
      })
    return jsonify({'rents': result})
  except Exception as e:
    print(f"Rents error: {e}")
    return jsonify({'rents': []}), 500
  finally:
    session.close()


@app.route('/api/rents', methods=['POST'])
def create_rent():
  data = request.json or {}
  owner_id = data.get('user_id') or data.get('owner_id')
  month = data.get('month')
  year = data.get('year')
  amount = _to_decimal(data.get('amount'))
  
  if not owner_id or not month or not year or amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'user_id, month, year ve pozitif amount gerekli'}), 400
  
  session = SessionLocal()
  try:
    owner = session.query(Owner).filter(Owner.id == owner_id, Owner.is_active == True).first()
    if not owner:
      session.close()
      return jsonify({'success': False, 'message': 'Malik bulunamadı'}), 404
    
    existing = session.query(Rent).filter(
      Rent.owner_id == owner_id, Rent.month == month, Rent.year == year
    ).first()
    if existing:
      session.close()
      return jsonify({'success': False, 'message': 'Bu dönem için aidat zaten var'}), 409
    
    due_date = None
    if data.get('due_date'):
      try:
        due_date = datetime.fromisoformat(data.get('due_date').replace('Z', '+00:00'))
      except ValueError:
        pass
    
    rent = Rent(
      owner_id=owner_id,
      month=month,
      year=year,
      amount=amount,
      due_date=due_date,
      status='UNPAID',
      late_fee=Decimal('0'),
      description=data.get('description'),
    )
    session.add(rent)
    session.commit()
    session.refresh(rent)
    
    result = {
      'id': rent.id,
      'owner_id': rent.owner_id,
      'owner_name': owner.full_name,
      'month': rent.month,
      'year': rent.year,
      'amount': float(rent.amount or 0),
      'due_date': rent.due_date.isoformat() if rent.due_date else None,
      'status': rent.status or 'UNPAID',
      'late_fee': float(rent.late_fee or 0) if rent.late_fee else None,
      'category_id': rent.category_id,
      'description': rent.description,
      'created_at': rent.created_at.isoformat() if rent.created_at else None,
      'updated_at': rent.updated_at.isoformat() if rent.updated_at else None,
    }
    session.close()
    return jsonify({'success': True, 'rent': result}), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/rents/bulk', methods=['POST'])
def bulk_create_rent():
  data = request.json or {}
  month = data.get('month')
  year = data.get('year')
  amount = _to_decimal(data.get('amount'))
  
  if not month or not year or amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'month, year ve pozitif amount gerekli'}), 400
  
  session = SessionLocal()
  try:
    owners = session.query(Owner).filter(Owner.is_active == True).all()
    created_count = 0
    skipped_count = 0
    
    due_date = None
    if data.get('due_date'):
      try:
        due_date = datetime.fromisoformat(data.get('due_date').replace('Z', '+00:00'))
      except ValueError:
        pass
    
    for owner in owners:
      existing = session.query(Rent).filter(
        Rent.owner_id == owner.id, Rent.month == month, Rent.year == year
      ).first()
      if existing:
        skipped_count += 1
        continue
      
      rent = Rent(
        owner_id=owner.id,
        month=month,
        year=year,
        amount=amount,
        due_date=due_date,
        status='UNPAID',
        late_fee=Decimal('0'),
      )
      session.add(rent)
      created_count += 1
    
    session.commit()
    session.close()
    return jsonify({
      'success': True,
      'message': f'{created_count} aidat oluşturuldu, {skipped_count} atlandı',
      'created': created_count,
      'skipped': skipped_count,
    }), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/rents/<int:rent_id>', methods=['PUT'])
def update_rent(rent_id):
  data = request.json or {}
  session = SessionLocal()
  try:
    rent = session.query(Rent).filter(Rent.id == rent_id).with_for_update().first()
    if not rent:
      session.close()
      return jsonify({'success': False, 'message': 'Aidat bulunamadı'}), 404
    
    if rent.status == 'PAID':
      session.close()
      return jsonify({'success': False, 'message': 'Ödenmiş aidat düzenlenemez'}), 400
    
    if data.get('amount') is not None:
      rent.amount = _to_decimal(data.get('amount'))
    if data.get('due_date') is not None:
      try:
        rent.due_date = datetime.fromisoformat(data.get('due_date').replace('Z', '+00:00'))
      except ValueError:
        pass
    if data.get('description') is not None:
      rent.description = data.get('description')
    
    rent.updated_at = datetime.utcnow()
    session.commit()
    session.refresh(rent)
    
    owner = session.query(Owner).filter(Owner.id == rent.owner_id).first()
    result = {
      'id': rent.id,
      'owner_id': rent.owner_id,
      'owner_name': owner.full_name if owner else None,
      'month': rent.month,
      'year': rent.year,
      'amount': float(rent.amount or 0),
      'due_date': rent.due_date.isoformat() if rent.due_date else None,
      'status': rent.status or 'UNPAID',
      'late_fee': float(rent.late_fee or 0) if rent.late_fee else None,
      'category_id': rent.category_id,
      'description': rent.description,
      'created_at': rent.created_at.isoformat() if rent.created_at else None,
      'updated_at': rent.updated_at.isoformat() if rent.updated_at else None,
    }
    session.close()
    return jsonify({'success': True, 'rent': result})
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/rents/<int:rent_id>', methods=['DELETE'])
def delete_rent(rent_id):
  session = SessionLocal()
  try:
    rent = session.query(Rent).filter(Rent.id == rent_id).first()
    if not rent:
      session.close()
      return jsonify({'success': False, 'message': 'Aidat bulunamadı'}), 404
    
    if rent.status == 'PAID':
      session.close()
      return jsonify({'success': False, 'message': 'Ödenmiş aidat silinemez'}), 400
    
    session.delete(rent)
    session.commit()
    session.close()
    return jsonify({'success': True, 'message': 'Aidat silindi'})
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


# PAYMENTS API
@app.route('/api/payments', methods=['GET'])
def list_payments():
  session = SessionLocal()
  try:
    payments = session.query(Payment).all()
    result = []
    for payment in payments:
      result.append({
        'id': payment.id,
        'rent_id': payment.rent_id,
        'owner_id': payment.owner_id,
        'account_id': payment.account_id,
        'amount': float(payment.amount) if payment.amount else 0,
        'late_fee_amount': float(payment.late_fee_amount) if payment.late_fee_amount else 0,
        'payment_date': payment.payment_date.isoformat() if payment.payment_date else None,
        'reference_number': payment.reference_number,
        'is_cancelled': payment.is_cancelled,
        'cancellation_date': payment.cancellation_date.isoformat() if payment.cancellation_date else None,
        'cancellation_reason': payment.cancellation_reason,
        'created_at': payment.created_at.isoformat() if payment.created_at else None,
        'updated_at': payment.updated_at.isoformat() if payment.updated_at else None,
      })
    return jsonify({'payments': result})
  except Exception as e:
    print(f"Payments error: {e}")
    return jsonify({'payments': []}), 500
  finally:
    session.close()


@app.route('/api/payments', methods=['POST'])
def create_payment():
  data = request.json or {}
  rent_id = data.get('rent_id')
  account_id = data.get('account_id')
  amount = _to_decimal(data.get('amount'))
  late_fee_amount = _to_decimal(data.get('late_fee_amount') or 0)
  
  if not rent_id or not account_id or amount is None or amount <= 0:
    return jsonify({'success': False, 'message': 'rent_id, account_id ve pozitif amount gerekli'}), 400
  
  session = SessionLocal()
  try:
    rent = session.query(Rent).filter(Rent.id == rent_id).with_for_update().first()
    account = session.query(Account).filter(Account.id == account_id, Account.is_active == True).with_for_update().first()
    
    if not rent:
      session.close()
      return jsonify({'success': False, 'message': 'Aidat bulunamadı'}), 404
    if not account:
      session.close()
      return jsonify({'success': False, 'message': 'Hesap bulunamadı'}), 404
    
    total = amount + (late_fee_amount or Decimal('0'))
    _apply_balance(account, total)
    
    payment_date = None
    if data.get('payment_date'):
      try:
        payment_date = datetime.fromisoformat(data.get('payment_date').replace('Z', '+00:00'))
      except ValueError:
        payment_date = datetime.utcnow()
    else:
      payment_date = datetime.utcnow()
    
    payment = Payment(
      rent_id=rent_id,
      owner_id=rent.owner_id,
      account_id=account_id,
      amount=amount,
      late_fee_amount=late_fee_amount,
      payment_date=payment_date,
      reference_number=data.get('reference_number'),
      is_cancelled=False,
    )
    session.add(payment)
    session.flush()
    
    rent.status = 'PAID'
    rent.updated_at = datetime.utcnow()
    
    tx = Transaction(
      account_id=account_id,
      type='INCOME',
      source='RENT',
      related_id=rent_id,
      amount=total,
      description=f'Aidat - {rent.month}/{rent.year}',
    )
    session.add(tx)
    session.commit()
    session.refresh(payment)
    session.refresh(account)
    
    owner = session.query(Owner).filter(Owner.id == rent.owner_id).first()
    result = {
      'id': payment.id,
      'rent_id': payment.rent_id,
      'owner_id': payment.owner_id,
      'owner_name': owner.full_name if owner else None,
      'account_id': payment.account_id,
      'account_name': account.name,
      'amount': float(payment.amount or 0),
      'late_fee_amount': float(payment.late_fee_amount or 0) if payment.late_fee_amount else None,
      'total_amount': float(total),
      'payment_date': payment.payment_date.isoformat() if payment.payment_date else None,
      'reference_number': payment.reference_number,
      'is_cancelled': payment.is_cancelled,
      'created_at': payment.created_at.isoformat() if payment.created_at else None,
    }
    session.close()
    return jsonify({'success': True, 'payment': result, 'account': _json_account(account)}), 201
  except Exception as e:
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/payments/<int:payment_id>/cancel', methods=['PUT'])
def cancel_payment(payment_id):
  data = request.json or {}
  print(f'[CANCEL_PAYMENT] Payment ID: {payment_id}, Data: {data}')
  session = SessionLocal()
  try:
    payment = session.query(Payment).filter(Payment.id == payment_id).with_for_update().first()
    print(f'[CANCEL_PAYMENT] Found payment: {payment}')
    if not payment:
      session.close()
      return jsonify({'success': False, 'message': 'Ödeme bulunamadı'}), 404
    
    if payment.is_cancelled:
      session.close()
      return jsonify({'success': False, 'message': 'Ödeme zaten iptal'}), 400
    
    account = session.query(Account).filter(Account.id == payment.account_id).with_for_update().first()
    rent = session.query(Rent).filter(Rent.id == payment.rent_id).with_for_update().first()
    
    if not account or not rent:
      session.close()
      return jsonify({'success': False, 'message': 'İlişkili veri bulunamadı'}), 404
    
    total = _to_decimal(payment.amount or 0) + _to_decimal(payment.late_fee_amount or 0)
    _apply_balance(account, -total)
    
    payment.is_cancelled = True
    payment.cancellation_date = datetime.utcnow()
    payment.cancellation_reason = data.get('cancellation_reason')
    
    rent.status = 'UNPAID'
    rent.updated_at = datetime.utcnow()
    
    tx = session.query(Transaction).filter(
      Transaction.source == 'RENT', Transaction.related_id == rent.id, Transaction.is_canceled == False
    ).with_for_update().first()
    if tx:
      tx.is_canceled = True
    
    session.commit()
    session.refresh(payment)
    session.refresh(account)
    
    owner = session.query(Owner).filter(Owner.id == payment.owner_id).first()
    result = {
      'id': payment.id,
      'rent_id': payment.rent_id,
      'owner_id': payment.owner_id,
      'owner_name': owner.full_name if owner else None,
      'account_id': payment.account_id,
      'account_name': account.name,
      'amount': float(payment.amount or 0),
      'late_fee_amount': float(payment.late_fee_amount or 0) if payment.late_fee_amount else None,
      'total_amount': float(total),
      'payment_date': payment.payment_date.isoformat() if payment.payment_date else None,
      'reference_number': payment.reference_number,
      'is_cancelled': payment.is_cancelled,
      'cancellation_date': payment.cancellation_date.isoformat() if payment.cancellation_date else None,
      'cancellation_reason': payment.cancellation_reason,
      'created_at': payment.created_at.isoformat() if payment.created_at else None,
    }
    session.close()
    return jsonify({'success': True, 'payment': result, 'account': _json_account(account)})
  except Exception as e:
    print(f'[CANCEL_PAYMENT] ERROR: {str(e)}')
    session.rollback()
    session.close()
    return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/health', methods=['GET'])
def health():
  return jsonify({'status': 'ok'})

# SETTINGS API
@app.route('/api/settings', methods=['GET'])
def get_settings():
  session = SessionLocal()
  settings = session.query(Settings).first()
  session.close()
  
  if not settings:
    return jsonify({
      'id': None,
      'site_name': '',
      'site_address': '',
      'city': '',
      'tax_number': '',
      'tax_office': '',
      'smtp_server': '',
      'smtp_port': None,
      'mail_address': '',
      'smtp_password': '',
      'rent_due_day': 1,
      'admin_pays_rent': False,
      'apply_late_fee': False,
      'late_fee_rate': 0.0,
    }), 200
  
  return jsonify({
    'id': settings.id,
    'site_name': settings.site_name,
    'site_address': settings.site_address,
    'city': settings.city,
    'tax_number': settings.tax_number,
    'tax_office': settings.tax_office,
    'smtp_server': settings.smtp_server,
    'smtp_port': settings.smtp_port,
    'mail_address': settings.mail_address,
    'smtp_password': settings.smtp_password,
    'rent_due_day': settings.rent_due_day,
    'admin_pays_rent': settings.admin_pays_rent,
    'apply_late_fee': settings.apply_late_fee,
    'late_fee_rate': settings.late_fee_rate,
  }), 200

@app.route('/api/settings', methods=['POST', 'PUT'])
def save_settings():
  data = request.json or {}
  session = SessionLocal()
  
  settings = session.query(Settings).first()
  if not settings:
    settings = Settings()
    session.add(settings)
  
  settings.site_name = data.get('site_name')
  settings.site_address = data.get('site_address')
  settings.city = data.get('city')
  settings.tax_number = data.get('tax_number')
  settings.tax_office = data.get('tax_office')
  settings.smtp_server = data.get('smtp_server')
  settings.smtp_port = data.get('smtp_port')
  settings.mail_address = data.get('mail_address')
  settings.smtp_password = data.get('smtp_password')
  settings.rent_due_day = data.get('rent_due_day', 1)
  settings.admin_pays_rent = data.get('admin_pays_rent', False)
  settings.apply_late_fee = data.get('apply_late_fee', False)
  settings.late_fee_rate = data.get('late_fee_rate', 0.0)
  
  session.commit()
  session.close()
  
  return jsonify({'success': True, 'message': 'Ayarlar kaydedildi'}), 200

# CATEGORIES API
@app.route('/api/categories', methods=['GET'])
def get_categories():
  session = SessionLocal()
  categories = session.query(Category).filter_by(is_active=True).all()
  session.close()
  
  result = []
  for cat in categories:
    result.append({
      'id': cat.id,
      'name': cat.name,
      'category_type': cat.category_type,
    })
  
  return jsonify(result), 200

@app.route('/api/categories', methods=['POST'])
def create_category():
  data = request.json or {}
  name = data.get('name')
  category_type = data.get('category_type')
  
  if not name or not category_type:
    return jsonify({'success': False, 'message': 'Kategori adı ve tipi gerekli'}), 400
  
  session = SessionLocal()
  category = Category(name=name, category_type=category_type)
  session.add(category)
  session.commit()
  
  result = {
    'id': category.id,
    'name': category.name,
    'category_type': category.category_type,
  }
  session.close()
  
  return jsonify(result), 201

@app.route('/api/categories/<int:category_id>', methods=['DELETE'])
def delete_category(category_id):
  session = SessionLocal()
  category = session.query(Category).filter_by(id=category_id).first()
  
  if not category:
    session.close()
    return jsonify({'success': False, 'message': 'Kategori bulunamadı'}), 404
  
  category.is_active = False
  session.commit()
  session.close()
  
  return jsonify({'success': True, 'message': 'Kategori silindi'}), 200

@app.route('/api/backup/list', methods=['GET'])
def list_backups():
  """Yedekleme klasöründeki tüm yedekleri listele"""
  try:
    backup_dir = 'backups'
    
    # Backups klasörü yoksa oluştur
    if not os.path.exists(backup_dir):
      os.makedirs(backup_dir)
      return jsonify({'success': True, 'backups': []})
    
    # Klasördeki tüm .db dosyalarını listele
    backup_files = []
    for filename in os.listdir(backup_dir):
      if filename.endswith('.db'):
        filepath = os.path.join(backup_dir, filename)
        file_size = os.path.getsize(filepath)
        file_time = os.path.getmtime(filepath)
        
        backup_files.append({
          'filename': filename,
          'size': file_size,
          'size_mb': round(file_size / (1024 * 1024), 2),
          'created_at': datetime.fromtimestamp(file_time).strftime('%Y-%m-%d %H:%M:%S')
        })
    
    # Tarihe göre sıralı (en yeni ilk)
    backup_files.sort(key=lambda x: x['created_at'], reverse=True)
    
    return jsonify({'success': True, 'backups': backup_files})
    
  except Exception as e:
    return jsonify({'success': False, 'message': f'Yedekleme listesi hatası: {str(e)}'}), 500

@app.route('/api/backup/create', methods=['POST'])
def create_backup():
  """Yedek dosyası oluştur"""
  try:
    db_path = 'database.db'
    
    # Veritabanı dosyası var mı kontrol et
    if not os.path.exists(db_path):
      return jsonify({'success': False, 'message': 'Veritabanı dosyası bulunamadı'}), 404
    
    # Backups klasörü yoksa oluştur
    backup_dir = 'backups'
    if not os.path.exists(backup_dir):
      os.makedirs(backup_dir)
    
    # Tarih damgalı yedek dosyası adı oluştur
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f'ays_backup_{timestamp}.db'
    backup_path = os.path.join(backup_dir, backup_filename)
    
    # Veritabanını kopyala
    shutil.copy2(db_path, backup_path)
    
    file_size = os.path.getsize(backup_path)
    
    return jsonify({
      'success': True, 
      'message': f'Yedek başarıyla oluşturuldu: {backup_filename}',
      'backup': {
        'filename': backup_filename,
        'size': file_size,
        'size_mb': round(file_size / (1024 * 1024), 2),
        'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
      }
    })
    
  except Exception as e:
    return jsonify({'success': False, 'message': f'Yedekleme hatası: {str(e)}'}), 500

@app.route('/api/backup/download', methods=['GET'])
def backup_database():
  """SQLite veritabanının yedeğini indir"""
  try:
    db_path = 'database.db'
    
    # Veritabanı dosyası var mı kontrol et
    if not os.path.exists(db_path):
      return jsonify({'success': False, 'message': 'Veritabanı dosyası bulunamadı'}), 404
    
    # Tarih damgalı yedek dosyası adı oluştur
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f'ays_backup_{timestamp}.db'
    backup_path = f'backup_{timestamp}.db'
    
    # Veritabanını kopyala
    shutil.copy2(db_path, backup_path)
    
    # Dosyayı gönder ve sonra sil
    response = send_file(
      backup_path,
      as_attachment=True,
      download_name=backup_filename,
      mimetype='application/octet-stream'
    )
    
    # Dosya gönderildikten sonra temizlik yapılacak
    @response.call_on_close
    def cleanup():
      try:
        if os.path.exists(backup_path):
          os.remove(backup_path)
      except:
        pass
    
    return response
    
  except Exception as e:
    return jsonify({'success': False, 'message': f'Yedekleme hatası: {str(e)}'}), 500


# ==================== WEBSOCKET EVENTS ====================
# WebSocket desteği şu anda devre dışı (gelecekte yapılacak)
# @socketio.on('connect')
# def handle_connect():
#   print(f'Client connected')
#   emit('connection_response', {'data': 'Connected to server'})

# @socketio.on('disconnect')
# def handle_disconnect():
#   print(f'Client disconnected')

# def broadcast_data_update(event_type, data):
#   socketio.emit('data_update', {
#     'event': event_type,
#     'data': data,
#     'timestamp': datetime.utcnow().isoformat()
#   }, broadcast=True)

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=5000, debug=False)

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=5000)
