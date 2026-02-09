from typing import Dict, Any

class SpeechEvaluationEngine:
    
    def __init__(self):
        print("Evaluation engine ready")
    
    async def evaluate(
        self,
        voice_results: Dict,
        content_results: Dict,
        transcription_results: Dict,
        **kwargs
    ) -> Dict[str, Any]:
        """Calculate final scores"""
        print("Calculating scores...")
        
        # For MVP: Simple average of available scores
        content_score = content_results.get('filler_words', {}).get('score', 70)
        
        # Overall score (for now just use content score)
        overall_score = content_score
        
        # Generate simple suggestions
        suggestions = self._generate_suggestions(content_results)
        
        print(f"Evaluation complete: Overall score = {overall_score}")
        
        return {
            'overall_score': round(overall_score, 1),
            'score_breakdown': {
                'content_quality': content_score,
                'filler_words': content_results.get('filler_words', {}).get('score', 70)
            },
            'improvement_suggestions': suggestions,
            'strengths': self._identify_strengths(content_results),
            'areas_for_improvement': self._identify_areas(content_results)
        }
    
    def _generate_suggestions(self, content_results: Dict) -> list:
        """Generate improvement suggestions"""
        suggestions = []
        
        filler_count = content_results.get('filler_words', {}).get('count', 0)
        filler_percentage = content_results.get('filler_words', {}).get('percentage', 0)
        
        if filler_percentage > 5:
            suggestions.append("Reduce filler words like 'um', 'uh', and 'like'. Practice pausing instead.")
        elif filler_percentage < 2:
            suggestions.append("Great job minimizing filler words! Keep it up.")
        
        if len(suggestions) == 0:
            suggestions.append("Good speech! Continue practicing to improve further.")
        
        return suggestions
    
    def _identify_strengths(self, content_results: Dict) -> list:
        """Identify speech strengths"""
        strengths = []
        
        filler_percentage = content_results.get('filler_words', {}).get('percentage', 0)
        
        if filler_percentage < 3:
            strengths.append("Excellent control over filler words")
        
        if len(strengths) == 0:
            strengths.append("Clear communication")
        
        return strengths
    
    def _identify_areas(self, content_results: Dict) -> list:
        """Identify areas for improvement"""
        areas = []
        
        filler_percentage = content_results.get('filler_words', {}).get('percentage', 0)
        
        if filler_percentage > 5:
            areas.append("Reduce filler word usage")
        
        if len(areas) == 0:
            areas.append("Continue refining delivery")
        
        return areas