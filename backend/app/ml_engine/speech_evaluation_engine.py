"""
IMPROVED Speech Evaluation Engine
Properly calculates overall score from ALL analyzers
Includes better error handling and default values
"""

from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)


class SpeechEvaluationEngine:
    """
    Calculates final scores and generates feedback
    Properly weights all analyzer results
    """
    
    def __init__(self):
        logger.info("Evaluation engine initialized")
        
        # Score weights (total = 100)
        self.weights = {
            'voice_modulation': 0.20,  # 20%
            'grammar_vocabulary': 0.20,  # 20%
            'proficiency': 0.15,  # 15%
            'filler_words': 0.15,  # 15%
            'structure': 0.15,  # 15%
            'effectiveness': 0.15,  # 15%
        }
    
    async def evaluate(
        self,
        voice_results: Dict,
        content_results: Dict,
        transcription_results: Dict,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Calculate final scores from all analyzers
        
        Args:
            voice_results: Results from voice analysis engine
            content_results: Results from content analysis engine
            transcription_results: Transcription data
            **kwargs: Additional parameters
        
        Returns:
            Complete evaluation with scores and feedback
        """
        logger.info("🔢 Calculating comprehensive evaluation...")
        
        try:
            # Extract scores from each analyzer (with fallbacks)
            scores = self._extract_scores(voice_results, content_results)
            
            # Calculate weighted overall score
            overall_score = self._calculate_overall_score(scores)
            
            # Generate detailed feedback
            suggestions = self._generate_suggestions(scores, content_results)
            strengths = self._identify_strengths(scores, content_results)
            areas = self._identify_areas(scores, content_results)
            specific_tips = self._generate_specific_tips(scores)
            
            logger.info(f"✅ Evaluation complete: Overall score = {overall_score:.1f}")
            
            return {
                'overall_score': round(overall_score, 1),
                'score_breakdown': scores,
                'improvement_suggestions': suggestions,
                'strengths': strengths,
                'areas_for_improvement': areas,
                'specific_tips': specific_tips,
                'performance_level': self._get_performance_level(overall_score)
            }
        
        except Exception as e:
            logger.error(f"Evaluation failed: {e}", exc_info=True)
            # Return safe defaults
            return {
                'overall_score': 50.0,
                'score_breakdown': {
                    'voice_modulation': 50,
                    'grammar_vocabulary': 50,
                    'proficiency': 50,
                    'filler_words': 50,
                    'structure': 50,
                    'effectiveness': 50
                },
                'improvement_suggestions': ["Continue practicing to improve your speaking skills."],
                'strengths': ["Clear communication"],
                'areas_for_improvement': ["Keep practicing"],
                'specific_tips': [],
                'performance_level': 'Intermediate'
            }
    
    def _extract_scores(self, voice_results: Dict, content_results: Dict) -> Dict[str, float]:
        """Extract scores from all analyzers with safe fallbacks"""
        
        scores = {}
        
        # Voice Modulation Score (from voice analysis)
        voice_mod = voice_results.get('voice_modulation', {})
        scores['voice_modulation'] = voice_mod.get('total_score', 
                                     voice_mod.get('score', 50))
        
        # Grammar & Vocabulary Score (from content analysis)
        grammar_vocab = content_results.get('grammar_vocabulary', {})
        scores['grammar_vocabulary'] = grammar_vocab.get('overall_score',
                                       grammar_vocab.get('score', 50))
        
        # Proficiency Score (from content analysis)
        proficiency = content_results.get('proficiency', {})
        scores['proficiency'] = proficiency.get('overall_score',
                               proficiency.get('score', 50))
        
        # Filler Words Score (from content analysis)
        filler = content_results.get('filler_words', {})
        scores['filler_words'] = filler.get('score', 70)
        
        # Structure Score (from content analysis)
        structure = content_results.get('structure', {})
        scores['structure'] = structure.get('overall_score',
                             structure.get('score', 50))
        
        # Effectiveness Score (from content analysis)
        effectiveness = content_results.get('effectiveness', {})
        scores['effectiveness'] = effectiveness.get('overall_score',
                                  effectiveness.get('score', 50))
        
        # Log extracted scores for debugging
        logger.info(f"Extracted scores: {scores}")
        
        # Ensure all scores are valid numbers between 0-100
        for key, value in scores.items():
            if not isinstance(value, (int, float)) or value < 0:
                logger.warning(f"Invalid score for {key}: {value}, using default 50")
                scores[key] = 50
            elif value > 100:
                logger.warning(f"Score too high for {key}: {value}, capping at 100")
                scores[key] = 100
        
        return scores
    
    def calculate_overall_score(scores):
    """Calculate overall score (0-100) from category scores (0-20)"""
    category_scores = [
        scores.get('grammar', 0),
        scores.get('voice', 0),
        scores.get('structure', 0),
        scores.get('effectiveness', 0),
        scores.get('proficiency', 0)
    ]
    
    # Average of category scores (0-20)
    average = sum(category_scores) / len(category_scores)
    
    # Convert to 0-100 scale
    overall = (average / 20) * 100
    
    return round(overall, 1)
    
    def _generate_suggestions(self, scores: Dict, content_results: Dict) -> list:
        """Generate improvement suggestions based on scores"""
        suggestions = []
        
        # Check each category and provide specific suggestions
        
        # Voice Modulation
        if scores.get('voice_modulation', 50) < 60:
            suggestions.append("Practice varying your pitch and tone to make your speech more engaging.")
        
        # Grammar & Vocabulary
        if scores.get('grammar_vocabulary', 50) < 60:
            suggestions.append("Focus on using more diverse vocabulary and proper grammar structures.")
        
        # Filler Words
        filler_percentage = content_results.get('filler_words', {}).get('percentage', 0)
        if filler_percentage > 5:
            suggestions.append("Reduce filler words like 'um', 'uh', and 'like'. Practice pausing instead.")
        elif scores.get('filler_words', 70) >= 80:
            suggestions.append("Great job minimizing filler words! Keep it up.")
        
        # Structure
        if scores.get('structure', 50) < 60:
            suggestions.append("Work on organizing your speech with a clear introduction, body, and conclusion.")
        
        # Effectiveness
        if scores.get('effectiveness', 50) < 60:
            suggestions.append("Make your main message clearer and ensure all points support your goal.")
        
        # Proficiency
        if scores.get('proficiency', 50) < 60:
            suggestions.append("Practice speaking more fluently with fewer pauses and hesitations.")
        
        # If no specific suggestions, add generic positive one
        if not suggestions:
            suggestions.append("Excellent speech! Continue practicing to maintain your high performance.")
        
        return suggestions[:5]  # Return top 5 suggestions
    
    def _identify_strengths(self, scores: Dict, content_results: Dict) -> list:
        """Identify speech strengths based on high scores"""
        strengths = []
        
        # Check each category for high scores (>75)
        if scores.get('voice_modulation', 0) >= 75:
            strengths.append("Excellent voice modulation and pitch variation")
        
        if scores.get('grammar_vocabulary', 0) >= 75:
            strengths.append("Strong grammar and diverse vocabulary")
        
        if scores.get('proficiency', 0) >= 75:
            strengths.append("High speaking fluency and confidence")
        
        filler_percentage = content_results.get('filler_words', {}).get('percentage', 100)
        if filler_percentage < 3:
            strengths.append("Exceptional control over filler words")
        
        if scores.get('structure', 0) >= 75:
            strengths.append("Well-organized speech structure")
        
        if scores.get('effectiveness', 0) >= 75:
            strengths.append("Clear and impactful message delivery")
        
        # Default if no strong areas
        if not strengths:
            strengths.append("Clear communication and good effort")
        
        return strengths[:4]  # Return top 4 strengths
    
    def _identify_areas(self, scores: Dict, content_results: Dict) -> list:
        """Identify areas for improvement based on low scores"""
        areas = []
        
        # Check each category for low scores (<60)
        if scores.get('voice_modulation', 100) < 60:
            areas.append("Voice modulation and pitch variation")
        
        if scores.get('grammar_vocabulary', 100) < 60:
            areas.append("Grammar accuracy and vocabulary diversity")
        
        if scores.get('proficiency', 100) < 60:
            areas.append("Speaking fluency and confidence")
        
        filler_percentage = content_results.get('filler_words', {}).get('percentage', 0)
        if filler_percentage > 5:
            areas.append("Reducing filler word usage")
        
        if scores.get('structure', 100) < 60:
            areas.append("Speech organization and structure")
        
        if scores.get('effectiveness', 100) < 60:
            areas.append("Message clarity and impact")
        
        # Default if no weak areas
        if not areas:
            areas.append("Continue refining overall delivery")
        
        return areas[:4]  # Return top 4 areas
    
    def _generate_specific_tips(self, scores: Dict) -> list:
        """Generate specific actionable tips"""
        tips = []
        
        # Voice tips
        if scores.get('voice_modulation', 100) < 70:
            tips.append("Record yourself and listen back to identify monotone sections")
            tips.append("Practice emphasizing key words in each sentence")
        
        # Structure tips
        if scores.get('structure', 100) < 70:
            tips.append("Write an outline before speaking: Intro → 3 Main Points → Conclusion")
            tips.append("Use transition phrases like 'First', 'Additionally', 'In conclusion'")
        
        # Filler word tips
        if scores.get('filler_words', 100) < 70:
            tips.append("Pause briefly instead of saying 'um' or 'uh'")
            tips.append("Practice speaking slower to reduce filler words")
        
        return tips[:3]  # Return top 3 tips
    
    def _get_performance_level(self, overall_score: float) -> str:
        """Determine performance level based on overall score"""
        if overall_score >= 90:
            return "Excellent"
        elif overall_score >= 80:
            return "Advanced"
        elif overall_score >= 70:
            return "Proficient"
        elif overall_score >= 60:
            return "Intermediate"
        elif overall_score >= 50:
            return "Developing"
        else:
            return "Needs Improvement"

    def build_response(analysis_results, speech_id, user_id):
    """Build proper response format"""
    
    scores = {
        'grammar': analysis_results.get('grammar_score', 0),
        'voice': analysis_results.get('voice_score', 0),
        'structure': analysis_results.get('structure_score', 0),
        'effectiveness': analysis_results.get('effectiveness_score', 0),
        'proficiency': analysis_results.get('proficiency_score', 0),
    }
    
    overall_score = calculate_overall_score(scores)
    
    return {
        'analysis_id': speech_id,
        'status': 'completed',
        'user_id': user_id,
        'overall_score': overall_score,
        'scores': scores,
        'transcription': analysis_results.get('transcription', ''),
        'detailed_analysis': {
            'fluency': {
                'filler_words': {
                    'count': analysis_results.get('filler_word_count', 0),
                    'per_minute': analysis_results.get('filler_words_per_minute', 0),
                },
                'pauses': {
                    'count': analysis_results.get('pause_count', 0),
                },
                'words_per_minute': analysis_results.get('wpm', 0),
            },
            'voice': {
                'pitch_variation': analysis_results.get('pitch_variation', 'N/A'),
                'volume_control': analysis_results.get('volume_control', 'N/A'),
                'emphasis': analysis_results.get('emphasis', 'N/A'),
            },
            'structure': {
                'has_introduction': analysis_results.get('has_intro', False),
                'has_body': analysis_results.get('has_body', False),
                'has_conclusion': analysis_results.get('has_conclusion', False),
            },
            'vocabulary': {
                'unique_words': analysis_results.get('unique_word_count', 0),
                'total_words': analysis_results.get('total_words', 0),
                'richness': analysis_results.get('vocabulary_richness', 'N/A'),
            }
        },
        'suggestions': analysis_results.get('suggestions', []),
    }