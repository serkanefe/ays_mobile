# -*- coding: utf-8 -*-
import os
from datetime import datetime
from sqlalchemy import (
  create_engine,
  Column,
  Integer,
  String,
  Float,
  DateTime,
  Boolean,
  ForeignKey,
  Numeric,
  Text,
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from werkzeug.security import generate_password_hash

# SQLite - PythonAnywhere uyumlu
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'ays.db')}"
engine = create_engine(
  DATABASE_URL,
  connect_args={"check_same_thread": False},
  echo=False,
)

SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


class Owner(Base):
  __tablename__ = "owners"
  id = Column(Integer, primary_key=True)
  full_name = Column(String(255), nullable=False)
  email = Column(String(255), nullable=False)
  password = Column(String(255), nullable=False)
  phone = Column(String(50))
  identity_number = Column(String(50))  # TC
  unit_name = Column(String(100))  # Daire No
  unit_type = Column(String(50), default="Mesken")  # Mesken / İşyeri
  share_ratio = Column(Float)
  owner_type = Column(String(20), default="PERSON")  # PERSON / COMPANY
  role = Column(String(50), default="Malik")  # Yönetici, Yönetici Yardımcısı, Denetci, Malik
  tenant_name = Column(String(255))
  tenant_email = Column(String(255))
  is_active = Column(Boolean, default=True)
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
  rents = relationship("Rent", back_populates="owner", cascade="all, delete-orphan")
  payments = relationship("Payment", back_populates="owner", cascade="all, delete-orphan")


class Rent(Base):
  __tablename__ = "rents"
  id = Column(Integer, primary_key=True)
  owner_id = Column(Integer, ForeignKey("owners.id"), nullable=False)
  month = Column(Integer, nullable=False)  # 1-12
  year = Column(Integer, nullable=False)
  amount = Column(Float, default=0)
  due_date = Column(DateTime)
  status = Column(String(50), default='UNPAID')  # UNPAID, PAID
  late_fee = Column(Float, default=0)
  category_id = Column(Integer, ForeignKey("categories.id"))
  description = Column(String(500))
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
  owner = relationship("Owner", back_populates="rents")


class Payment(Base):
  __tablename__ = "payments"
  id = Column(Integer, primary_key=True)
  rent_id = Column(Integer, ForeignKey("rents.id"), nullable=False)
  owner_id = Column(Integer, ForeignKey("owners.id"), nullable=False)
  account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
  amount = Column(Float, default=0)
  late_fee_amount = Column(Float, default=0)
  payment_date = Column(DateTime, default=datetime.utcnow)
  reference_number = Column(String(100))
  is_cancelled = Column(Boolean, default=False)
  cancellation_date = Column(DateTime)
  cancellation_reason = Column(String(500))
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
  owner = relationship("Owner", back_populates="payments")
  rent = relationship("Rent", backref="payments")
  account = relationship("Account", backref="payments")


class Settings(Base):
  __tablename__ = "settings"
  id = Column(Integer, primary_key=True)
  site_name = Column(String(255))
  site_address = Column(String(500))
  city = Column(String(100))
  tax_number = Column(String(50))
  tax_office = Column(String(100))
  
  # Mail ayarları
  smtp_server = Column(String(255))
  smtp_port = Column(Integer)
  mail_address = Column(String(255))
  smtp_password = Column(String(255))
  
  # Aidat ayarları
  rent_due_day = Column(Integer, default=1)  # 1-31
  admin_pays_rent = Column(Boolean, default=False)
  apply_late_fee = Column(Boolean, default=False)
  late_fee_rate = Column(Float, default=0.0)
  
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Category(Base):
  __tablename__ = "categories"
  id = Column(Integer, primary_key=True)
  name = Column(String(255), nullable=False)
  category_type = Column(String(50), nullable=False)  # INCOME / EXPENSE
  is_active = Column(Boolean, default=True)
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Expense(Base):
  __tablename__ = "expenses"

  id = Column(Integer, primary_key=True)
  name = Column(String(255), nullable=False)
  category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
  account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
  amount = Column(Numeric(14, 2), nullable=False, default=0)
  payee = Column(String(255))
  receipt_no = Column(String(100))
  expense_date = Column(DateTime)
  maintenance_agreement_id = Column(Integer, nullable=True)
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

  category = relationship("Category")
  account = relationship("Account")


class Account(Base):
  __tablename__ = "accounts"

  id = Column(Integer, primary_key=True)
  name = Column(String(100), nullable=False)
  type = Column(String(10), nullable=False)  # CASH / BANK
  balance = Column(Numeric(14, 2), nullable=False, default=0)
  is_active = Column(Boolean, default=True)
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

  # Relationships
  transactions = relationship("Transaction", back_populates="account", foreign_keys="Transaction.account_id")
  related_transactions = relationship(
    "Transaction",
    back_populates="related_account_obj",
    foreign_keys="Transaction.related_account",
  )


class Transaction(Base):
  __tablename__ = "transactions"

  id = Column(Integer, primary_key=True)
  account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
  related_account = Column(Integer, ForeignKey("accounts.id"), nullable=True)
  type = Column(String(15), nullable=False)  # INCOME / EXPENSE / TRANSFER
  source = Column(String(20), nullable=True)  # RENT / EXPENSE / MANUAL / TRANSFER
  related_id = Column(Integer, nullable=True)  # rent_id / expense_id / etc
  amount = Column(Numeric(14, 2), nullable=False)
  description = Column(Text, nullable=True)
  is_canceled = Column(Boolean, default=False)
  created_by = Column(Integer, nullable=True)
  created_at = Column(DateTime, default=datetime.utcnow)

  account = relationship("Account", foreign_keys=[account_id], back_populates="transactions")
  related_account_obj = relationship("Account", foreign_keys=[related_account], back_populates="related_transactions")


def init_db():
  Base.metadata.create_all(engine)
