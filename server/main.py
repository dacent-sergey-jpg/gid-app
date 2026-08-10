from fastapi import FastAPI, Query, HTTPException
from pydantic import BaseModel
import math
from typing import List, Optional

app = FastAPI(title="GID Backend API", version="1.0.0")

# Расширенная база данных POI Вологды (Раздел 25 ТЗ)
POI_DATABASE = [
    {
        "id": 1,
        "title": "Софийский собор",
        "category": "Архитектура",
        "description": "Древнейшее сохранившееся каменное здание Вологды, возведенное по повелению Ивана Грозного.",
        "lat": 59.2244,
        "lon": 39.8837,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        "facts": [
            "Строился с 1568 по 1570 год.",
            "Иван Грозный едва не сделал Вологду столицей Опричнины."
        ]
    },
    {
        "id": 2,
        "title": "Вологодский кремль",
        "category": "История",
        "description": "Архиерейский двор, ансамбль исторических зданий XVI–XIX веков.",
        "lat": 59.2238,
        "lon": 39.8831,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        "facts": ["Включает в себя Палаты Иосифа Золотого."]
    },
    {
        "id": 3,
        "title": "Памятник букве «О»",
        "category": "Арт-объект",
        "description": "Арт-объект, посвященный характерному вологодскому «окающему» говору.",
        "lat": 59.2255,
        "lon": 39.8860,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
        "facts": ["Установлен в 2012 году студентами."]
    },
    {
        "id": 4,
        "title": "Музей кружева",
        "category": "Культура",
        "description": "Уникальный музей, посвященный традиционному вологодскому промыслу кружевоплетения.",
        "lat": 59.2233,
        "lon": 39.8845,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
        "facts": ["Экспозиция занимает более 1400 кв. метров."]
    }
]

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

class AskGuideRequest(BaseModel):
    poi_id: int
    user_question: str
    voice_id: str

@app.get("/api/v1/nearby")
def get_nearby_poi(
    lat: float = Query(..., description="Широта"),
    lon: float = Query(..., description="Долгота"),
    radius_meters: float = Query(5000.0, description="Радиус поиска в метрах")
):
    results = []
    for poi in POI_DATABASE:
        dist = calculate_distance(lat, lon, poi["lat"], poi["lon"])
        if dist <= radius_meters:
            poi_with_dist = poi.copy()
            poi_with_dist["distance_meters"] = round(dist, 1)
            results.append(poi_with_dist)

    results.sort(key=lambda x: x["distance_meters"])
    return {"status": "success", "count": len(results), "data": results}

@app.post("/api/v1/ask-guide")
def ask_guide(request: AskGuideRequest):
    poi = next((p for p in POI_DATABASE if p["id"] == request.poi_id), None)
    if not poi:
        raise HTTPException(status_code=404, detail="Объект не найден")

    # Имитация RAG + AI ответа с использованием проверенных фактов
    facts_str = " ".join(poi.get("facts", []))
    answer = f"Отвечает гид ({request.voice_id.capitalize()}): По поводу '{poi['title']}' — {facts_str} Относительно вашего вопроса: '{request.user_question}' — это место действительно уникально своей историей!"

    return {
        "status": "success",
        "answer": answer,
        "audio_url": poi["audio_url"]
    }
