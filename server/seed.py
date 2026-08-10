from database import SessionLocal, engine, Base
from models import POI
from geoalchemy2.functions import ST_SetSRID, ST_MakePoint

# Автоматически создаем таблицы, если их еще нет
Base.metadata.create_all(bind=engine)

INITIAL_POIS = [
    {
        "id": "VLG-0001",
        "name": "Софийский собор",
        "category": "Архитектура",
        "lat": 59.2244,
        "lon": 39.8837,
        "description": "Древнейшее сохранившееся каменное здание Вологды, возведенное по повелению Ивана Грозного.",
        "built_period": "XVI век",
        "interest_score": 9.5,
        "historical_value": 10.0,
        "facts": [
            "Строился в 1568—1570 годах по приказу Ивана Грозного.",
            "Внутри сохранились величественные фрески XVII века площадию около 5000 кв. м."
        ],
        "legends": [
            "По легенде, при посещении собора Ивану Грозному на голову упал кусок штукатурки, после чего он решил покинуть Вологду."
        ],
        "images": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Saint_Sophia_Cathedral_Vologda.jpg/800px-Saint_Sophia_Cathedral_Vologda.jpg"
        ]
    },
    {
        "id": "VLG-0002",
        "name": "Вологодский кремль",
        "category": "История",
        "lat": 59.2238,
        "lon": 39.8831,
        "description": "Архиерейский двор, ансамбль исторических зданий XVI–XIX веков.",
        "built_period": "XVI–XIX века",
        "interest_score": 9.0,
        "historical_value": 9.5,
        "facts": [
            "Заложен как крепость Иваном Грозным в 1566 году.",
            "Сегодня на территории располагается Вологодский музей-заповедник."
        ],
        "legends": [],
        "images": []
    },
    {
        "id": "VLG-0003",
        "name": "Памятник букве «О»",
        "category": "Арт-объект",
        "lat": 59.2255,
        "lon": 39.8860,
        "description": "Арт-объект, посвященный характерному вологодскому «окающему» говору.",
        "built_period": "2012 год",
        "interest_score": 8.0,
        "historical_value": 6.0,
        "facts": [
            "Высота кованого памятника составляет около 2.5 метров.",
            "Изготовлен студентами и мастерами Вологодского института бизнеса."
        ],
        "legends": [],
        "images": []
    },
    {
        "id": "VLG-0004",
        "name": "Музей кружева",
        "category": "Музей",
        "lat": 59.2233,
        "lon": 39.8845,
        "description": "Уникальный музей, посвященный традиционному вологодскому промыслу кружевоплетения.",
        "built_period": "2010 год",
        "interest_score": 8.8,
        "historical_value": 8.5,
        "facts": [
            "Экспозиция занимает площадь свыше 1400 кв. метров.",
            "Расположен в здании бывшей Государственной поверочной палаты."
        ],
        "legends": [],
        "images": []
    }
]


def seed_database():
    db = SessionLocal()
    try:
        added_count = 0
        for item in INITIAL_POIS:
            existing = db.query(POI).filter(POI.id == item["id"]).first()
            if not existing:
                poi = POI(
                    id=item["id"],
                    name=item["name"],
                    category=item["category"],
                    latitude=item["lat"],
                    longitude=item["lon"],
                    location=ST_SetSRID(ST_MakePoint(item["lon"], item["lat"]), 4326),
                    description=item["description"],
                    built_period=item["built_period"],
                    interest_score=item["interest_score"],
                    historical_value=item["historical_value"],
                    facts=item["facts"],
                    legends=item["legends"],
                    images=item["images"]
                )
                db.add(poi)
                added_count += 1

        db.commit()
        print(f"✅ База данных заполнена! Добавлено новых POI: {added_count}")
    except Exception as e:
        db.rollback()
        print(f"❌ Ошибка заполнения БД: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
