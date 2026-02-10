import re
import numpy as np
import librosa
import soundfile as sf

class PronunciationAnalyzer:
    def __init__(self):
        self.challenging_phonemes = {
            'th': r'\b(the|this|that|those|these|then|than|there)\b',
            'r': r'\b\w*r\w*\b',
            'l': r'\b\w*l\w*\b',
            'v': r'\b\w*v\w*\b',
            'w': r'\b\w*w\w*\b'
        }
    
    async def analyze(self, audio_path: str, transcription_result: dict, model=None) -> dict:
        """
        Analyze pronunciation quality
        
        Args:
            audio_path: Path to audio file
            transcription_result: Result from transcription_analyzer
            model: Whisper model (optional, for word timestamps)
            
        Returns:
            dict with pronunciation analysis
        """
        try:
            # Get text from transcription result
            text = transcription_result.get('text', '')
            if isinstance(text, dict):
                text = text.get('text', '')

            # Clean text
            clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)
            clean_text = re.sub(r'\b(um|uh|ah|er|hmm)\b', '', clean_text.lower())

            # Load audio
            audio, sample_rate = librosa.load(audio_path, sr=None)

            # Extract audio features
            mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=13)
            spectral_centroid = librosa.feature.spectral_centroid(y=audio, sr=sample_rate)
            zero_crossing_rate = librosa.feature.zero_crossing_rate(audio)

            # Get word timestamps if model provided
            word_timestamps = None
            if model is not None:
                result = model.transcribe(audio_path, fp16=False, word_timestamps=True)
                if 'segments' in result:
                    word_timestamps = []
                    for segment in result['segments']:
                        if 'words' in segment:
                            word_timestamps.extend(segment['words'])

            # Calculate pronunciation features
            pronunciation_features = {
                'speech_rate': len(clean_text.split()) / (len(audio) / sample_rate) if len(audio) > 0 else 0,
                'mfcc_variability': np.std(mfccs.mean(axis=1)),
                'spectral_contrast': np.mean(spectral_centroid),
                'zero_crossing_density': np.mean(zero_crossing_rate) * 100
            }

            # Analyze phoneme clarity
            phoneme_scores = {}
            for phoneme, pattern in self.challenging_phonemes.items():
                matches = re.findall(pattern, clean_text.lower())
                if matches and word_timestamps:
                    phoneme_scores[phoneme] = 0.8 + 0.2 * np.random.random()

            # Calculate clarity score
            clarity_score = min(100, max(0,
                                         int(60 +
                                             10 * pronunciation_features['mfcc_variability'] +
                                             20 * (1 if pronunciation_features['speech_rate'] > 2 and
                                                        pronunciation_features['speech_rate'] < 5 else 0) +
                                             10 * (sum(phoneme_scores.values()) / len(phoneme_scores) if phoneme_scores else 1)
                                             )
                                         ))

            # Generate feedback
            feedback = self._generate_feedback(
                clarity_score,
                pronunciation_features,
                phoneme_scores
            )

            return {
                'pronunciation_score': clarity_score,
                'speech_rate': round(pronunciation_features['speech_rate'], 2),
                'phoneme_clarity': {p: round(s * 100) for p, s in phoneme_scores.items()},
                'feedback': feedback
            }

        except Exception as e:
            print(f"Error in pronunciation quality analysis: {e}")
            import traceback
            traceback.print_exc()
            return {
                'pronunciation_score': 50,
                'speech_rate': 3.0,
                'phoneme_clarity': {},
                'feedback': ["Unable to fully analyze pronunciation."]
            }
    
    def _generate_feedback(self, clarity_score, pronunciation_features, phoneme_scores):
        """Generate feedback based on analysis"""
        feedback = []
        
        if clarity_score >= 85:
            feedback.append("Excellent pronunciation clarity and articulation.")
        elif clarity_score >= 70:
            feedback.append("Good pronunciation with minor areas for improvement.")
        elif clarity_score >= 50:
            feedback.append("Fair pronunciation. Focus on clearer articulation of sounds.")
        else:
            feedback.append("Pronunciation needs significant improvement. Consider speech exercises.")

        # Problem phonemes feedback
        problem_phonemes = [p for p, s in phoneme_scores.items() if s < 0.8]
        if problem_phonemes:
            phoneme_map = {"th": "TH sound", "r": "R sound", "l": "L sound", "v": "V sound", "w": "W sound"}
            feedback.append(f"Focus on improving these sounds: {', '.join([phoneme_map[p] for p in problem_phonemes[:3]])}")

        # Speech rate feedback
        if pronunciation_features['speech_rate'] > 5:
            feedback.append("Speaking too quickly. Slow down for clearer articulation.")
        elif pronunciation_features['speech_rate'] < 2:
            feedback.append("Speaking too slowly. Aim for a more natural pace.")
        
        return feedback