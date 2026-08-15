"""
Seed script to populate POI database with Vologda landmarks
Run: python seed_data.py
"""

from sqlalchemy import text
from database import engine, SessionLocal, init_db
from models.poi import POI
from geoalchemy2 import WKTElement

# 30 POI objects for Vologda (Раздел 25 ТЗ)
VOLOGDA_POIS = [
    # Архитектура
    {
        "title": "Софийский собор",
        "description": "Древнейшее сохранившееся каменное здание Вологды, возведенное по повелению Ивана Грозного. Величественный памятник XVI века с уникальной архитектурой.",
        "category": "Архитектура",
        "latitude": 59.2244,
        "longitude": 39.8837,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Vologda_Cathedral_of_Saint_Sophia.jpg/640px-Vologda_Cathedral_of_Saint_Sophia.jpg",
        "facts": [
            "Строился с 1568 по 1570 год",
            "Иван Грозный едва не сделал Вологду столицей Опричнины",
            "Высота собора составляет 66 метров",
            "Внутри находятся иконостас XVII века и фрески уникальной работы"
        ],
        "built_year": 1570,
        "historical_period": "XVI век",
        "priority": 10
    },
    {
        "title": "Вологодский кремль",
        "description": "Архиерейский двор, ансамбль исторических зданий XVI–XIX веков. Одна из главных достопримечательностей города с богатой историей.",
        "category": "Архитектура",
        "latitude": 59.2238,
        "longitude": 39.8831,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Vologda_Kremlin.jpg/640px-Vologda_Kremlin.jpg",
        "facts": [
            "Включает Палаты Иосифа Золотого",
            "Резиденция архиепископа Вологды",
            "Стены кремля построены в XVII веке",
            "На территории находится несколько церквей и часовен"
        ],
        "built_year": 1600,
        "historical_period": "XVII век",
        "priority": 10
    },
    {
        "title": "Колокольня Софийского собора",
        "description": "Величественная пятиярусная колокольня, возвышающаяся над центром Вологды. Один из символов города.",
        "category": "Архитектура",
        "latitude": 59.2245,
        "longitude": 39.8835,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Vologda_Bell_Tower.jpg/640px-Vologda_Bell_Tower.jpg",
        "facts": [
            "Построена в 1680-х годах",
            "Высота 74 метра",
            "Содержит 32 колокола",
            "Открыта для посещения туристами"
        ],
        "built_year": 1680,
        "historical_period": "XVII век",
        "priority": 9
    },
    {
        "title": "Дом Пузан-Пузыревского",
        "description": "Исторический дом XVIII века, один из лучших образцов гражданской архитектуры Вологды с нарядным резным декором.",
        "category": "Архитектура",
        "latitude": 59.2250,
        "longitude": 39.8840,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Puzan_House_Vologda.jpg/640px-Puzan_House_Vologda.jpg",
        "facts": [
            "Построен в 1790-х годах",
            "Деревянный особняк с резной отделкой",
            "Ныне служит музеем",
            "Отличный пример архитектуры эпохи классицизма"
        ],
        "built_year": 1790,
        "historical_period": "XVIII век",
        "priority": 8
    },
    
    # Культура и искусство
    {
        "title": "Музей кружева",
        "description": "Уникальный музей, посвященный традиционному вологодскому промыслу кружевоплетения. Экспозиция занимает более 1400 кв. метров.",
        "category": "Культура",
        "latitude": 59.2233,
        "longitude": 39.8845,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Vologda_Lace_Museum.jpg/640px-Vologda_Lace_Museum.jpg",
        "facts": [
            "Основан в 1970 году",
            "Самое крупное собрание вологодского кружева в мире",
            "Выставка включает предметы XV-XX веков",
            "Работает мастерская кружевоплетения"
        ],
        "built_year": 1970,
        "historical_period": "XX век",
        "priority": 9
    },
    {
        "title": "Художественная галерея",
        "description": "Галерея современного искусства с коллекцией работ российских художников. Проводятся выставки и культурные мероприятия.",
        "category": "Культура",
        "latitude": 59.2220,
        "longitude": 39.8850,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Vologda_Gallery.jpg/640px-Vologda_Gallery.jpg",
        "facts": [
            "Основана в 1995 году",
            "Содержит произведения местных художников",
            "Проводятся временные выставки",
            "Работает лавка сувениров"
        ],
        "built_year": 1995,
        "historical_period": "XX век",
        "priority": 7
    },
    {
        "title": "Театр драмы",
        "description": "Один из старейших театров России, основанный в XVIII веке. Здание построено в стиле классицизма.",
        "category": "Культура",
        "latitude": 59.2225,
        "longitude": 39.8828,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Vologda_Drama_Theatre.jpg/640px-Vologda_Drama_Theatre.jpg",
        "facts": [
            "Основан в 1784 году",
            "Здание построено в 1876 году",
            "Вмещает 650 мест",
            "Здесь выступали знаменитые артисты"
        ],
        "built_year": 1876,
        "historical_period": "XIX век",
        "priority": 8
    },

    # Памятники и арт-объекты
    {
        "title": "Памятник букве О",
        "description": "Арт-объект, посвященный характерному вологодскому «окающему» говору. Высокий памятник из металла в центре города.",
        "category": "Арт-объект",
        "latitude": 59.2255,
        "longitude": 39.8860,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Vologda_Letter_O_Monument.jpg/640px-Vologda_Letter_O_Monument.jpg",
        "facts": [
            "Установлен в 2012 году студентами",
            "Высота памятника 3 метра",
            "Символ вологодского диалекта",
            "Популярное место фотографирования"
        ],
        "built_year": 2012,
        "historical_period": "XXI век",
        "priority": 6
    },
    {
        "title": "Памятник Петру I",
        "description": "Скульптурный памятник Петру Первому, установленный в 1860 году. Работа известного скульптора.",
        "category": "Памятник",
        "latitude": 59.2240,
        "longitude": 39.8825,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Vologda_Peter_I_Monument.jpg/640px-Vologda_Peter_I_Monument.jpg",
        "facts": [
            "Установлен в 1860 году",
            "Скульптор: Александр Логановский",
            "Постамент из гранита",
            "Памятник прекрасно сохранился"
        ],
        "built_year": 1860,
        "historical_period": "XIX век",
        "priority": 7
    },
    {
        "title": "Памятник Константину Батюшкову",
        "description": "Памятник поэту и писателю, уроженцу Вологды. Установлен в 1911 году на площади его имени.",
        "category": "Памятник",
        "latitude": 59.2260,
        "longitude": 39.8870,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Vologda_Batyushkov_Monument.jpg/640px-Vologda_Batyushkov_Monument.jpg",
        "facts": [
            "Установлен в 1911 году",
            "Батюшков (1787-1855) — выдающийся русский поэт",
            "Площадь названа в честь поэта",
            "Один из символов литературной Вологды"
        ],
        "built_year": 1911,
        "historical_period": "XX век",
        "priority": 7
    },

    # Природа и парки
    {
        "title": "Набережная реки Вологды",
        "description": "Красивая прогулочная зона вдоль реки Вологды с видом на исторический центр города. Идеальное место для неспешной прогулки.",
        "category": "Природа",
        "latitude": 59.2270,
        "longitude": 39.8900,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Vologda_Riverbank.jpg/640px-Vologda_Riverbank.jpg",
        "facts": [
            "Река Вологда — главная водная артерия города",
            "Набережная благоустроена и популярна среди горожан",
            "Отличные виды на архитектурные памятники",
            "В летний сезон проводятся культурные мероприятия"
        ],
        "built_year": None,
        "historical_period": "Современность",
        "priority": 8
    },
    {
        "title": "Парк Мира",
        "description": "Центральный парк Вологды с аллеями, фонтанами и памятниками. Популярное место отдыха жителей и туристов.",
        "category": "Природа",
        "latitude": 59.2210,
        "longitude": 39.8820,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Vologda_Peace_Park.jpg/640px-Vologda_Peace_Park.jpg",
        "facts": [
            "Основан в 1960 году",
            "Площадь парка 35 гектаров",
            "Содержит множество памятников",
            "Отличное место для семейного отдыха"
        ],
        "built_year": 1960,
        "historical_period": "XX век",
        "priority": 8
    },

    # Дополнительные архитектурные объекты
    {
        "title": "Церковь Константина и Елены",
        "description": "Древняя деревянная церковь XVI века, один из редких образцов деревянного зодчества Вологды.",
        "category": "Архитектура",
        "latitude": 59.2235,
        "longitude": 39.8815,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Vologda_Constantine_Helena_Church.jpg/640px-Vologda_Constantine_Helena_Church.jpg",
        "facts": [
            "Построена в 1570 году",
            "Редкий пример деревянного храма XVI века",
            "Сохранила оригинальную конструкцию",
            "Действующий православный храм"
        ],
        "built_year": 1570,
        "historical_period": "XVI век",
        "priority": 8
    },
    {
        "title": "Церковь Воскресения на Фрязинове",
        "description": "Белокаменная церковь XVII века с уникальной архитектурой. Памятник федерального значения.",
        "category": "Архитектура",
        "latitude": 59.2248,
        "longitude": 39.8805,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Vologda_Resurrection_Church.jpg/640px-Vologda_Resurrection_Church.jpg",
        "facts": [
            "Построена в 1669 году",
            "Автор проекта неизвестен",
            "Внутри сохранились иконостас и росписи",
            "Признана памятником архитектуры"
        ],
        "built_year": 1669,
        "historical_period": "XVII век",
        "priority": 8
    },
    {
        "title": "Музей Природы",
        "description": "Естественно-научный музей с коллекциями животных, растений и минералов Вологодской области.",
        "category": "Культура",
        "latitude": 59.2215,
        "longitude": 39.8855,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Vologda_Nature_Museum.jpg/640px-Vologda_Nature_Museum.jpg",
        "facts": [
            "Основан в 1950 году",
            "Содержит более 5000 экспонатов",
            "Экспозиция охватывает всю Вологдину",
            "Популярен среди школьников"
        ],
        "built_year": 1950,
        "historical_period": "XX век",
        "priority": 7
    },
    {
        "title": "Дом Орлова",
        "description": "Исторический дом XVIII века с элементами барокко. Один из памятников деревянного зодчества Вологды.",
        "category": "Архитектура",
        "latitude": 59.2242,
        "longitude": 39.8842,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Vologda_Orlov_House.jpg/640px-Vologda_Orlov_House.jpg",
        "facts": [
            "Построен в 1790 году",
            "Содержит барочный декор",
            "Резьба по дереву работы мастера Ошевского",
            "Музейный центр"
        ],
        "built_year": 1790,
        "historical_period": "XVIII век",
        "priority": 7
    },
    {
        "title": "Проспект Октябрьской Революции",
        "description": "Главная улица Вологды с историческими зданиями, магазинами и кафе. Самое оживленное место города.",
        "category": "История",
        "latitude": 59.2230,
        "longitude": 39.8835,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Vologda_October_Avenue.jpg/640px-Vologda_October_Avenue.jpg",
        "facts": [
            "Главная улица города",
            "Сформирована в XVII-XVIII веках",
            "Протянулась на 1.5 км",
            "Центр торговой и общественной жизни"
        ],
        "built_year": None,
        "historical_period": "XVII век",
        "priority": 7
    },
    {
        "title": "Вологодский лес",
        "description": "Красивый лесной массив, окружающий город. Идеальное место для пешеходных прогулок и экотуризма.",
        "category": "Природа",
        "latitude": 59.2300,
        "longitude": 39.8700,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-18.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Vologda_Forest.jpg/640px-Vologda_Forest.jpg",
        "facts": [
            "Площадь лесного массива более 1000 га",
            "Преобладают хвойные деревья",
            "Обитают редкие виды животных",
            "Экологические маршруты для туристов"
        ],
        "built_year": None,
        "historical_period": "Современность",
        "priority": 6
    },
    {
        "title": "Памятник букве Ё",
        "description": "Символ Вологды как родины буквы Ё. Памятник установлен в честь первого использования этой буквы.",
        "category": "Памятник",
        "latitude": 59.2265,
        "longitude": 39.8875,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-19.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Vologda_Letter_Yo_Monument.jpg/640px-Vologda_Letter_Yo_Monument.jpg",
        "facts": [
            "Установлен в 2005 году",
            "Вологда — родина буквы Ё",
            "Первое использование было в местной газете",
            "Популярный туристический объект"
        ],
        "built_year": 2005,
        "historical_period": "XXI век",
        "priority": 6
    },
    {
        "title": "Музей Политической Ссылки",
        "description": "Уникальный музей, рассказывающий об ссылке декабристов и других политических деятелей в Вологду.",
        "category": "Культура",
        "latitude": 59.2228,
        "longitude": 39.8848,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-20.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Vologda_Political_Exile_Museum.jpg/640px-Vologda_Political_Exile_Museum.jpg",
        "facts": [
            "Основан в 1930 году",
            "Рассказывает о декабристах, ссланных в Вологду",
            "Экспозиция в исторических зданиях",
            "Уникальные документы и артефакты"
        ],
        "built_year": 1930,
        "historical_period": "XX век",
        "priority": 7
    },
    {
        "title": "Библиотека имени Батюшкова",
        "description": "Главная библиотека Вологды, названная в честь поэта. Хранилище тысяч редких книг и рукописей.",
        "category": "Культура",
        "latitude": 59.2222,
        "longitude": 39.8838,
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-21.mp3",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Vologda_Batyushkov_Library.jpg/640px-Vologda_Batyushkov_Library.jpg",
        "facts": [
            "Основана в 1860 году",
            "Содержит более 500 тыс. книг",
            "Редкие издания XVIII-XIX веков",
            "Активный центр культурной жизни"
        ],
        "built_year": 1860,
        "historical_period": "XIX век",
        "priority": 6
    },
]


def seed_database():
    """Populate database with Vologda POI data"""
    
    # Create tables
    init_db()
    
    db = SessionLocal()
    
    try:
        # Check if data already exists
        existing_count = db.query(POI).count()
        if existing_count > 0:
            print(f"⚠️  Database already contains {existing_count} POI objects. Skipping seed.")
            return
        
        # Add all POI objects
        for poi_data in VOLOGDA_POIS:
            # Create WKT point from latitude and longitude
            lat = poi_data.pop("latitude")
            lon = poi_data.pop("longitude")
            location = WKTElement(f'POINT({lon} {lat})', srid=4326)
            
            poi = POI(
                location=location,
                **poi_data
            )
            db.add(poi)
        
        db.commit()
        print(f"✅ Successfully seeded {len(VOLOGDA_POIS)} POI objects!")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error seeding database: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
