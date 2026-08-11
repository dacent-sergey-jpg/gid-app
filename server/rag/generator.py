"""
LLM Generator component for RAG system
Интеграция с Claude API (Anthropic)
"""

import anthropic
from typing import Optional, List
from config import CLAUDE_API_KEY
import re


class LLMGenerator:
    """Generator component using Claude API"""
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Claude API client
        
        Args:
            api_key: Claude API key (uses CLAUDE_API_KEY from env if not provided)
        """
        self.api_key = api_key or CLAUDE_API_KEY
        
        if not self.api_key:
            print("⚠️ Warning: CLAUDE_API_KEY not set. LLM features will be disabled.")
            self.client = None
            return
        
        try:
            self.client = anthropic.Anthropic(api_key=self.api_key)
            print("✅ Claude API initialized")
        except Exception as e:
            print(f"❌ Error initializing Claude: {e}")
            self.client = None
    
    def generate_answer(
        self,
        context: str,
        user_question: str,
        language: str = "russian",
        max_tokens: int = 500
    ) -> str:
        """
        Generate answer to user question using Claude.
        
        Параметры ТЗ раздел 11 (Ответ гида):
        - Использует верифицированные факты (RAG context)
        - Ответ на русском языке
        - Дополнительная информация от LLM
        
        Args:
            context: RAG context with verified facts
            user_question: User's question
            language: Response language (default: russian)
            max_tokens: Maximum tokens in response
            
        Returns:
            Generated answer from Claude
        """
        
        if self.client is None:
            # Fallback: return context-based answer
            return self._fallback_answer(context, user_question)
        
        # Build prompt with context and instructions
        prompt = self._build_prompt(context, user_question, language)
        
        try:
            response = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=max_tokens,
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.7
            )
            
            answer = response.content[0].text
            return answer.strip()
            
        except Exception as e:
            print(f"❌ Error calling Claude: {e}")
            return self._fallback_answer(context, user_question)
    
    def _build_prompt(
        self,
        context: str,
        user_question: str,
        language: str
    ) -> str:
        """Build prompt for Claude"""
        
        return f"""You are a helpful audio guide (гид) for tourists in Russia. 
Your role is to answer questions about historical landmarks and cultural sites.

Important instructions:
1. Use ONLY the verified facts provided in the context below
2. Answer in {language.upper()}
3. Be friendly and engaging, as if speaking to a tourist
4. Keep answer concise (2-3 sentences)
5. Do NOT invent facts not in the context

VERIFIED CONTEXT:
{context}

USER QUESTION: {user_question}

ANSWER:"""
    
    def _fallback_answer(self, context: str, user_question: str) -> str:
        """Fallback answer when Claude API is unavailable"""
        
        # Extract facts from context
        facts_section = context.split("Интересные факты:")[1] if "Интересные факты:" in context else ""
        
        # Build simple answer from facts
        answer = f"Относительно вашего вопроса '{user_question}': "
        
        if "Построен" in context:
            year_match = re.search(r'Построен/основан: (\d+)', context)
            if year_match:
                answer += f"Это произошло в {year_match.group(1)} году. "
        
        if facts_section.strip():
            answer += "Вот несколько интересных фактов: " + facts_section.split("\n")[1]
        else:
            answer += "Извините, но я не имею достаточно информации для полного ответа."
        
        return answer.strip()
    
    def generate_route_description(
        self,
        pois: List[dict],
        start_poi: str
    ) -> str:
        """
        Generate a description of a tourist route.
        
        Args:
            pois: List of POI with titles and descriptions
            start_poi: Starting POI title
            
        Returns:
            Generated route description
        """
        
        if self.client is None:
            return "Route information not available"
        
        poi_list = "\n".join([f"- {poi['title']}: {poi['description'][:100]}" for poi in pois])
        
        prompt = f"""You are creating a tourist audio guide route description.
Create an engaging route description starting from {start_poi} that connects these points of interest:

{poi_list}

Generate a brief, engaging route description (2-3 sentences) in Russian that makes tourists excited to visit these places."""
        
        try:
            response = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}]
            )
            
            return response.content[0].text.strip()
            
        except Exception as e:
            print(f"Error generating route: {e}")
            return f"Visit {len(pois)} interesting places starting from {start_poi}"
    
    def extract_entities(self, text: str) -> dict:
        """
        Extract entities (places, dates, etc.) from user text.
        
        Args:
            text: User input text
            
        Returns:
            Dictionary with extracted entities
        """
        
        if self.client is None:
            return {"text": text}
        
        prompt = f"""Extract entities from this Russian text about landmarks:
"{text}"

Return JSON with keys: location, person, date, action
If not found, use null."""
        
        try:
            response = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=200,
                messages=[{"role": "user", "content": prompt}]
            )
            
            # Parse response (simplified)
            return {"extracted": response.content[0].text}
            
        except Exception as e:
            print(f"Error extracting entities: {e}")
            return {"text": text}
