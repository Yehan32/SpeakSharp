"""
Topic Relevance Analyzer - Evaluates speech relevance to given topic
"""
import re
from typing import Dict, Any, List
from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.corpus import stopwords
from collections import Counter

class TopicRelevanceAnalyzer:
    def __init__(self):
        try:
            self.stop_words = set(stopwords.words('english'))
        except:
            import nltk
            nltk.download('stopwords')
            self.stop_words = set(stopwords.words('english'))
    
    async def analyze(self, text: str, topic: str = None) -> Dict[str, Any]:
        """
        Analyze topic relevance
        
        Args:
            text: Speech transcription
            topic: Expected topic/title
        
        Returns:
            Dict with relevance scores and feedback
        """
        if not topic:
            return {
                'relevance_score': 15.0,
                'keyword_matches': 0,
                'focus_score': 15.0,
                'feedback': ["No topic specified for comparison"],
                'rating': 'N/A'
            }
        
        try:
            # Clean text
            clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', text).lower()
            clean_topic = topic.lower()
            
            # Extract keywords from topic
            topic_keywords = self._extract_keywords(clean_topic)
            
            # Count topic keyword occurrences in speech
            keyword_matches = self._count_keyword_matches(clean_text, topic_keywords)
            
            # Calculate focus score (how consistently topic is maintained)
            focus_score = self._calculate_focus_score(clean_text, topic_keywords)
            
            # Calculate overall relevance score (0-20)
            relevance_score = (keyword_matches * 10 + focus_score) / 2
            relevance_score = min(20, relevance_score)
            
            # Generate feedback
            feedback = self._generate_feedback(keyword_matches, focus_score, topic)
            
            return {
                'relevance_score': round(relevance_score, 1),
                'keyword_matches': keyword_matches,
                'focus_score': round(focus_score, 1),
                'topic_keywords': list(topic_keywords),
                'feedback': feedback,
                'rating': self._get_rating(relevance_score)
            }
            
        except Exception as e:
            print(f"Topic relevance analysis error: {e}")
            return {
                'relevance_score': 10.0,
                'keyword_matches': 0,
                'focus_score': 10.0,
                'feedback': ["Could not analyze topic relevance"],
                'rating': 'Unknown'
            }
    
    def _extract_keywords(self, topic: str) -> set:
        """Extract meaningful keywords from topic"""
        words = word_tokenize(topic)
        keywords = {word for word in words 
                   if word.isalpha() and 
                   word not in self.stop_words and 
                   len(word) > 3}
        return keywords
    
    def _count_keyword_matches(self, text: str, keywords: set) -> int:
        """Count how many topic keywords appear in speech"""
        words = word_tokenize(text)
        matches = sum(1 for word in words if word in keywords)
        return min(10, matches)  # Cap at 10
    
    def _calculate_focus_score(self, text: str, keywords: set) -> float:
        """Calculate how consistently topic is maintained throughout"""
        sentences = sent_tokenize(text)
        if not sentences:
            return 10.0
        
        sentences_with_keywords = 0
        for sentence in sentences:
            sentence_words = word_tokenize(sentence.lower())
            if any(word in keywords for word in sentence_words):
                sentences_with_keywords += 1
        
        focus_percentage = (sentences_with_keywords / len(sentences)) * 100
        return min(20, (focus_percentage / 100) * 20)
    
    def _generate_feedback(self, keyword_matches: int, focus_score: float, topic: str) -> List[str]:
        """Generate topic relevance feedback"""
        feedback = []
        
        if keyword_matches < 3:
            feedback.append(f"Include more references to '{topic}' throughout your speech")
        elif keyword_matches > 7:
            feedback.append(f"Excellent focus on the topic '{topic}'")
        
        if focus_score < 10:
            feedback.append("Try to maintain consistent focus on your main topic")
        elif focus_score > 15:
            feedback.append("Great consistency in staying on topic!")
        
        if not feedback:
            feedback.append("Good topic relevance")
        
        return feedback
    
    def _get_rating(self, score: float) -> str:
        """Get rating based on relevance score"""
        if score >= 16:
            return "Highly Relevant"
        elif score >= 12:
            return "Relevant"
        elif score >= 8:
            return "Moderately Relevant"
        else:
            return "Needs Focus"