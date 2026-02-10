import numpy as np
import spacy
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
from typing import Dict, Any, List
from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.corpus import stopwords
from collections import Counter
import nltk
from nltk.tokenize import word_tokenize
import traceback

# Try to load sentence-transformers
try:
    from sentence_transformers import SentenceTransformer, util
    model = SentenceTransformer('all-MiniLM-L6-v2')
    TRANSFORMER_AVAILABLE = True
except ImportError:
    TRANSFORMER_AVAILABLE = False

# Load spaCy
try:
    nlp = spacy.load('en_core_web_sm')
except:
    import subprocess
    subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
    nlp = spacy.load('en_core_web_sm')


class TopicRelevanceAnalyzer:
    """Analyzer for topic relevance and focus"""
    
    def __init__(self):
        self.nlp = nlp
    
    async def analyze(self, text: str, topic: str) -> dict:
        """
        Analyze topic relevance
        
        Args:
            text: Transcribed speech text
            topic: The assigned topic
            
        Returns:
            dict with topic relevance analysis
        """
        try:
            # Preprocess
            speech_text = self._preprocess_text(text)
            topic_text = self._preprocess_text(topic)
            
            if not speech_text or not topic_text:
                return {
                    'topic_relevance_score': 50,
                    'similarity': 0.5,
                    'key_speech_topics': [],
                    'feedback': ["Unable to analyze topic relevance due to empty text."]
                }
            
            # Extract key topics
            key_speech_topics = self._extract_key_topics(speech_text)
            
            # Calculate similarity
            transformer_similarity = self._calculate_similarity_transformer(speech_text, topic_text)
            
            if transformer_similarity is not None:
                similarity = transformer_similarity
            else:
                similarity = self._calculate_similarity_tfidf(speech_text, topic_text)
            
            similarity = max(0, min(1, similarity))
            relevance_score = int(similarity * 100)
            
            # Generate feedback
            feedback = self._generate_topic_feedback(similarity, key_speech_topics, topic)
            
            return {
                'topic_relevance_score': relevance_score,
                'similarity': round(similarity, 2),
                'key_speech_topics': key_speech_topics,
                'feedback': feedback
            }
            
        except Exception as e:
            print(f"Error analyzing topic relevance: {e}")
            traceback.print_exc()
            return {
                'topic_relevance_score': 50,
                'similarity': 0.5,
                'key_speech_topics': [],
                'feedback': ["Unable to fully analyze topic relevance."]
            }
    
    def _preprocess_text(self, text):
        """Clean and preprocess text"""
        if isinstance(text, dict):
            text = text.get('text', '')
        
        text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)
        text = re.sub(r'\b(um|uh|ah|er|hmm)\b', '', text.lower())
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    def _extract_key_topics(self, text, n=10):
        """Extract key topics from speech"""
        doc = self.nlp(text)
        key_phrases = []
        
        # Noun phrases
        for chunk in doc.noun_chunks:
            if not all(token.is_stop for token in chunk):
                key_phrases.append(chunk.text.lower())
        
        # Named entities
        for ent in doc.ents:
            key_phrases.append(ent.text)
        
        # Common words if needed
        if len(key_phrases) < n:
            stop_words = set(stopwords.words('english'))
            words = [token.text.lower() for token in doc
                     if token.is_alpha and token.text.lower() not in stop_words
                     and len(token.text) > 2]
            
            word_freq = Counter(words)
            common_words = [word for word, _ in word_freq.most_common(n)]
            key_phrases.extend(common_words)
        
        return list(set(key_phrases))[:n]
    
    def _calculate_similarity_transformer(self, text1, text2):
        """Calculate similarity using transformers"""
        if not TRANSFORMER_AVAILABLE:
            return None
        
        try:
            embedding1 = model.encode(text1, convert_to_tensor=True)
            embedding2 = model.encode(text2, convert_to_tensor=True)
            similarity = util.pytorch_cos_sim(embedding1, embedding2).item()
            return similarity
        except Exception as e:
            print(f"Error in transformer similarity: {e}")
            return None
    
    def _calculate_similarity_tfidf(self, text1, text2):
        """Calculate similarity using TF-IDF"""
        try:
            vectorizer = TfidfVectorizer()
            tfidf_matrix = vectorizer.fit_transform([text1, text2])
            similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
            return similarity
        except Exception as e:
            print(f"Error in TF-IDF similarity: {e}")
            return 0.5
    
    def _generate_topic_feedback(self, score, key_speech_topics, topic):
        """Generate feedback"""
        feedback = []
        
        if score >= 0.9:
            feedback.append(f"Excellent topic relevance! Your speech is strongly focused on '{topic}'.")
        elif score >= 0.75:
            feedback.append(f"Good topic relevance. Your speech stays on topic with '{topic}'.")
        elif score >= 0.6:
            feedback.append(f"Moderate topic relevance. Your speech somewhat relates to '{topic}' but could be more focused.")
        elif score >= 0.4:
            feedback.append(f"Limited topic relevance. Your speech touches on '{topic}' but frequently deviates from it.")
        else:
            feedback.append(f"Poor topic relevance. Your speech doesn't adequately address '{topic}'.")
        
        if score < 0.7:
            feedback.append("Try to make stronger connections to the main topic throughout your speech.")
        
        if key_speech_topics and len(key_speech_topics) > 0:
            if score < 0.5:
                feedback.append(f"Your speech focused more on {', '.join(key_speech_topics[:3])} than the assigned topic.")
            elif score >= 0.7:
                feedback.append(f"You effectively covered key aspects: {', '.join(key_speech_topics[:3])}.")
        
        return feedback