from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from geoalchemy2 import Geometry
from config import DATABASE_URL

# Create database engine with PostGIS support
engine = create_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()

# Enable PostGIS extension on connection
@event.listens_for(engine, "connect")
def receive_connect(dbapi_connection, connection_record):
    try:
        dbapi_connection.enable_load_extension('postgis')
    except (AttributeError, Exception):
        # PostGIS is enabled at database level, not connection level
        pass


def get_db():
    """Dependency for getting database session in FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)
