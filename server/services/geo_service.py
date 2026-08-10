import math
from typing import List, Tuple, Optional, Set
from sqlalchemy.orm import Session
from sqlalchemy import func
from geoalchemy2.functions import ST_SetSRID, ST_MakePoint

from models import POI, UserHistory
from schemas import UserLocationRequest, POIResponse, POIScoreBreakdown, NearbyPOIResponse


def calculate_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    diff_lon_rad = math.radians(lon2 - lon1)

    x = math.sin(diff_lon_rad) * math.cos(lat2_rad)
    y = math.cos(lat1_rad) * math.sin(lat2_rad) - (
        math.sin(lat1_rad) * math.cos(lat2_rad) * math.cos(diff_lon_rad)
    )

    initial_bearing = math.atan2(x, y)
    compass_bearing = (math.degrees(initial_bearing) + 360) % 360
    return compass_bearing


def calculate_heading_score(user_heading: Optional[float], user_lat: float, user_lon: float,
                            poi_lat: float, poi_lon: float, speed: float) -> float:
    if user_heading is None or speed < 0.5:
        return 0.8

    bearing_to_poi = calculate_bearing(user_lat, user_lon, poi_lat, poi_lon)
    angle_diff = abs(user_heading - bearing_to_poi)
    if angle_diff > 180:
        angle_diff = 360 - angle_diff

    return max(0.0, (180.0 - angle_diff) / 180.0)


class GeoScoringEngine:
    @staticmethod
    def get_nearby_pois(db: Session, loc: UserLocationRequest) -> NearbyPOIResponse:
        visited_records = (
            db.query(UserHistory.poi_id)
            .filter(UserHistory.user_id == loc.user_id)
            .all()
        )
        visited_poi_ids: Set[str] = {item[0] for item in visited_records}

        user_point = ST_SetSRID(ST_MakePoint(loc.longitude, loc.latitude), 4326)
        
        # Защита: если поле location NULL, вычисляем его из latitude/longitude
        poi_geom = func.coalesce(
            POI.location,
            ST_SetSRID(ST_MakePoint(POI.longitude, POI.latitude), 4326)
        )

        query = (
            db.query(
                POI,
                func.ST_Distance(
                    func.Geography(poi_geom),
                    func.Geography(user_point)
                ).label("distance_meters")
            )
            .filter(
                func.ST_DWithin(
                    func.Geography(poi_geom),
                    func.Geography(user_point),
                    loc.search_radius_meters
                )
            )
        )

        results = query.all()
        scored_pois: List[Tuple[POI, float, POIScoreBreakdown]] = []

        for poi, dist_m in results:
            if poi.id in visited_poi_ids:
                continue

            dist_score = max(0.0, 1.0 - (dist_m / loc.search_radius_meters))
            head_score = calculate_heading_score(
                user_heading=loc.heading,
                user_lat=loc.latitude,
                user_lon=loc.longitude,
                poi_lat=poi.latitude,
                poi_lon=poi.longitude,
                speed=loc.speed or 0.0
            )

            total_score = (
                (poi.interest_score * 0.25) +
                (poi.historical_value * 0.25) +
                (dist_score * 10.0 * 0.30) +
                (head_score * 10.0 * 0.20)
            )

            score_breakdown = POIScoreBreakdown(
                interest=poi.interest_score,
                historical=poi.historical_value,
                distance_score=round(dist_score * 10.0, 2),
                heading_score=round(head_score * 10.0, 2),
                total_score=round(total_score, 2)
            )

            scored_pois.append((poi, dist_m, score_breakdown))

        scored_pois.sort(key=lambda x: x[2].total_score, reverse=True)

        response_items: List[POIResponse] = []
        selected_poi_res: Optional[POIResponse] = None

        for idx, (poi, dist_m, breakdown) in enumerate(scored_pois):
            poi_res = POIResponse(
                id=poi.id,
                name=poi.name,
                category=poi.category,
                latitude=poi.latitude,
                longitude=poi.longitude,
                distance_meters=round(dist_m, 1),
                description=poi.description,
                images=poi.images or [],
                score_info=breakdown
            )

            if idx == 0 and dist_m <= 100.0:
                selected_poi_res = poi_res

            response_items.append(poi_res)

        return NearbyPOIResponse(
            selected_poi=selected_poi_res,
            nearby_pois=response_items
        )
