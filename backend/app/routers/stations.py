from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import crud, models, schemas, database, auth

router = APIRouter()

@router.get("/stations/", response_model=List[schemas.Station])
def read_stations(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    # In a real app, filter by User's Org or Assigned Stations
    return crud.get_stations(db, skip=skip, limit=limit)

@router.post("/stations/", response_model=schemas.Station)
def create_station(station: schemas.StationCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    if current_user.role != models.UserRole.ORG_ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized")
    return crud.create_station(db=db, station=station)

@router.post("/stations/{station_id}/parameters/", response_model=schemas.Parameter)
def create_parameter_for_station(
    station_id: int, parameter: schemas.ParameterBase, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_active_user)
):
    if current_user.role != models.UserRole.ORG_ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Check if station exists
    station = db.query(models.Station).filter(models.Station.id == station_id).first()
    if not station:
         raise HTTPException(status_code=404, detail="Station not found")
         
    db_param = models.Parameter(**parameter.dict(), station_id=station_id)
    db.add(db_param)
    db.commit()
    db.refresh(db_param)
    return db_param
