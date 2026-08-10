from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from schemas import UserLocationRequest, NearbyPOIResponse
from services.geo_service import GeoScoringEngine
from database import get_db

router = APIRouter(prefix="/api/v1/location", tags=["Location & Geo-Guide"])


@router.post("/nearby", response_model=NearbyPOIResponse)
def get_nearby_poi(
    location_data: UserLocationRequest,
    db: Session = Depends(get_db)
):
    try:
        result = GeoScoringEngine.get_nearby_pois(db=db, loc=location_data)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка скоринга геолокации: {str(e)}")
