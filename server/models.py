import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Text, DateTime, ForeignKey, Boolean, JSON
)
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry

from database import Base


class POI(Base):
    """Модель достопримечательности (Point of Interest)"""
    __tablename__ = "pois"

    id = Column(String(50), primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False, index=True)
    
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    
    location = Column(Geometry(geometry_type='POINT', srid=4326), nullable=True)

    description = Column(Text, nullable=True)
    built_period = Column(String(100), nullable=True)
    
    interest_score = Column(Float, default=8.0)
    historical_value = Column(Float, default=8.0)
    
    facts = Column(JSON, default=list)
    interesting_facts = Column(JSON, default=list)
    legends = Column(JSON, default=list)
    images = Column(JSON, default=list)
    sources = Column(JSON, default=list)
    related_poi_ids = Column(JSON, default=list)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)


class User(Base):
    """Модель пользователя приложения"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=True)
    name = Column(String(100), nullable=True)
    
    selected_voice = Column(String(50), default="anna")
    preferred_style = Column(String(50), default="history")
    audio_speed = Column(Float, default=1.0)
    is_premium = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    history = relationship("UserHistory", back_populates="user")
    favorites = relationship("UserFavorite", back_populates="user")


class UserHistory(Base):
    """История прослушанных мест"""
    __tablename__ = "user_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    poi_id = Column(String(50), ForeignKey("pois.id"), nullable=False)
    
    visited_at = Column(DateTime, default=datetime.datetime.utcnow)
    completed_audio = Column(Boolean, default=True)

    user = relationship("User", back_populates="history")
    poi = relationship("POI")


class UserFavorite(Base):
    """Избранное пользователя"""
    __tablename__ = "user_favorites"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    poi_id = Column(String(50), ForeignKey("pois.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="favorites")
    poi = relationship("POI")


class GeneratedStory(Base):
    """Кэш сгенерированных текстов и аудиозаписей для POI"""
    __tablename__ = "generated_stories"

    id = Column(Integer, primary_key=True, autoincrement=True)
    poi_id = Column(String(50), ForeignKey("pois.id"), nullable=False)
    style = Column(String(50), default="history")
    voice = Column(String(50), default="anna")
    
    story_text = Column(Text, nullable=False)
    audio_url = Column(String(500), nullable=True)
    duration_seconds = Column(Float, default=0.0)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
