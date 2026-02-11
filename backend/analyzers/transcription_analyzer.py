import re
from openai import OpenAI
from config.settings import settings

class TranscriptionAnalyzer:
    """Analyzer for audio transcription using OpenAI Whisper API"""
    
    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
    
    async def transcribe(self, model, audio_path: str) -> dict:
        """
        Transcribe audio using OpenAI Whisper API
        
        Args:
            model: Not used (kept for compatibility)
            audio_path: Path to audio file
            
        Returns:
            dict with transcription text, segments, and pause info
        """
        print("Transcribing audio using OpenAI API...")
        
        # Open audio file
        with open(audio_path, 'rb') as audio_file:
            # Call OpenAI Whisper API with verbose_json for timestamps
            response = self.client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                response_format="verbose_json",
                timestamp_granularities=["word"]
            )
        
        # Convert OpenAI response to our format
        result = {
            'text': response.text,
            'segments': [],
            'words': response.words if hasattr(response, 'words') else []
        }
        
        # Build segments from words (OpenAI gives us word-level timestamps)
        if response.words:
            current_segment = {
                'start': response.words[0].start,
                'end': response.words[0].end,
                'text': '',
                'words': []
            }
            
            for word_obj in response.words:
                word_dict = {
                    'word': word_obj.word,
                    'start': word_obj.start,
                    'end': word_obj.end
                }
                current_segment['words'].append(word_dict)
                current_segment['text'] += word_obj.word
                current_segment['end'] = word_obj.end
            
            result['segments'].append(current_segment)
        
        # Process transcription to add pause markers
        transcription_with_pauses, total_pause_duration = self._process_transcription(result)
        
        return {
            'text': transcription_with_pauses,
            'segments': result['segments'],
            'total_pause_duration': total_pause_duration,
            'raw_result': result
        }
    
    def _process_transcription(self, result):
        """Process transcription to add pause markers"""
        transcription_with_pauses = []
        total_pause_duration = 0
        
        # Get all words with timestamps
        all_words = []
        for segment in result.get('segments', []):
            all_words.extend(segment.get('words', []))
        
        if not all_words:
            # Fallback if no word timestamps
            return result.get('text', ''), 0
        
        # Process words and detect pauses
        for i, word_info in enumerate(all_words):
            word = word_info['word']
            transcription_with_pauses.append(word)
            
            # Check for pause before next word
            if i < len(all_words) - 1:
                current_word_end = word_info['end']
                next_word_start = all_words[i + 1]['start']
                time_gap = next_word_start - current_word_end
                
                if time_gap >= 1.0:  # 1 second or more pause
                    pause_duration = round(time_gap, 1)
                    pause_marker = f"[{pause_duration} second pause]"
                    transcription_with_pauses.append(pause_marker)
                    total_pause_duration += pause_duration
        
        # Join into final text
        transcription_with_pauses = ' '.join(transcription_with_pauses)
        transcription_with_pauses = re.sub(r'\s+', ' ', transcription_with_pauses).strip()
        
        return transcription_with_pauses, total_pause_duration