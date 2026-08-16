"""
RAG Pipeline - orchestrates retrieval and generation
"""

from sqlalchemy.orm import Session
from models.poi import POI
from rag.retriever import RAGRetriever
from rag.generator import LLMGenerator
from typing import Optional, Dict, List


class RAGPipeline:
    """Full RAG pipeline combining retriever and generator"""
    
    def __init__(self):
        """Initialize RAG components"""
        self.retriever = RAGRetriever()
        self.generator = LLMGenerator()
        print("✅ RAG Pipeline initialized")
    
    def answer_question(
        self,
        db: Session,
        poi_id: int,
        user_question: str,
        include_recommendations: bool = False
    ) -> Dict[str, Optional[str]]:
        """
        Full RAG pipeline: retrieve context and generate answer.
        """
        try:
            # Step 1: Get POI from database
            poi = db.query(POI).filter(POI.id == poi_id).first()
            if not poi:
                return {
                    "status": "error",
                    "message": "POI not found",
                    "answer": None
                }
            
            # Step 2: Build context with relevant facts
            context = self.retriever.build_context(poi, user_question)
            
            # Step 3: Generate answer using LLM
            answer = self.generator.generate_answer(
                context=context,
                user_question=user_question
            )
            
            # Step 4: Optional recommendations
            recommendations = []
            if include_recommendations:
                try:
                    similar_pois = self.retriever.retrieve_similar_pois(db, poi, top_k=2)
                    recommendations = [
                        {
                            "id": p.id,
                            "title": p.title,
                            "category": p.category
                        }
                        for p in similar_pois
                    ]
                except Exception as rec_err:
                    print(f"⚠️ Failed to retrieve recommendations: {rec_err}")
            
            # Safe facts counting
            facts_list = self.retriever.retrieve_facts(poi, user_question) or []
            
            # Update visit count with transaction safety
            try:
                poi.times_visited = (poi.times_visited or 0) + 1
                db.commit()
            except Exception as db_err:
                db.rollback()
                print(f"⚠️ Failed to update visit stats: {db_err}")
            
            return {
                "status": "success",
                "answer": answer,
                "poi_title": poi.title,
                "poi_id": poi.id,
                "context_facts": len(facts_list),
                "recommendations": recommendations
            }

        except Exception as e:
            db.rollback()
            print(f"❌ RAG Pipeline Error: {e}")
            return {
                "status": "error",
                "message": f"Pipeline internal error: {str(e)}",
                "answer": "Извините, временно не могу обработать ваш запрос."
            }
    
    def generate_guide_intro(
        self,
        db: Session,
        poi_id: int
    ) -> str:
        """
        Generate an engaging introduction for a POI.
        """
        try:
            poi = db.query(POI).filter(POI.id == poi_id).first()
            if not poi:
                return ""
            
            context = f"""
Название: {poi.title}
Описание: {poi.description or 'Описание отсутствует'}
Категория: {poi.category or 'Общее'}
Исторический период: {poi.historical_period or 'Не указан'}
"""
            
            intro = self.generator.generate_answer(
                context=context,
                user_question="Дай краткую интересную справку об этом месте",
                max_tokens=200
            )
            
            return intro
        except Exception as e:
            print(f"❌ Error generating guide intro: {e}")
            return ""
    
    def batch_generate_descriptions(
        self,
        db: Session,
        poi_ids: List[int]
    ) -> Dict[int, str]:
        """
        Generate descriptions for multiple POI safely.
        """
        descriptions = {}
        for poi_id in poi_ids:
            try:
                intro = self.generate_guide_intro(db, poi_id)
                descriptions[poi_id] = intro
            except Exception as e:
                print(f"⚠️ Error processing batch item {poi_id}: {e}")
                descriptions[poi_id] = ""
        
        return descriptions
