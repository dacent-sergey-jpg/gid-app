from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional


class UserLocationRequest(BaseModel):
    user_id: int
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    speed: Optional[float] = 0.0
    heading: Optional[float] = None
    accuracy: Optional[float] = 10.0
    search_radius_meters: Optional[float] = 500.0


class POIScoreBreakdown(BaseModel):
    interest: float
    historical: float
    distance_score: float
    heading_score: float
    total_score: float


class POIResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    category: str
    latitude: float
    longitude: float
    distance_meters: float
    description: Optional[str] = None
    images: List[str] = []
    score_info: Optional[POIScoreBreakdown] = None


class NearbyPOIResponse(BaseModel):
    selected_poi: Optional[POIResponse] = None
    nearby_pois: List[POIResponse] = []


class StoryGenerateRequest(BaseModel):
    user_id: int
    poi_id: str
    style: Optional[str] = "history"  # history, legends, architecture, casual
    voice: Optional[str] = "anna"


class StoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    poi_id: str
    poi_name: str
    story_text: str
    audio_url: Optional[str] = None
    style: str
    voice: str
