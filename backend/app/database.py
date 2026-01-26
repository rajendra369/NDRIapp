from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Use environment variable for DB URL or default to local Postgres
# For development, we can default to a standard local URL
# Use environment variable for DB URL or default to SQLite for local dev
# since Postgres is not detected on the host machine.
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./meteo.db")

if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
