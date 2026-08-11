# 🚀 ЭТАП 1: Backend - База данных + PostGIS

## 📋 Что было реализовано

### ✅ Полная интеграция PostgreSQL + PostGIS
- **models/poi.py** — SQLAlchemy модель POI с поддержкой геометрии PostGIS
- **database.py** — конфигурация подключения и сессий SQLAlchemy
- **config.py** — переменные окружения для базы данных и API ключей
- **schemas.py** — Pydantic схемы для валидации запросов/ответов
- **seed_data.py** — скрипт заполнения БД 30 объектами Вологды
- **main.py** — обновленный FastAPI backend с пространственными запросами

### 📊 База данных
- **30 POI объектов** Вологды (архитектура, культура, природа)
- **PostGIS POINT geometry** для каждого объекта
- **Пространственные индексы** для быстрых поисков

### 🔍 API endpoints (обновленные)

#### 1. `GET /api/v1/nearby`
Поиск всех объектов в радиусе используя PostGIS ST_DWithin
```bash
curl "http://localhost:8000/api/v1/nearby?lat=59.224167&lon=39.883889&radius_meters=500"
```
**Параметры**: latitude, longitude, radius_meters  
**Возвращает**: List[PoiNearbyResponse] отсортированный по расстоянию

#### 2. `POST /api/v1/ask-guide`
Ответ гида на вопрос пользователя (с фактами из БД)
```bash
curl -X POST "http://localhost:8000/api/v1/ask-guide" \
  -H "Content-Type: application/json" \
  -d '{
    "poi_id": 1,
    "user_question": "Расскажи подробнее",
    "voice_id": "anna"
  }'
```

#### 3. `GET /api/v1/best-poi` (НОВОЕ!)
Выбор лучшего POI по алгоритму оценки (Раздел 7 ТЗ)
```bash
curl "http://localhost:8000/api/v1/best-poi?lat=59.224167&lon=39.883889&radius_meters=500"
```

---

## 🛠️ Инструкция по установке

### 1. Установить PostgreSQL + PostGIS

**macOS (Homebrew)**:
```bash
brew install postgresql postgis
brew services start postgresql
```

**Linux (Ubuntu)**:
```bash
sudo apt-get install postgresql postgresql-contrib postgis
sudo service postgresql start
```

**Windows**: Скачать PostgreSQL installer с https://www.postgresql.org/download/windows/

### 2. Создать базу данных
```bash
# Подключиться к PostgreSQL
psql -U postgres

# В psql:
CREATE DATABASE gid_app;
\c gid_app
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
\q
```

### 3. Установить Python зависимости
```bash
cd server
pip install -r requirements.txt
```

### 4. Настроить переменные окружения
```bash
cp .env.example .env
# Отредактировать .env с вашими данными
nano .env
```

### 5. Заполнить базу данных (seed)
```bash
python seed_data.py
# ✅ Successfully seeded 30 POI objects!
```

### 6. Запустить сервер
```bash
python main.py
# Или:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 7. Проверить API
```bash
# Health check
curl http://localhost:8000/health

# Get stats
curl http://localhost:8000/api/v1/stats

# Get nearby POI
curl "http://localhost:8000/api/v1/nearby?lat=59.2244&lon=39.8837&radius_meters=500"
```

---

## 📁 Структура ЭТАПА 1

```
server/
├── models/
│   └── poi.py              # SQLAlchemy модель с PostGIS
├── database.py             # SQLAlchemy engine и session
├── config.py               # Переменные окружения
├── schemas.py              # Pydantic схемы
├── seed_data.py            # Скрипт заполнения БД (30 объектов)
├── main.py                 # FastAPI приложение с пространственными запросами
├── requirements.txt        # Зависимости Python
└── .env.example            # Пример конфигурации
```

---

## 🎯 Ключевые особенности ЭТАПА 1

### PostGIS интеграция
- ✅ ST_DWithin для поиска в радиусе
- ✅ ST_Distance_Sphere для расчета расстояния
- ✅ Пространственные индексы для производительности
- ✅ WGS84 (SRID 4326) для GPS координат

### 30 объектов Вологды
- 🏛️ Архитектура (Софийский собор, Кремль, Колокольня, Дома)
- 🎭 Культура (Музей кружева, Театр, Галерея, Библиотека)
- 🗿 Памятники (Петр I, Батюшков, Буква Ё, Буква О)
- 🌳 Природа (Набережная, Парк, Лес)

### Алгоритм выбора лучшего POI (Раздел 7 ТЗ)
```
Оценка = 
  distance_score * 0.3 (ближе = выше)
  + priority_score * 0.5 (важность объекта)
  + recency_score * 0.2 (не показывали ранее)
```

---

## 📝 Следующие этапы

- **ЭТАП 2**: RAG система + Claude/Gemini LLM интеграция
- **ЭТАП 3**: Google Cloud TTS для озвучивания
- **ЭТАП 4**: Пространственное масштабирование алгоритма
- **ЭТАП 5**: Google Vision API для камеры
- **ЭТАП 6**: Speech-to-Text обработка

---

## 🐛 Troubleshooting

### "psycopg2: FATAL: role "postgres" does not exist"
```bash
# Create postgres user
sudo -u postgres createuser --superuser $USER
```

### "could not connect to server"
```bash
# Check if PostgreSQL is running
brew services list  # macOS
sudo systemctl status postgresql  # Linux
```

### PostGIS extension not found
```bash
# Install PostGIS in database
psql -U postgres -d gid_app -c "CREATE EXTENSION postgis;"
```

---

**Status**: ✅ ГОТОВО  
**Дата**: 2026-08-11  
**Тест**: Пройти `python seed_data.py` перед ЭТАПОМ 2
