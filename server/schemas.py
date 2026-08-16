from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class PoiBase(BaseModel):
    """Base POI schema"""
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = ""
    category: str = Field(default="Общее", min_length=1, max_length=100)
    audio_url: Optional[str] = None
    image_url: Optional[str] = None
    facts: List[str] = Field(default_factory=list)
    built_year: Optional[int] = None
    historical_period: Optional[str] = None
    priority: int = Field(default=5, ge=1, le=10)


class PoiCreate(PoiBase):
    """Schema for creating POI"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class PoiUpdate(BaseModel):
    """Schema for updating POI"""
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    audio_url: Optional[str] = None
    image_url: Optional[str] = None
    facts: Optional[List[str]] = None
    built_year: Optional[int] = None
    historical_period: Optional[str] = None
    priority: Optional[int] = Field(None, ge=1, le=10)


class PoiResponse(PoiBase):
    """Schema for POI response"""
    id: int
    latitude: float
    longitude: float
    times_visited: int = 0
    average_rating: float = 0.0
    is_active: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class PoiNearbyResponse(BaseModel):
    """Schema for nearby POI with distance"""
    id: int
    title: str
    description: Optional[str] = ""
    category: Optional[str] = "Общее"
    latitude: float
    longitude: float
    audio_url: Optional[str] = None
    image_url: Optional[str] = None
    facts: List[str] = Field(default_factory=list)
    distance_meters: float
    priority: int = 5

    class Config:
        from_attributes = True


class NearbyPoiRequest(BaseModel):
    """Request schema for finding nearby POI"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    radius_meters: float = Field(default=5000.0, gt=0)


class AskGuideRequest(BaseModel):
    """Request schema for asking guide"""
    poi_id: int
    user_question: str = Field(..., min_length=1, max_length=500)
    voice_id: str = "anna"


class AskGuideResponse(BaseModel):
    """Response schema for guide answer"""
    status: str
    answer: str
    audio_url: Optional[str] = None
