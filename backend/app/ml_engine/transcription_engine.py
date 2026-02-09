import re
from typing import Dict, Any

class TranscriptionEngine:
    def __init__(self):
        self.model = None
        print("Transcription engine ready (lazy loading)")
    
    def _load_model(self):
        """Load model only when needed"""
        if self.model is None:
            print("Loading Whisper model...")
            import whisper
            self.model = whisper.load_model("base")
            print("Whisper model loaded")
    
    async def transcribe(self, audio_path: str) -> Dict[str, Any]:
        """Transcribe audio file"""
        self._load_model()  # Load model here instead of __init__
        
        print(f"Transcribing: {audio_path}")
        
        result = self.model.transcribe(
            audio_path,
            fp16=False,
            word_timestamps=True
        )
        
        # Simple processing
        text = result['text']
        duration = result.get('duration', 0)
        word_count = len(text.split())
        
        print(f"Transcription complete: {word_count} words")
        
        return {
            'text': text,
            'duration': duration,
            'word_count': word_count,
            'raw_result': result
        }