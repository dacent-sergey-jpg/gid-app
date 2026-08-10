from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional

from schemas import UserLocationRequest, NearbyPOIResponse
from services.geo_service import GeoScoringEngine
from database import get_db

router = APIRouter(tags=["Location & Geo-Guide"])


@router.get("/api/v1/nearby", response_model=NearbyPOIResponse)
@router.get("/api/v1/location/nearby", response_model=NearbyPOIResponse)
def get_nearby_poi_get(
    lat: float = Query(..., description="Широта"),
    lon: float = Query(..., description="Долгота"),
    radius_meters: float = Query(5000.0, description="Радиус поиска в метрах"),
    user_id: int = Query(1, description="ID пользователя"),
    db: Session = Depends(get_db)
):
    """
    Простой GET-эндпоинт для быстрых тестов из браузера или Postman.
    """
    try:
        loc_request = UserLocationRequest(
            user_id=user_id,
            latitude=lat,
            longitude=lon,
            search_radius_meters=radius_meters
        )
        return GeoScoringEngine.get_nearby_pois(db=db, loc=loc_request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка поиска точек: {str(e)}")


@router.post("/api/v1/location/nearby", response_model=NearbyPOIResponse)
def get_nearby_poi_post(
    location_data: UserLocationRequest,
    db: Session = Depends(get_db)
):
    """
    Основной POST-эндпоинт для мобильного приложения Flutter
    с поддержкой азимута движения, скорости и параметров скоринга.
    """
    try:
        return GeoScoringEngine.get_nearby_pois(db=db, loc=location_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка скоринга геолокации: {str(e)}")
