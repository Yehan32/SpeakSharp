import numpy as np
import librosa
import re
from sklearn.preprocessing import StandardScaler
import spacy
import torch
from transformers import BertTokenizer, BertModel
import os
import warnings

# Suppress warnings
warnings.filterwarnings("ignore", category=UserWarning)

# Load NLP models
nlp = spacy.load("en_core_web_sm")

# BERT model globals
BERT_MODEL_NAME = "bert-base-uncased"
tokenizer = None
model = None


class EmphasisAnalyzer:
    """Analyzer for vocal emphasis and key point highlighting"""
    
    def __init__(self):
        pass
    
    async def analyze(self, audio_path: str, transcription_result: dict) -> dict:
        """
        Analyze emphasis quality in speech
        
        Args:
            audio_path: Path to audio file
            transcription_result: Result from transcription_analyzer with timestamps
            
        Returns:
            dict with emphasis analysis
        """
        try:
            # Get transcript text and segments
            transcript_text = transcription_result.get('text', '')
            result = transcription_result.get('raw_result', transcription_result)
            
            # Load audio
            audio, sample_rate = librosa.load(audio_path, sr=None)
            
            # Detect emphasized segments
            emphasized_segments = self._detect_emphasized_segments(audio, sample_rate, transcript_text)
            
            # Map emphasis to words
            emphasized_words = self._map_emphasis_to_transcript(emphasized_segments, result, transcript_text)
            
            # Identify key phrases
            key_phrases = self._identify_key_phrases(transcript_text)
            
            # Calculate coverage
            emphasized_key_phrases = []
            for key_phrase in key_phrases:
                for emph_word in emphasized_words:
                    if key_phrase in emph_word.lower() or emph_word.lower() in key_phrase:
                        emphasized_key_phrases.append(key_phrase)
                        break
            
            # Calculate metrics
            total_emphasized_segments = len(emphasized_segments)
            emphasis_density = total_emphasized_segments / (len(audio) / sample_rate / 60) if len(audio) > 0 else 0
            emphasis_coverage = len(emphasized_key_phrases) / len(key_phrases) if len(key_phrases) > 0 else 0
            
            # Calculate score
            emphasis_score = min(100, max(0, int(
                40 * min(1.0, emphasis_coverage) +
                30 * min(1.0, emphasis_density / 5) +
                30 * min(1.0, total_emphasized_segments / max(1, len(key_phrases)))
            )))
            
            # Generate feedback
            feedback = self._generate_feedback(emphasis_score, emphasis_coverage, emphasis_density, key_phrases, emphasized_key_phrases)
            
            return {
                'emphasis_score': emphasis_score,
                'total_emphasized_segments': total_emphasized_segments,
                'emphasis_density_per_minute': round(emphasis_density, 2),
                'emphasis_coverage': round(emphasis_coverage * 100),
                'key_phrases': key_phrases,
                'emphasized_words': emphasized_words,
                'feedback': feedback
            }
            
        except Exception as e:
            print(f"Error in emphasis analysis: {e}")
            import traceback
            traceback.print_exc()
            return {
                'emphasis_score': 50,
                'feedback': ["Unable to fully analyze emphasis. Focus on varying your tone to highlight key points."]
            }
    
    def _detect_emphasized_segments(self, audio, sample_rate, transcript_with_timestamps=None):
        """Detect emphasized segments in audio"""
        hop_length = 512
        frame_length = 2048
        
        # Extract features
        rms = librosa.feature.rms(y=audio, frame_length=frame_length, hop_length=hop_length)[0]
        rms_scaled = StandardScaler().fit_transform(rms.reshape(-1, 1)).flatten()
        
        pitches, magnitudes = librosa.piptrack(y=audio, sr=sample_rate, fmin=75, fmax=400,
                                                n_fft=frame_length, hop_length=hop_length)
        
        pitch_values = []
        for t in range(pitches.shape[1]):
            index = magnitudes[:, t].argmax()
            pitch = pitches[index, t]
            pitch_values.append(pitch if pitch > 0 else 0)
        
        pitch_delta = np.abs(np.diff(np.array(pitch_values), prepend=pitch_values[0]))
        pitch_delta_scaled = StandardScaler().fit_transform(pitch_delta.reshape(-1, 1)).flatten()
        
        contrast = librosa.feature.spectral_contrast(y=audio, sr=sample_rate, n_fft=frame_length, hop_length=hop_length)
        contrast_mean = np.mean(contrast, axis=0)
        contrast_scaled = StandardScaler().fit_transform(contrast_mean.reshape(-1, 1)).flatten()
        
        # Combine features
        emphasis_score = (0.4 * rms_scaled + 0.3 * pitch_delta_scaled + 0.3 * contrast_scaled)
        emphasis_score = (emphasis_score - np.min(emphasis_score)) / (np.max(emphasis_score) - np.min(emphasis_score))
        
        # Find emphasized frames
        emphasis_threshold = 0.7
        emphasized_frames = np.where(emphasis_score > emphasis_threshold)[0]
        
        # Group into segments
        emphasized_segments = []
        if len(emphasized_frames) > 0:
            current_segment = [emphasized_frames[0]]
            
            for i in range(1, len(emphasized_frames)):
                if emphasized_frames[i] - emphasized_frames[i-1] <= 3:
                    current_segment.append(emphasized_frames[i])
                else:
                    start_time = librosa.frames_to_time(min(current_segment), sr=sample_rate, hop_length=hop_length)
                    end_time = librosa.frames_to_time(max(current_segment), sr=sample_rate, hop_length=hop_length)
                    emphasized_segments.append((start_time, end_time))
                    current_segment = [emphasized_frames[i]]
            
            start_time = librosa.frames_to_time(min(current_segment), sr=sample_rate, hop_length=hop_length)
            end_time = librosa.frames_to_time(max(current_segment), sr=sample_rate, hop_length=hop_length)
            emphasized_segments.append((start_time, end_time))
        
        return emphasized_segments
    
    def _identify_key_phrases(self, text):
        """Identify phrases that should be emphasized"""
        if not text:
            return []
        
        key_phrases = []
        doc = nlp(text)
        
        # Important noun phrases
        for chunk in doc.noun_chunks:
            if len(chunk) >= 2 and not all(token.is_stop for token in chunk):
                key_phrases.append(chunk.text)
        
        # Named entities
        for ent in doc.ents:
            key_phrases.append(ent.text)
        
        # Emphasis indicators
        emphasis_indicators = [
            "important", "critical", "essential", "crucial", "significant",
            "key", "primary", "fundamental", "vital", "central"
        ]
        
        for token in doc:
            if token.text.lower() in emphasis_indicators and token.head.text:
                start = max(0, token.i - 2)
                end = min(len(doc), token.i + 5)
                key_phrases.append(doc[start:end].text)
        
        # Remove duplicates
        key_phrases = list(set(key_phrase.strip().lower() for key_phrase in key_phrases))
        key_phrases = [phrase for phrase in key_phrases if len(phrase) > 2]
        
        return key_phrases
    
    def _map_emphasis_to_transcript(self, emphasized_segments, result, text):
        """Map emphasized segments to words"""
        emphasized_words = []
        
        try:
            if not emphasized_segments or not result or 'segments' not in result:
                return emphasized_words
            
            # Extract words with timestamps
            all_words = []
            for segment in result['segments']:
                if 'words' in segment:
                    for word_info in segment['words']:
                        all_words.append({
                            'word': word_info['word'],
                            'start': word_info['start'],
                            'end': word_info['end']
                        })
            
            # Find overlapping words
            for start_time, end_time in emphasized_segments:
                segment_words = []
                for word_info in all_words:
                    word_start = word_info['start']
                    word_end = word_info['end']
                    
                    if (word_start <= end_time and word_end >= start_time):
                        segment_words.append(word_info['word'])
                
                if segment_words:
                    emphasized_phrase = ' '.join(segment_words).strip()
                    if emphasized_phrase and len(emphasized_phrase) > 1:
                        emphasized_words.append(emphasized_phrase)
        
        except Exception as e:
            print(f"Error mapping emphasis: {e}")
        
        return emphasized_words
    
    def _generate_feedback(self, emphasis_score, emphasis_coverage, emphasis_density, key_phrases, emphasized_key_phrases):
        """Generate feedback based on analysis"""
        feedback = []
        
        if emphasis_score >= 80:
            feedback.append("Excellent use of vocal emphasis to highlight key points.")
        elif emphasis_score >= 60:
            feedback.append("Good emphasis patterns but could be more consistent on key points.")
        elif emphasis_score >= 40:
            feedback.append("Some points emphasized effectively, but important concepts need clearer emphasis.")
        else:
            feedback.append("Limited vocal emphasis detected. Work on highlighting key points through voice modulation.")
        
        if emphasis_coverage < 0.3:
            feedback.append("Many important concepts weren't emphasized. Practice identifying and highlighting key points.")
        
        if emphasis_density < 2:
            feedback.append("Add more emphasis to engage listeners and highlight important information.")
        elif emphasis_density > 10:
            feedback.append("Too many emphasized segments may dilute their impact. Focus on emphasizing only the most important points.")
        
        if emphasized_key_phrases and emphasis_score >= 60:
            feedback.append(f"Effectively emphasized {len(emphasized_key_phrases)} key points in your speech.")
        
        return feedback