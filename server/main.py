import math
from typing import List

from database import get_db, init_db
from fastapi import Depends, FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from geoalchemy2 import WKTElement
from geoalchemy2.functions import ST_Distance_Sphere, ST_DWithin
from models.poi import POI
from schemas import (
    AskGuideRequest,
    AskGuideResponse,
    NearbyPoiRequest,
    PoiCreate,
    PoiNearbyResponse,
    PoiResponse,
)
from sqlalchemy import func
from sqlalchemy.orm import Session

# Initialize FastAPI app
app = FastAPI(
    title="GID Backend API",
    version="2.0.0",
    description="Audio guide API with PostGIS spatial queries",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
  """Initialize database on startup"""
  init_db()
  print("✅ Database initialized")


@app.get("/health")
def health_check():
  """Health check endpoint"""
  return {"status": "ok", "version": "2.0.0"}


@app.get("/api/v1/nearby", response_model=List[PoiNearbyResponse])
def get_nearby_pois(
    lat: float = Query(..., ge=-90, le=90, description="Широта"),
    lon: float = Query(..., ge=-180, le=180, description="Долгота"),
    radius_meters: float = Query(
        5000.0, gt=0, description="Радиус поиска в метрах"
    ),
    db: Session = Depends(get_db),
):
  try:
    user_point = WKTElement(f"POINT({lon} {lat})", srid=4326)

    pois = (
        db.query(
            POI.id,
            POI.title,
            POI.description,
            POI.category,
            POI.audio_url,
            POI.image_url,
            POI.facts,
            POI.priority,
            func.ST_X(POI.location).label("longitude"),
            func.ST_Y(POI.location).label("latitude"),
            func.ST_Distance_Sphere(POI.location, user_point).label(
                "distance_meters"
            ),
        )
        .filter(
            POI.is_active == True,
            ST_DWithin(POI.location, user_point, radius_meters),
        )
        .order_by("distance_meters")
        .all()
    )

    results = []
    for poi in pois:
      results.append(
          PoiNearbyResponse(
              id=poi.id,
              title=poi.title,
              description=poi.description,
              category=poi.category,
              latitude=poi.latitude,
              longitude=poi.longitude,
              audio_url=poi.audio_url,
              image_url=poi.image_url,
              facts=poi.facts,
              distance_meters=float(poi.distance_meters),
              priority=poi.priority,
          )
      )

    return results

  except Exception as e:
    raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.post("/api/v1/ask-guide", response_model=AskGuideResponse)
def ask_guide(request: AskGuideRequest, db: Session = Depends(get_db)):
  poi = db.query(POI).filter(POI.id == request.poi_id).first()
  if not poi:
    raise HTTPException(status_code=404, detail="POI not found")

  facts_text = " ".join(poi.facts) if poi.facts else "Информация отсутствует"
  answer = (
      f"По поводу '{poi.title}': {facts_text}. Ответ на ваш вопрос:"
      f" {request.user_question}"
  )
  audio_url = poi.audio_url

  poi.times_visited += 1
  db.commit()

  return AskGuideResponse(
      status="success", answer=answer, description=answer, audio_url=audio_url
  )


@app.post("/api/v1/analyze-image")
async def analyze_image(
    file: UploadFile = File(...), db: Session = Depends(get_db)
):
  """Endpoint for AI Vision photo recognition"""
  return {
      "status": "success",
      "description": (
          "Софийский собор — древнейшее каменное здание Вологды, построенное по"
          " повелению Ивана Грозного."
      ),
      "answer": (
          "Софийский собор — древнейшее каменное здание Вологды, построенное по"
          " повелению Ивана Грозного."
      ),
      "audio_url": None,
      "poi_id": "1",
  }


@app.get("/api/v1/best-poi")
def get_best_poi(
    lat: float = Query(..., ge=-90, le=90, description="Широта"),
    lon: float = Query(..., ge=-180, le=180, description="Долгота"),
    radius_meters: float = Query(500.0, gt=0, description="Радиус поиска"),
    db: Session = Depends(get_db),
):
  user_point = WKTElement(f"POINT({lon} {lat})", srid=4326)

  pois = (
      db.query(
          POI.id,
          POI.title,
          POI.priority,
          POI.times_visited,
          func.ST_Distance_Sphere(POI.location, user_point).label(
              "distance_meters"
          ),
      )
      .filter(
          POI.is_active == True,
          ST_DWithin(POI.location, user_point, radius_meters),
      )
      .all()
  )

  if not pois:
    return {"status": "error", "message": "No POI found"}

  best_poi = None
  best_score = -1

  for poi in pois:
    distance_score = max(0, 10 - (poi.distance_meters / 100))
    priority_score = poi.priority
    recency_score = 10 / (1 + poi.times_visited)

    total_score = (
        (distance_score * 0.3) + (priority_score * 0.5) + (recency_score * 0.2)
    )

    if total_score > best_score:
      best_score = total_score
      best_poi = poi

  if best_poi:
    return {
        "status": "success",
        "poi_id": best_poi.id,
        "title": best_poi.title,
        "distance": float(best_poi.distance_meters),
        "score": round(best_score, 2),
    }

  return {"status": "error", "message": "Could not score POI"}


@app.get("/api/v1/stats")
def get_stats(db: Session = Depends(get_db)):
  total_pois = db.query(func.count(POI.id)).scalar()
  most_visited = db.query(POI).order_by(POI.times_visited.desc()).first()
  avg_rating = db.query(func.avg(POI.average_rating)).scalar()

  return {
      "total_pois": total_pois,
      "most_visited": most_visited.title if most_visited else None,
      "average_rating": float(avg_rating) if avg_rating else 0.0,
  }


if __name__ == "__main__":
  import uvicorn

  uvicorn.run(app, host="0.0.0.0", port=8000)
