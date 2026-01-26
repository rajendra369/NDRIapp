from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from .models import UserRole, DataType

class OrganizationBase(BaseModel):
    name: str
    code: str
    contact_info: Optional[str] = None

class OrganizationCreate(OrganizationBase):
    pass

class Organization(OrganizationBase):
    id: int
    
    class Config:
        from_attributes = True

class UserBase(BaseModel):
    username: str
    email: Optional[str] = None
    role: UserRole = UserRole.DATA_COLLECTOR

class UserCreate(UserBase):
    password: str
    org_id: int

class User(UserBase):
    id: int
    is_active: bool
    org_id: int

    class Config:
        from_attributes = True

class StationBase(BaseModel):
    name: str
    latitude: float
    longitude: float
    type: DataType

class StationCreate(StationBase):
    org_id: int

class Station(StationBase):
    id: int
    org_id: int

    class Config:
        from_attributes = True

class ParameterBase(BaseModel):
    name: str
    unit: str
    min_val: Optional[float] = None
    max_val: Optional[float] = None

class ParameterCreate(ParameterBase):
    station_id: int

class Parameter(ParameterBase):
    id: int
    station_id: int

    class Config:
        from_attributes = True

class DataRecordBase(BaseModel):
    timestamp: datetime
    value: float

class DataRecordCreate(DataRecordBase):
    station_id: int
    parameter_id: int
    # user_id is handled by auth

class DataRecord(DataRecordBase):
    id: int
    station_id: int
    parameter_id: int
    user_id: Optional[int]
    is_verified: bool

    class Config:
        from_attributes = True
