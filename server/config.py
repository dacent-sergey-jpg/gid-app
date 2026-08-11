import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration
DATABASE_URL = os.getenv(
    'DATABASE_URL',
    'postgresql://postgres:password@localhost:5432/gid_app'
)

# API Keys
GOOGLE_VISION_API_KEY = os.getenv('GOOGLE_VISION_API_KEY', '')
GOOGLE_TTS_API_KEY = os.getenv('GOOGLE_TTS_API_KEY', '')
GOOGLE_SPEECH_API_KEY = os.getenv('GOOGLE_SPEECH_API_KEY', '')
CLAUDE_API_KEY = os.getenv('CLAUDE_API_KEY', '')

# Application settings
APP_ENV = os.getenv('APP_ENV', 'development')
DEBUG = APP_ENV == 'development'
