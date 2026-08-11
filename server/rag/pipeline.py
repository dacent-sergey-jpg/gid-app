"""
RAG Pipeline - orchestrates retrieval and generation
"""

from sqlalchemy.orm import Session
from models.poi import POI
from rag.retriever import RAGRetriever
from rag.generator import LLMGenerator
from typing import Optional, Dict


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
    ) -> Dict[str, str]:
        """
        Full RAG pipeline: retrieve context and generate answer.
        
        Pipeline steps:
        1. Retrieve POI from database
        2. Get relevant facts using semantic search
        3. Build context
        4. Generate answer using Claude
        5. Optional: Get similar POI recommendations
        
        Args:
            db: Database session
            poi_id: ID of POI
            user_question: User's question
            include_recommendations: Whether to include similar POI
            
        Returns:
            Dictionary with answer and metadata
        """
        
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
        
        # Step 3: Generate answer using Claude
        answer = self.generator.generate_answer(
            context=context,
            user_question=user_question
        )
        
        # Step 4: Optional recommendations
        recommendations = []
        if include_recommendations:
            similar_pois = self.retriever.retrieve_similar_pois(db, poi, top_k=2)
            recommendations = [
                {
                    "id": p.id,
                    "title": p.title,
                    "category": p.category
                }
                for p in similar_pois
            ]
        
        # Update visit count
        poi.times_visited += 1
        db.commit()
        
        return {
            "status": "success",
            "answer": answer,
            "poi_title": poi.title,
            "poi_id": poi.id,
            "context_facts": len(self.retriever.retrieve_facts(poi, user_question)),
            "recommendations": recommendations
        }
    
    def generate_guide_intro(
        self,
        db: Session,
        poi_id: int
    ) -> str:
        """
        Generate an engaging introduction for a POI.
        
        Args:
            db: Database session
            poi_id: POI ID
            
        Returns:
            Generated introduction text
        """
        
        poi = db.query(POI).filter(POI.id == poi_id).first()
        if not poi:
            return ""
        
        context = f"""
Название: {poi.title}
Описание: {poi.description}
Категория: {poi.category}
Периоду: {poi.historical_period}
"""
        
        intro = self.generator.generate_answer(
            context=context,
            user_question="Дай краткую интересную справку об этом месте",
            max_tokens=200
        )
        
        return intro
    
    def batch_generate_descriptions(
        self,
        db: Session,
        poi_ids: list
    ) -> Dict[int, str]:
        """
        Generate descriptions for multiple POI.
        
        Args:
            db: Database session
            poi_ids: List of POI IDs
            
        Returns:
            Dictionary mapping POI ID to description
        """
        
        descriptions = {}
        for poi_id in poi_ids:
            intro = self.generate_guide_intro(db, poi_id)
            descriptions[poi_id] = intro
        
        return descriptions
