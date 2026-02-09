import librosa
import numpy as np
from typing import Dict, Any

class PronunciationAnalyzer:
    def __init__(self):
        self.threshold_clarity = 0.7
    
    async def analyze(self, audio_path: str, transcription_result: Dict, whisper_model=None) -> Dict[str, Any]:
        """
        Analyze pronunciation based on audio features
        
        Returns:
            Dict with pronunciation scores and feedback
        """
        try:
            # Load audio
            y, sr = librosa.load(audio_path, sr=16000)
            
            # Calculate pronunciation metrics
            clarity_score = self._calculate_clarity(y, sr)
            articulation_score = self._calculate_articulation(y, sr)
            
            # Overall pronunciation score (0-20)
            pronunciation_score = (clarity_score + articulation_score) / 2
            
            # Generate feedback
            feedback = self._generate_feedback(clarity_score, articulation_score)
            
            return {
                'pronunciation_score': round(pronunciation_score, 1),
                'clarity_score': round(clarity_score, 1),
                'articulation_score': round(articulation_score, 1),
                'feedback': feedback,
                'rating': self._get_rating(pronunciation_score)
            }
            
        except Exception as e:
            print(f"Pronunciation analysis error: {e}")
            return {
                'pronunciation_score': 10.0,
                'clarity_score': 10.0,
                'articulation_score': 10.0,
                'feedback': [],
                'rating': 'Average'
            }
    
    def _calculate_clarity(self, y, sr) -> float:
        """Calculate speech clarity based on spectral features"""
        # Spectral centroid (brightness of sound)
        spectral_centroids = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
        clarity = np.mean(spectral_centroids)
        
        # Normalize to 0-20 scale
        normalized_clarity = min(20, (clarity / 2000) * 20)
        return normalized_clarity
    
    def _calculate_articulation(self, y, sr) -> float:
        """Calculate articulation based on zero-crossing rate"""
        # Zero crossing rate (how often signal changes sign)
        zcr = librosa.feature.zero_crossing_rate(y)[0]
        articulation = np.mean(zcr)
        
        # Normalize to 0-20 scale
        normalized_articulation = min(20, (articulation / 0.1) * 20)
        return normalized_articulation
    
    def _generate_feedback(self, clarity: float, articulation: float) -> list:
        """Generate pronunciation feedback"""
        feedback = []
        
        if clarity < 10:
            feedback.append("Focus on clearer enunciation of words")
        elif clarity > 15:
            feedback.append("Excellent speech clarity!")
        
        if articulation < 10:
            feedback.append("Work on articulating consonants more distinctly")
        elif articulation > 15:
            feedback.append("Great articulation!")
        
        if not feedback:
            feedback.append("Good pronunciation overall")
        
        return feedback
    
    def _get_rating(self, score: float) -> str:
        """Get rating based on score"""
        if score >= 16:
            return "Excellent"
        elif score >= 12:
            return "Good"
        elif score >= 8:
            return "Average"
        else:
            return "Needs Improvement"