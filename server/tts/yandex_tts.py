"""
Yandex SpeechKit Text-to-Speech
https://cloud.yandex.ru/docs/speechkit/tts/
"""

import hashlib
from pathlib import Path
from typing import Optional
import httpx

from config import YANDEX_API_KEY, YANDEX_FOLDER_ID

YANDEX_TTS_URL = "https://tts.api.cloud.yandex.net/speech/v1/tts:synthesize"

# Голоса гидов из ТЗ -> голоса Yandex SpeechKit
GUIDE_VOICES = {
    "anna": "marina",        # Анна — профессиональный экскурсовод
    "alexander": "alexander",  # Александр — историк
    "mikhail": "kirill",     # Михаил — с юмором
}

DEFAULT_VOICE = "marina"
# Директория относительно корня проекта: server/static/audio
AUDIO_DIR = Path(__file__).resolve().parent.parent / "static" / "audio"


class YandexTTS:
    """Synthesize speech using Yandex SpeechKit."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        folder_id: Optional[str] = None,
    ):
        self.api_key = api_key or YANDEX_API_KEY
        self.folder_id = folder_id or YANDEX_FOLDER_ID
        self.enabled = bool(self.api_key and self.folder_id)
        
        # Гарантируем создание папки для кэша
        AUDIO_DIR.mkdir(parents=True, exist_ok=True)

        if self.enabled:
            print("✅ Yandex SpeechKit TTS configured")
        else:
            print("⚠️ Warning: Yandex TTS credentials not set")

    def resolve_voice(self, voice_id: str) -> str:
        return GUIDE_VOICES.get(voice_id, DEFAULT_VOICE)

    def synthesize_to_file(
        self,
        text: str,
        voice_id: str = "anna",
        speed: float = 1.0,
    ) -> Optional[str]:
        """
        Synthesize text to OGG file. Returns relative URL path (/static/audio/...).
        Uses cache: same text+voice+speed -> same file.
        """
        if not self.enabled or not text or not text.strip():
            return None

        # Ограничение скорости вещания в пределах API (0.1 - 3.0)
        clamped_speed = max(0.1, min(3.0, speed))
        voice = self.resolve_voice(voice_id)
        
        # Хэширование текста для кэша
        clean_text = text.strip()
        cache_key = hashlib.sha256(f"{voice}:{clamped_speed}:{clean_text}".encode()).hexdigest()[:16]
        filename = f"{cache_key}.ogg"
        filepath = AUDIO_DIR / filename

        # Если файл уже отрендерен — отдаем из кэша
        if filepath.exists():
            return f"/static/audio/{filename}"

        audio_data = self._call_tts(clean_text, voice, clamped_speed)
        if not audio_data:
            return None

        try:
            filepath.write_bytes(audio_data)
            return f"/static/audio/{filename}"
        except Exception as e:
            print(f"❌ Error saving TTS audio file: {e}")
            return None

    def _call_tts(self, text: str, voice: str, speed: float) -> Optional[bytes]:
        headers = {"Authorization": f"Api-Key {self.api_key}"}
        data = {
            "text": text[:5000],  # Лимит Yandex TTS — 5000 символов
            "lang": "ru-RU",
            "voice": voice,
            "format": "oggopus",
            "folderId": self.folder_id,
            "speed": str(round(speed, 2)),
        }

        try:
            with httpx.Client(timeout=15.0) as client:
                response = client.post(YANDEX_TTS_URL, headers=headers, data=data)
                response.raise_for_status()
                return response.content
        except Exception as e:
            print(f"❌ Error calling Yandex TTS: {e}")
            if hasattr(e, "response") and e.response is not None:
                print(f"TTS response detail: {e.response.text[:300]}")
            return None
