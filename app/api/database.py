import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

POSTGRES_USER = os.getenv('POSTGRES_USER', 'postgres')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'postgres')
SISTEMAS_HOST = os.getenv('SISTEMAS_HOST', 'localhost')
SISTEMAS_PORT = os.getenv('SISTEMAS_PORT', '5454')

URL_ADMIN = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{SISTEMAS_HOST}:{SISTEMAS_PORT}/db_admin"
URL_MOTORISTAS = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{SISTEMAS_HOST}:{SISTEMAS_PORT}/db_motoristas"

engine_admin = create_engine(URL_ADMIN)
engine_motoristas = create_engine(URL_MOTORISTAS)

SessionAdmin = sessionmaker(autocommit=False, autoflush=False, bind=engine_admin)
SessionMotoristas = sessionmaker(autocommit=False, autoflush=False, bind=engine_motoristas)

def get_db_admin():
    db = SessionAdmin()
    try:
        yield db
    finally:
        db.close()

def get_db_motoristas():
    db = SessionMotoristas()
    try:
        yield db
    finally:
        db.close()
