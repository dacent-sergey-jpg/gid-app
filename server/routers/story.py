from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from schemas import StoryGenerateRequest, StoryResponse
from services.rag_tts_service import RAGTSService
from database import get_db

router = APIRouter(prefix="/api/v1/story", tags=["RAG & TTS Story Generator"])


@router.post("/generate", response_model=StoryResponse)
def generate_story(
    request: StoryGenerateRequest,
    db: Session = Depends(get_db)
):
    try:
        story = RAGTSService.generate_story_for_poi(db=db, req=request)
        return story
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка генерации истории: {str(e)}")
