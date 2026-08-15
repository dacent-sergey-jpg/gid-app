"""
LLM Generator component for RAG system
Интеграция с YandexGPT API
"""

import re
from typing import List, Optional

import httpx

from config import YANDEX_API_KEY, YANDEX_FOLDER_ID, YANDEX_GPT_MODEL

YANDEX_COMPLETION_URL = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"


class LLMGenerator:
    """Generator component using YandexGPT API"""

    def __init__(
        self,
        api_key: Optional[str] = None,
        folder_id: Optional[str] = None,
        model: Optional[str] = None,
    ):
        self.api_key = api_key or YANDEX_API_KEY
        self.folder_id = folder_id or YANDEX_FOLDER_ID
        self.model = model or YANDEX_GPT_MODEL
        self.enabled = bool(self.api_key and self.folder_id)

        if not self.enabled:
            print("⚠️ Warning: YANDEX_API_KEY or YANDEX_FOLDER_ID not set. LLM features will be disabled.")
        else:
            print("✅ YandexGPT API configured")

    def generate_answer(
        self,
        context: str,
        user_question: str,
        language: str = "russian",
        max_tokens: int = 500,
    ) -> str:
        """
        Generate answer to user question using YandexGPT.

        Параметры ТЗ раздел 11 (Ответ гида):
        - Использует верифицированные факты (RAG context)
        - Ответ на русском языке
        - Не придумывает факты вне контекста
        """
        if not self.enabled:
            return self._fallback_answer(context, user_question)

        system_prompt = (
            "Ты персональный аудиогид для туристов в России. "
            "Отвечай только на основе проверенных фактов из контекста. "
            "Не выдумывай даты, имена и события. "
            "Будь дружелюбным, говори кратко — 2-3 предложения."
        )
        user_prompt = self._build_prompt(context, user_question, language)

        try:
            return self._call_yandexgpt(system_prompt, user_prompt, max_tokens)
        except Exception as e:
            print(f"❌ Error calling YandexGPT: {e}")
            return self._fallback_answer(context, user_question)

    def _call_yandexgpt(self, system_text: str, user_text: str, max_tokens: int) -> str:
        headers = {
            "Authorization": f"Api-Key {self.api_key}",
            "x-folder-id": self.folder_id,
            "Content-Type": "application/json",
        }
        payload = {
            "modelUri": f"gpt://{self.folder_id}/{self.model}",
            "completionOptions": {
                "stream": False,
                "temperature": 0.5,
                "maxTokens": str(max_tokens),
            },
            "messages": [
                {"role": "system", "text": system_text},
                {"role": "user", "text": user_text},
            ],
        }

        with httpx.Client(timeout=30.0) as client:
            response = client.post(YANDEX_COMPLETION_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()

        alternatives = data.get("result", {}).get("alternatives", [])
        if not alternatives:
            raise ValueError("YandexGPT returned empty response")

        return alternatives[0]["message"]["text"].strip()

    def _build_prompt(self, context: str, user_question: str, language: str) -> str:
        return f"""Используй ТОЛЬКО проверенные факты из контекста ниже.
Ответь на {language.upper()} языке.
Не добавляй информацию, которой нет в контексте.

ПРОВЕРЕННЫЙ КОНТЕКСТ:
{context}

ВОПРОС ПОЛЬЗОВАТЕЛЯ: {user_question}

ОТВЕТ:"""

    def _fallback_answer(self, context: str, user_question: str) -> str:
        """Fallback answer when YandexGPT API is unavailable"""
        facts_section = context.split("Интересные факты:")[1] if "Интересные факты:" in context else ""
        answer = f"Относительно вашего вопроса «{user_question}»: "

        if "Построен" in context:
            year_match = re.search(r"Построен/основан: (\d+)", context)
            if year_match:
                answer += f"Это произошло в {year_match.group(1)} году. "

        if facts_section.strip():
            answer += "Вот несколько интересных фактов: " + facts_section.split("\n")[1]
        else:
            answer += "Извините, но у меня недостаточно информации для полного ответа."

        return answer.strip()

    def generate_route_description(self, pois: List[dict], start_poi: str) -> str:
        if not self.enabled:
            return "Информация о маршруте недоступна"

        poi_list = "\n".join(
            [f"- {poi['title']}: {poi['description'][:100]}" for poi in pois]
        )
        system_prompt = "Ты создаёшь описания туристических маршрутов для аудиогида."
        user_prompt = f"""Составь краткое (2-3 предложения) увлекательное описание маршрута на русском языке.
Стартовая точка: {start_poi}

Точки маршрута:
{poi_list}"""

        try:
            return self._call_yandexgpt(system_prompt, user_prompt, max_tokens=300)
        except Exception as e:
            print(f"Error generating route: {e}")
            return f"Маршрут из {len(pois)} мест, начиная с {start_poi}"

    def extract_entities(self, text: str) -> dict:
        if not self.enabled:
            return {"text": text}

        system_prompt = "Извлекай сущности из текста и возвращай JSON."
        user_prompt = f"""Извлеки сущности из русского текста о достопримечательностях:
"{text}"

Верни JSON с ключами: location, person, date, action.
Если не найдено — null."""

        try:
            extracted = self._call_yandexgpt(system_prompt, user_prompt, max_tokens=200)
            return {"extracted": extracted}
        except Exception as e:
            print(f"Error extracting entities: {e}")
            return {"text": text}
