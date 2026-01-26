from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, Enum as SqlEnum
from sqlalchemy.orm import relationship
from .database import Base
import datetime
import enum

class UserRole(str, enum.Enum):
    ORG_ADMIN = "ORG_ADMIN"
    DATA_COLLECTOR = "DATA_COLLECTOR"

class DataType(str, enum.Enum):
    RAIN_GAUGE = "RAIN_GAUGE"
    DISCHARGE = "DISCHARGE"
    OTHER = "OTHER"

class Organization(Base):
    __tablename__ = "organizations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    code = Column(String, unique=True)
    contact_info = Column(String, nullable=True)

    users = relationship("User", back_populates="organization")
    stations = relationship("Station", back_populates="organization")
    imports = relationship("ImportLog", back_populates="organization")

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    org_id = Column(Integer, ForeignKey("organizations.id"))
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String)
    role = Column(SqlEnum(UserRole), default=UserRole.DATA_COLLECTOR)
    is_active = Column(Boolean, default=True)

    organization = relationship("Organization", back_populates="users")
    data_records = relationship("DataRecord", back_populates="user")
    
    # Many-to-Many relationship for assigned stations could be added here
    # For now, we can assume Org Admin sees all, DC sees assigned (needs association table)

class Station(Base):
    __tablename__ = "stations"

    id = Column(Integer, primary_key=True, index=True)
    org_id = Column(Integer, ForeignKey("organizations.id"))
    name = Column(String, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    type = Column(SqlEnum(DataType), default=DataType.OTHER)
    
    organization = relationship("Organization", back_populates="stations")
    parameters = relationship("Parameter", back_populates="station")
    data_records = relationship("DataRecord", back_populates="station")

class Parameter(Base):
    __tablename__ = "parameters"

    id = Column(Integer, primary_key=True, index=True)
    station_id = Column(Integer, ForeignKey("stations.id"))
    name = Column(String) # e.g. "Rainfall", "Water Level"
    unit = Column(String) # e.g. "mm", "m"
    min_val = Column(Float, nullable=True)
    max_val = Column(Float, nullable=True)

    station = relationship("Station", back_populates="parameters")
    data_records = relationship("DataRecord", back_populates="parameter")

class DataRecord(Base):
    __tablename__ = "data_records"

    id = Column(Integer, primary_key=True, index=True)
    station_id = Column(Integer, ForeignKey("stations.id"))
    parameter_id = Column(Integer, ForeignKey("parameters.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Nullable if imported by system/bulk
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, index=True)
    value = Column(Float)
    is_verified = Column(Boolean, default=False)
    
    station = relationship("Station", back_populates="data_records")
    parameter = relationship("Parameter", back_populates="data_records")
    user = relationship("User", back_populates="data_records")

class ImportLog(Base):
    __tablename__ = "imports"

    id = Column(Integer, primary_key=True, index=True)
    org_id = Column(Integer, ForeignKey("organizations.id"))
    filename = Column(String)
    status = Column(String) # PENDING, COMPLETED, FAILED
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    organization = relationship("Organization", back_populates="imports")
