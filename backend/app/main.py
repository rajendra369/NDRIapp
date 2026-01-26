from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, database

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="Meteorological Data System API",
    description="API for collecting and managing meteorological and hydrological data",
    version="1.0.0"
)

# Configure CORS
origins = [
    "http://localhost",
    "http://localhost:3000", # Next.js
    "http://localhost:8000", 
    "*" # For mobile app development (refine in production)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from .routers import auth, stations, data

# ... existing code ...

app.include_router(auth.router, tags=["auth"])
app.include_router(stations.router, tags=["stations"])
app.include_router(data.router, tags=["data"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the Meteorological Data System API"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
