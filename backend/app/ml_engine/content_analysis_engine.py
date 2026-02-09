import re
from typing import Dict, Any

class ContentAnalysisEngine:
    
    FILLER_WORDS = {
        'um', 'uh', 'ah', 'er', 'like', 'you know', 'sort of', 'kind of',
        'basically', 'literally', 'actually', 'hmm', 'yeah', 'right', 'okay', 'well'
    }
    
    def __init__(self):
        print("Content analysis engine ready")
    
    async def analyze(self, transcript_text: str, **kwargs) -> Dict[str, Any]:
        """Analyze transcript content"""
        print("Analyzing content...")
        
        # Count filler words
        filler_count = self._count_filler_words(transcript_text)
        word_count = len(transcript_text.split())
        
        # Calculate score (simple for MVP)
        filler_percentage = (filler_count / word_count * 100) if word_count > 0 else 0
        
        if filler_percentage < 2:
            score = 100
        elif filler_percentage < 5:
            score = 80
        elif filler_percentage < 10:
            score = 60
        else:
            score = 40
        
        print(f"Content analysis complete: {filler_count} filler words")
        
        return {
            'filler_words': {
                'count': filler_count,
                'percentage': round(filler_percentage, 2),
                'score': score
            },
            'word_count': word_count
        }
    
    def _count_filler_words(self, text: str) -> int:
        """Count filler words in text"""
        text_lower = text.lower()
        count = 0
        
        for filler in self.FILLER_WORDS:
            count += len(re.findall(r'\b' + re.escape(filler) + r'\b', text_lower))
        
        return count
    
    async def quick_analyze(self, transcript_text: str) -> Dict[str, Any]:
        """Quick analysis for preview"""
        return await self.analyze(transcript_text)