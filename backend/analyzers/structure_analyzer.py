import nltk
import spacy
from nltk.tokenize import word_tokenize

class StructureAnalyzer:
    """Analyzer for speech structure and effectiveness"""
    
    def __init__(self):
        self.purpose_indicators = [
            "purpose", "goal", "aim", "objective", "today", "discuss",
            "explain", "demonstrate", "show", "present", "introduce"
        ]
        self.conclusion_indicators = [
            "conclusion", "finally", "in summary", "to sum up", "therefore",
            "thus", "consequently", "in closing", "lastly"
        ]
        self.transition_words = ["however", "moreover", "furthermore", "additionally", "therefore", "thus"]
    
    async def analyze(self, text: str, nlp_model) -> dict:
        """
        Analyze speech structure and effectiveness
        
        Args:
            text: Transcribed text
            nlp_model: spaCy NLP model
            
        Returns:
            dict with structure analysis
        """
        if isinstance(text, dict):
            text = text.get('text', '')
        
        try:
            # Basic structure analysis
            effectiveness_result = self._analyze_effectiveness(text)
            
            # Detailed structure analysis with NLP
            structure_result = self._analyze_structure(text, nlp_model)
            
            # Combine results
            return {
                **effectiveness_result,
                **structure_result,
                'structure_score': effectiveness_result['effectiveness_score'],
                'feedback': effectiveness_result['feedback'] + structure_result.get('feedback', [])
            }
            
        except Exception as e:
            print(f"Error in speech structure analysis: {e}")
            return {
                'structure_score': 50,
                'feedback': ["Unable to fully analyze speech structure."]
            }
    
    def _analyze_effectiveness(self, text):
        """Analyze speech effectiveness"""
        try:
            words = word_tokenize(text.lower())
            first_50_words = ' '.join(words[:50])
            last_50_words = ' '.join(words[-50:])
            
            # Check for clear purpose
            has_clear_purpose = any(indicator in first_50_words for indicator in self.purpose_indicators)
            
            # Check for conclusion
            has_conclusion = any(indicator in last_50_words for indicator in self.conclusion_indicators)
            
            # Calculate sentence length
            sentences = nltk.sent_tokenize(text)
            if sentences:
                avg_sentence_length = sum(len(word_tokenize(sentence)) for sentence in sentences) / len(sentences)
            else:
                avg_sentence_length = 0
            
            # Calculate score and feedback
            effectiveness_score = 0
            feedback = []
            
            if has_clear_purpose:
                effectiveness_score += 30
                feedback.append("Clear purpose statement identified in the introduction.")
            else:
                feedback.append("Consider adding a clear purpose statement at the beginning.")
            
            if 10 <= avg_sentence_length <= 20:
                effectiveness_score += 20
                feedback.append("Good sentence length variation for clarity.")
            else:
                feedback.append("Consider varying sentence lengths for better flow.")
            
            if has_conclusion:
                effectiveness_score += 20
                feedback.append("Clear conclusion identified.")
            else:
                feedback.append("Consider adding a strong concluding statement.")
            
            # Count transition words
            transition_count = sum(1 for word in words if word.lower() in self.transition_words)
            
            if transition_count >= 3:
                effectiveness_score += 30
                feedback.append("Good use of transition words for coherence.")
            else:
                feedback.append("Consider using more transition words to improve flow.")
            
            return {
                'effectiveness_score': effectiveness_score,
                'purpose_clarity': has_clear_purpose,
                'has_conclusion': has_conclusion,
                'avg_sentence_length': round(avg_sentence_length, 2),
                'feedback': feedback
            }
            
        except Exception as e:
            print(f"Error in effectiveness analysis: {e}")
            return {
                'effectiveness_score': 50,
                'feedback': ["Unable to analyze speech effectiveness."]
            }
    
    def _analyze_structure(self, text, nlp_model):
        """Analyze speech structure with NLP"""
        try:
            doc = nlp_model(text)
            sentences = list(doc.sents)
            num_sentences = len(sentences)
            
            if num_sentences > 0:
                sentence_lengths = [len(sentence) for sentence in sentences]
                avg_sentence_length = sum(sentence_lengths) / num_sentences
            else:
                avg_sentence_length = 0
            
            paragraphs = [sent.text for sent in doc.sents if sent.text.strip()]
            
            # Count transitions
            transitions = ["however", "moreover", "thus", "therefore", "in addition"]
            transition_count = sum(1 for token in doc if token.text.lower() in transitions)
            
            # Check for introduction/conclusion keywords
            introduction_keywords = ["introduction", "begin", "start"]
            conclusion_keywords = ["conclusion", "end", "summary"]
            introduction_present = any(keyword in text.lower() for keyword in introduction_keywords)
            conclusion_present = any(keyword in text.lower() for keyword in conclusion_keywords)
            
            structure_score = 0
            structure_feedback = []
            
            if introduction_present:
                structure_score += 30
                structure_feedback.append("Clear introduction detected.")
            else:
                structure_feedback.append("Consider adding a clear introduction.")
            
            if conclusion_present:
                structure_score += 30
                structure_feedback.append("Clear conclusion detected.")
            else:
                structure_feedback.append("Consider adding a clear conclusion.")
            
            if transition_count >= 3:
                structure_score += 20
                structure_feedback.append("Effective use of transitions detected.")
            else:
                structure_feedback.append("Consider adding more transitions for coherence.")
            
            return {
                'structure_score': structure_score,
                'avg_sentence_length': round(avg_sentence_length, 2),
                'num_paragraphs': len(paragraphs),
                'feedback': structure_feedback
            }
            
        except Exception as e:
            print(f"Error in structure NLP analysis: {e}")
            return {
                'structure_score': 50,
                'feedback': []
            }