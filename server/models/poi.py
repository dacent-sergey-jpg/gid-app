from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Boolean, JSON
from sqlalchemy.ext.hybrid import hybrid_property
from geoalchemy2 import Geometry
from datetime import datetime
from database import Base


class POI(Base):
    """Point of Interest model with PostGIS geometry support"""
    
    __tablename__ = "pois"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=False)
    category = Column(String(100), nullable=False, index=True)
    
    # PostGIS geometry: Point(longitude, latitude)
    location = Column(Geometry('POINT', srid=4326), nullable=False, index=True)
    
    # Audio and media
    audio_url = Column(String(500), nullable=True)
    image_url = Column(String(500), nullable=True)
    
    # Historical data
    facts = Column(JSON, default=list)  # List of interesting facts
    built_year = Column(Integer, nullable=True)
    historical_period = Column(String(100), nullable=True)
    
    # Metadata
    priority = Column(Integer, default=5)  # 1-10 for ranking
    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Tracking
    times_visited = Column(Integer, default=0)
    average_rating = Column(Float, default=0.0)

    def __repr__(self):
        return f"<POI(id={self.id}, title='{self.title}', category='{self.category}')>"
