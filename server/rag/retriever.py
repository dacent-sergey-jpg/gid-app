"""
RAG (Retrieval-Augmented Generation) система для GID
Компонент: Retrieval - поиск релевантных фактов из БД
"""

from typing import List
import numpy as np
from sqlalchemy.orm import Session
from models.poi import POI

try:
    from sentence_transformers import SentenceTransformer
    from sentence_transformers.util import cos_sim
    HAS_TRANSFORMERS = True
except ImportError:
    HAS_TRANSFORMERS = False


class RAGRetriever:
    """Retriever component for RAG system"""

    def __init__(self, model_name: str = "sentence-transformers/multilingual-MiniLM-L12-v2"):
        """Initialize retriever with semantic search model"""
        self.model = None
        if HAS_TRANSFORMERS:
            try:
                self.model = SentenceTransformer(model_name)
                print(f"✅ Loaded embedding model: {model_name}")
            except Exception as e:
                print(f"⚠️ Warning: Could not load embedding model ({e}). Using fallback retrieval.")
        else:
            print("⚠️ sentence-transformers not installed. Using fallback retrieval.")

    def retrieve_facts(
        self, 
        poi: POI, 
        user_question: str, 
        top_k: int = 3
    ) -> List[str]:
        """Retrieve most relevant facts from POI using semantic search."""
        # Гарантируем, что facts — это валидный список непустых строк
        raw_facts = poi.facts if isinstance(poi.facts, list) else []
        facts = [str(f) for f in raw_facts if f and str(f).strip()]

        if not facts:
            return []

        k = min(top_k, len(facts))

        # Fallback при отсутствии модели или пустом вопросе
        if self.model is None or not user_question or not user_question.strip():
            return facts[:k]

        try:
            question_embedding = self.model.encode(user_question, convert_to_tensor=True)
            fact_embeddings = self.model.encode(facts, convert_to_tensor=True)

            similarities = cos_sim(question_embedding, fact_embeddings)[0]
            sim_scores = similarities.cpu().detach().numpy()
            
            top_indices = np.argsort(sim_scores)[-k:][::-1]
            return [facts[i] for i in top_indices]

        except Exception as e:
            print(f"⚠️ Embedding error: {e}, returning fallback facts")
            return facts[:k]

    def build_context(self, poi: POI, user_question: str) -> str:
        """Build context string from POI data for LLM."""
        relevant_facts = self.retrieve_facts(poi, user_question, top_k=3)

        title = poi.title or "Неизвестный объект"
        category = poi.category or "Общее"
        description = poi.description or "Описание отсутствует"
        built_year = poi.built_year if poi.built_year else "Неизвестно"
        historical_period = poi.historical_period if poi.historical_period else "Неизвестно"

        facts_text = ""
        if relevant_facts:
            for i, fact in enumerate(relevant_facts, 1):
                facts_text += f"{i}. {fact}\n"
        else:
            facts_text = "Дополнительные факты отсутствуют.\n"

        context = f"""
Название объекта: {title}
Категория: {category}
Описание: {description}

Исторические данные:
- Построен/основан: {built_year}
- Исторический период: {historical_period}

Интересные факты:
{facts_text}
Приоритет (интересность): {poi.priority or 5}/10
Количество посещений: {poi.times_visited or 0}
""".strip()

        return context

    def retrieve_similar_pois(
        self,
        db: Session,
        current_poi: POI,
        top_k: int = 3
    ) -> List[POI]:
        """Retrieve similar POI based on description embeddings."""
        if self.model is None:
            return db.query(POI).filter(
                POI.category == current_poi.category,
                POI.id != current_poi.id,
                POI.is_active == True
            ).limit(top_k).all()

        try:
            all_pois = db.query(POI).filter(
                POI.is_active == True,
                POI.id != current_poi.id
            ).all()

            if not all_pois:
                return []

            current_desc = current_poi.description or current_poi.title or ""
            if not current_desc.strip():
                return all_pois[:top_k]

            other_descs = [p.description or p.title or "" for p in all_pois]

            current_embedding = self.model.encode(current_desc, convert_to_tensor=True)
            other_embeddings = self.model.encode(other_descs, convert_to_tensor=True)

            similarities = cos_sim(current_embedding, other_embeddings)[0]
            sim_scores = similarities.cpu().detach().numpy()

            k = min(top_k, len(all_pois))
            top_indices = np.argsort(sim_scores)[-k:][::-1]

            return [all_pois[i] for i in top_indices]

        except Exception as e:
            print(f"⚠️ Similarity error: {e}")
            return []
