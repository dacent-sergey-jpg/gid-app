import os
from sqlalchemy.orm import Session
from models import POI, GeneratedStory
from schemas import StoryGenerateRequest, StoryResponse


class RAGTSService:
    @staticmethod
    def generate_story_for_poi(db: Session, req: StoryGenerateRequest) -> StoryResponse:
        # 1. Проверяем кэш сгенерированных историй
        cached_story = (
            db.query(GeneratedStory)
            .filter(
                GeneratedStory.poi_id == req.poi_id,
                GeneratedStory.style == req.style,
                GeneratedStory.voice == req.voice
            )
            .first()
        )

        poi = db.query(POI).filter(POI.id == req.poi_id).first()
        if not poi:
            raise ValueError(f"Объект с ID {req.poi_id} не найден")

        if cached_story:
            return StoryResponse(
                poi_id=poi.id,
                poi_name=poi.name,
                story_text=cached_story.story_text,
                audio_url=cached_story.audio_url,
                style=cached_story.style,
                voice=cached_story.voice
            )

        # 2. Формируем текст экскурсии на основе фактов и описания (RAG)
        facts_summary = "\n".join([f"- {fact}" for fact in (poi.facts or [])])
        legends_summary = "\n".join([f"- {legend}" for legend in (poi.legends or [])])

        generated_text = (
            f"Вы находитесь рядом с замечательным местом: {poi.name}. "
            f"Оно относится к категории {poi.category}. {poi.description or ''} "
        )
        if poi.built_period:
            generated_text += f"Период постройки: {poi.built_period}. "
        if facts_summary:
            generated_text += f"\nИнтересные факты:\n{facts_summary}"
        if req.style == "legends" and legends_summary:
            generated_text += f"\nС этим местом связаны следующие легенды:\n{legends_summary}"

        # 3. Сохраняем результат в кэш
        new_story = GeneratedStory(
            poi_id=poi.id,
            style=req.style,
            voice=req.voice,
            story_text=generated_text,
            audio_url=None,  # Здесь будет генерироваться URL аудиофайла TTS
            duration_seconds=45.0
        )
        db.add(new_story)
        db.commit()

        return StoryResponse(
            poi_id=poi.id,
            poi_name=poi.name,
            story_text=generated_text,
            audio_url=None,
            style=req.style,
            voice=req.voice
        )
