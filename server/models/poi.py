from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Boolean, JSON, func
from geoalchemy2 import Geometry
from database import Base


class POI(Base):
    """Point of Interest model with PostGIS geometry support"""
    
    __tablename__ = "pois"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True, default="")
    category = Column(String(100), nullable=True, default="Общее", index=True)
    
    # PostGIS geometry: Point(longitude, latitude)
    location = Column(Geometry('POINT', srid=4326), nullable=False, index=True)
    
    # Audio and media
    audio_url = Column(String(500), nullable=True)
    image_url = Column(String(500), nullable=True)
    
    # Historical data
    facts = Column(JSON, nullable=True, default=list)
    built_year = Column(Integer, nullable=True)
    historical_period = Column(String(100), nullable=True)
    
    # Metadata
    priority = Column(Integer, default=5)
    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Tracking
    times_visited = Column(Integer, default=0)
    average_rating = Column(Float, default=0.0)

    def __repr__(self):
        return f"<POI(id={self.id}, title='{self.title}', category='{self.category}')>"
