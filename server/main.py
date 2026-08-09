from fastapi import FastAPI, Query
import math

app = FastAPI(title="GID Backend API")

POI_DATABASE = [
    {
        "id": 1,
        "title": "Софийский собор",
        "description": "Древнейшее сохранившееся каменное здание Вологды, возведенное по повелению Ивана Грозного.",
        "lat": 59.2244,
        "lon": 39.8837,
        "audio_url": "https://example.com/audio/sophia.mp3"
    },
    {
        "id": 2,
        "title": "Вологодский кремль",
        "description": "Архиерейский двор, ансамбль исторических зданий XVI–XIX веков.",
        "lat": 59.2238,
        "lon": 39.8831,
        "audio_url": "https://example.com/audio/kremlin.mp3"
    },
    {
        "id": 3,
        "title": "Памятник букве «О»",
        "description": "Арт-объект, посвященный характерному вологодскому «окающему» говору.",
        "lat": 59.2255,
        "lon": 39.8860,
        "audio_url": "https://example.com/audio/letter_o.mp3"
    },
    {
        "id": 4,
        "title": "Музей кружева",
        "description": "Уникальный музей, посвященный традиционному вологодскому промыслу кружевоплетения.",
        "lat": 59.2233,
        "lon": 39.8845,
        "audio_url": "https://example.com/audio/lace_museum.mp3"
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
    return {
        "status": "success",
        "count": len(results),
        "data": results
    }
