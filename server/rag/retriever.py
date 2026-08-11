"""
RAG (Retrieval-Augmented Generation) система для GID
Компонент: Retrieval - поиск релевантных фактов из БД
"""

from typing import List, Dict, Tuple
from sqlalchemy.orm import Session
from models.poi import POI
from sentence_transformers import SentenceTransformer
import numpy as np


class RAGRetriever:
    """Retriever component for RAG system"""
    
    def __init__(self, model_name: str = "sentence-transformers/multilingual-MiniLM-L12-v2"):
        """
        Initialize retriever with semantic search model
        
        Args:
            model_name: Hugging Face model for embeddings
        """
        try:
            self.model = SentenceTransformer(model_name)
            print(f"✅ Loaded embedding model: {model_name}")
        except Exception as e:
            print(f"⚠️ Warning: Could not load embedding model: {e}")
            print("   Using fallback: keyword-based retrieval")
            self.model = None
    
    def retrieve_facts(
        self, 
        poi: POI, 
        user_question: str,
        top_k: int = 3
    ) -> List[str]:
        """
        Retrieve most relevant facts from POI using semantic search.
        
        Параметры ТЗ раздел 10 (Верифицированные факты):
        - Все факты в БД уже проверены
        - Система выбирает наиболее релевантные к вопросу
        
        Args:
            poi: POI object from database
            user_question: User's question
            top_k: Number of facts to retrieve
            
        Returns:
            List of most relevant facts
        """
        
        if not poi.facts or len(poi.facts) == 0:
            return []
        
        # If no embedding model, return all facts
        if self.model is None:
            return poi.facts[:top_k]
        
        try:
            # Encode question and facts
            question_embedding = self.model.encode(user_question, convert_to_tensor=True)
            fact_embeddings = self.model.encode(poi.facts, convert_to_tensor=True)
            
            # Calculate cosine similarities
            from sentence_transformers.util import cos_sim
            similarities = cos_sim(question_embedding, fact_embeddings)[0]
            
            # Get top-k facts by relevance
            top_indices = np.argsort(similarities.cpu().detach().numpy())[-top_k:][::-1]
            relevant_facts = [poi.facts[i] for i in top_indices]
            
            return relevant_facts
            
        except Exception as e:
            print(f"⚠️ Embedding error: {e}, returning all facts")
            return poi.facts[:top_k]
    
    def build_context(self, poi: POI, user_question: str) -> str:
        """
        Build context string from POI data for LLM.
        
        Includes:
        - POI title and description
        - Most relevant facts
        - Historical information
        - Category information
        
        Args:
            poi: POI object
            user_question: User's question
            
        Returns:
            Context string for LLM prompt
        """
        
        # Get relevant facts using semantic search
        relevant_facts = self.retrieve_facts(poi, user_question, top_k=3)
        
        # Build context
        context = f"""
Название объекта: {poi.title}
Категория: {poi.category}
Описание: {poi.description}

Исторические данные:
- Построен/основан: {poi.built_year if poi.built_year else 'Неизвестно'}
- Исторический период: {poi.historical_period if poi.historical_period else 'Неизвестно'}

Интересные факты:
"""
        for i, fact in enumerate(relevant_facts, 1):
            context += f"{i}. {fact}\n"
        
        context += f"""
Приоритет (интересность): {poi.priority}/10
Количество посещений: {poi.times_visited}
"""
        
        return context.strip()
    
    def retrieve_similar_pois(
        self,
        db: Session,
        current_poi: POI,
        top_k: int = 3
    ) -> List[POI]:
        """
        Retrieve similar POI based on description embeddings.
        
        Args:
            db: Database session
            current_poi: Current POI
            top_k: Number of similar POI to return
            
        Returns:
            List of similar POI objects
        """
        
        if self.model is None:
            # Fallback: return same category
            similar = db.query(POI).filter(
                POI.category == current_poi.category,
                POI.id != current_poi.id,
                POI.is_active == True
            ).limit(top_k).all()
            return similar
        
        try:
            # Get all active POI
            all_pois = db.query(POI).filter(
                POI.is_active == True,
                POI.id != current_poi.id
            ).all()
            
            if not all_pois:
                return []
            
            # Encode descriptions
            current_embedding = self.model.encode(
                current_poi.description, 
                convert_to_tensor=True
            )
            other_embeddings = self.model.encode(
                [poi.description for poi in all_pois],
                convert_to_tensor=True
            )
            
            # Calculate similarities
            from sentence_transformers.util import cos_sim
            similarities = cos_sim(current_embedding, other_embeddings)[0]
            
            # Get top-k similar
            top_indices = np.argsort(similarities.cpu().detach().numpy())[-top_k:][::-1]
            similar_pois = [all_pois[i] for i in top_indices]
            
            return similar_pois
            
        except Exception as e:
            print(f"⚠️ Similarity error: {e}")
            return []
