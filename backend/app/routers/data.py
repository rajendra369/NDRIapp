from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from datetime import datetime
import pandas as pd
import io
from .. import crud, models, schemas, database, auth

router = APIRouter()

@router.post("/data/", response_model=schemas.DataRecord)
def create_data_record(record: schemas.DataRecordCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    # Verify user is assigned to this station (logic omitted for brevity, assume check matches org)
    return crud.create_data_record(db=db, record=record, user_id=current_user.id)

@router.post("/data/import")
async def import_data(
    file: UploadFile = File(...),
    resolution: str = Form("dry_run"), # dry_run, replace, skip
    org_id: int = Form(...),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    if current_user.role != models.UserRole.ORG_ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized")

    contents = await file.read()
    if file.filename.endswith('.csv'):
        df = pd.read_csv(io.StringIO(contents.decode('utf-8')))
    elif file.filename.endswith(('.xls', '.xlsx')):
        df = pd.read_excel(io.BytesIO(contents))
    else:
         raise HTTPException(status_code=400, detail="Invalid file format")

    # Expected columns: station_name, parameter_name, timestamp, value
    # Validation logic here (omitted for brevity)
    
    conflicts = []
    new_records = []
    
    for index, row in df.iterrows():
        # Find Station
        station = db.query(models.Station).filter(models.Station.name == row['station_name'], models.Station.org_id == org_id).first()
        if not station:
            continue # Or error
            
        # Find Parameter
        param = db.query(models.Parameter).filter(models.Parameter.name == row['parameter_name'], models.Parameter.station_id == station.id).first()
        if not param:
            continue
            
        timestamp = pd.to_datetime(row['timestamp'])
        val = float(row['value'])
        
        # Check existing
        existing = db.query(models.DataRecord).filter(
            models.DataRecord.station_id == station.id,
            models.DataRecord.parameter_id == param.id,
            models.DataRecord.timestamp == timestamp
        ).first()
        
        if existing:
            conflicts.append({
                "row_index": index,
                "station": station.name,
                "parameter": param.name,
                "timestamp": str(timestamp),
                "existing_value": existing.value,
                "new_value": val,
                "station_id": station.id,
                "parameter_id": param.id,
                "record_id": existing.id
            })
        else:
            new_records.append({
                "station_id": station.id,
                "parameter_id": param.id,
                "timestamp": timestamp,
                "value": val,
                "user_id": current_user.id
            })

    if resolution == "dry_run":
        return {"status": "preview", "conflicts": conflicts, "new_records_count": len(new_records)}
    
    inserted_count = 0
    updated_count = 0
    
    if resolution == "replace":
        # Handle conflicts: Update logic
        for conf in conflicts:
            rec = db.query(models.DataRecord).filter(models.DataRecord.id == conf['record_id']).first()
            rec.value = conf['new_value']
            updated_count += 1
        
        # Insert new
        for new_rec in new_records:
            db_rec = models.DataRecord(**new_rec, is_verified=True)
            db.add(db_rec)
            inserted_count += 1
            
    elif resolution == "skip":
        # Ignore conflicts, just insert new
        for new_rec in new_records:
            db_rec = models.DataRecord(**new_rec, is_verified=True)
            db.add(db_rec)
            inserted_count += 1
            
    db.commit()
    
    # Log import
    import_log = models.ImportLog(org_id=org_id, filename=file.filename, status="COMPLETED")
    db.add(import_log)
    db.commit()

    return {"status": "success", "inserted": inserted_count, "updated": updated_count}
