class ProficiencyCalculator:
    """Calculator for speech proficiency based on fluency and pauses"""
    
    def __init__(self):
        pass
    
    async def calculate(self, transcription_result: dict, filler_analysis: dict, expected_duration: str = "5-7 minutes") -> dict:
        """
        Calculate proficiency score
        
        Args:
            transcription_result: Result from transcription_analyzer
            filler_analysis: Result from filler_word_analyzer
            expected_duration: Expected speech duration
            
        Returns:
            dict with proficiency scores
        """
        # Get pause analysis from filler_analysis if available
        pause_analysis = filler_analysis.get('mid_sentence_pauses', {
            'Pauses under 1.5 seconds': 0,
            'Pauses between 1.5-3 seconds': 0,
            'Pauses exceeding 3 seconds': 0,
            'Pauses exceeding 5 seconds': 0
        })
        
        # Calculate scores
        filler_score = self._evaluate_filler_words(filler_analysis, expected_duration)
        pause_score = self._evaluate_pauses(pause_analysis, expected_duration)
        
        # Weighted combination (60% filler, 40% pause)
        final_score = ((filler_score * 0.6) + (pause_score * 0.4)) * 2
        
        return {
            'final_score': round(final_score, 1),
            'filler_score': round(filler_score, 1),
            'pause_score': round(pause_score, 1),
            'details': {
                'filler_penalty': round(10 - filler_score, 1),
                'pause_penalty': round(10 - pause_score, 1),
                'filler_density': filler_analysis.get('Filler Density', 0),
                'total_fillers': filler_analysis.get('Total Filler Words', 0)
            }
        }
    
    def _get_duration_adjusted_thresholds(self, expected_duration):
        """Calculate thresholds based on expected duration"""
        try:
            expected_duration = expected_duration.lower().replace('—', '-')
            if '-' in expected_duration:
                max_minutes = float(expected_duration.split('-')[1].split()[0])
            else:
                max_minutes = float(expected_duration.split()[0])
            
            scaling_factor = min(max_minutes / 7.0, 1.0)
            
            return {
                'filler_thresholds': {
                    'minimal': round(2 * scaling_factor),
                    'low': round(5 * scaling_factor),
                    'moderate': round(8 * scaling_factor),
                },
                'pause_thresholds': {
                    'short': round(5 * scaling_factor),
                    'medium': round(3 * scaling_factor),
                    'long': round(2 * scaling_factor),
                    'very_long': 0
                }
            }
        except (ValueError, AttributeError):
            return {
                'filler_thresholds': {'minimal': 2, 'low': 5, 'moderate': 8},
                'pause_thresholds': {'short': 5, 'medium': 3, 'long': 2, 'very_long': 0}
            }
    
    def _evaluate_filler_words(self, filler_analysis, expected_duration):
        """Evaluate filler word usage"""
        max_score = 10
        score = max_score
        
        total_fillers = filler_analysis.get('Total Filler Words', 0)
        per_minute_data = filler_analysis.get('Filler Words Per Minute', {})
        filler_density = filler_analysis.get('Filler Density', 0)
        
        # Harsh penalties for high density
        if filler_density > 0.15:
            return 0
        elif filler_density > 0.10:
            score = 2
        elif filler_density > 0.05:
            score = 4
        else:
            # Per-minute penalties
            if isinstance(per_minute_data, dict):
                for minute, count in per_minute_data.items():
                    if count > 8:
                        score -= 3
                    elif count > 5:
                        score -= 2
                    elif count > 2:
                        score -= 1
        
        return max(0, min(score, max_score))
    
    def _evaluate_pauses(self, pause_analysis, expected_duration):
        """Evaluate pause patterns"""
        max_score = 10
        score = max_score
        
        # Penalties for mid-sentence pauses
        if pause_analysis.get('Pauses under 1.5 seconds', 0) > 3:
            score -= 2
        
        if pause_analysis.get('Pauses between 1.5-3 seconds', 0) > 2:
            score -= 3
        
        if pause_analysis.get('Pauses exceeding 3 seconds', 0) > 1:
            score -= 4
        
        if pause_analysis.get('Pauses exceeding 5 seconds', 0) > 0:
            score = 0
        
        # Total pause penalty
        total_pauses = sum(pause_analysis.values())
        if total_pauses > 8:
            score = max(0, score - 5)
        
        return max(0, score)