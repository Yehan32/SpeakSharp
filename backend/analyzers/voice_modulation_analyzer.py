import librosa
import numpy as np
import parselmouth
from parselmouth.praat import call


class VoiceModulationAnalyzer:
    def __init__(self):
        pass
    
    async def analyze(self, audio_path: str) -> dict:
        """
        Analyze voice modulation parameters
        
        Args:
            audio_path: Path to audio file
            
        Returns:
            dict with voice modulation analysis
        """
        try:
            # Load audio
            y, sr = librosa.load(audio_path)
            sound = parselmouth.Sound(audio_path)
            
            # Analyze pitch
            pitch = sound.to_pitch()
            pitch_values = pitch.selected_array['frequency']
            pitch_values = pitch_values[pitch_values != 0]
            
            # Calculate pitch statistics
            mean_pitch = np.mean(pitch_values)
            std_pitch = np.std(pitch_values)
            pitch_range = np.max(pitch_values) - np.min(pitch_values)
            
            # Analyze volume/intensity
            intensity = sound.to_intensity()
            intensity_values = intensity.values[0]
            mean_intensity = np.mean(intensity_values)
            intensity_range = np.max(intensity_values) - np.min(intensity_values)
            
            # Calculate emphasis points
            emphasis_points = self._detect_emphasis_points(pitch_values, intensity_values)
            
            # Audio quality assessment
            audio_quality = self._assess_audio_quality(y, sr)
            quality_compensation = self._calculate_quality_compensation(audio_quality)
            
            # Calculate scores with quality compensation
            pitch_vol_score = (
                self._calculate_pitch_score(mean_pitch, std_pitch, pitch_range) + 
                self._calculate_volume_score(intensity_values)
            ) / 2
            pitch_vol_score = self._adjust_score_for_quality(pitch_vol_score, quality_compensation)
            
            emphasis_score = self._calculate_emphasis_score(
                emphasis_points, len(y)/sr, pitch_values, intensity_values
            )
            emphasis_score = self._adjust_score_for_quality(emphasis_score, quality_compensation)
            
            # Calculate total score (scale to 0-20)
            total_score = (pitch_vol_score + emphasis_score)
            
            return {
                'pitch_analysis': {
                    'mean_pitch': float(mean_pitch),
                    'pitch_range': float(pitch_range),
                    'pitch_variation': float(std_pitch)
                },
                'volume_analysis': {
                    'mean_intensity': float(mean_intensity),
                    'intensity_range': float(intensity_range)
                },
                'emphasis_analysis': {
                    'emphasis_points_count': len(emphasis_points),
                    'emphasis_distribution': self._calculate_emphasis_distribution(emphasis_points, len(y)/sr)
                },
                'audio_quality': {
                    'quality_factor': float(audio_quality),
                    'compensation_applied': float(quality_compensation)
                },
                'scores': {
                    'pitch_and_volume_score': float(pitch_vol_score),
                    'emphasis_score': float(emphasis_score),
                    'total_score': float(total_score)
                }
            }
            
        except Exception as e:
            print(f"Error in voice modulation analysis: {e}")
            return {
                'error': f"Error analyzing voice modulation: {str(e)}",
                'scores': {
                    'total_score': 10.0
                }
            }
    
    def _detect_emphasis_points(self, pitch_values, intensity_values):
        """Detect points of emphasis"""
        emphasis_points = []
        pitch_threshold = np.std(pitch_values) * 1.5
        intensity_threshold = np.std(intensity_values) * 1.5
        
        for i in range(1, len(pitch_values) - 1):
            if (abs(pitch_values[i] - pitch_values[i-1]) > pitch_threshold or 
                abs(intensity_values[i] - intensity_values[i-1]) > intensity_threshold):
                emphasis_points.append(i)
        
        return emphasis_points
    
    def _calculate_pitch_score(self, mean_pitch, std_pitch, pitch_range):
        """Calculate score for pitch variation"""
        score = 10.0
        
        if std_pitch < 8:
            score -= 5
        elif std_pitch < 15:
            score -= 3
        elif std_pitch > 60:
            score -= 4
        
        if pitch_range < 40:
            score -= 3
        elif pitch_range > 250:
            score -= 2
        
        if 15 <= std_pitch <= 50 and 50 <= pitch_range <= 200:
            score += 1
        
        return max(5, min(10, score))
    
    def _calculate_volume_score(self, intensity_values):
        """Calculate score for volume consistency"""
        score = 10.0
        
        intensity_std = np.std(intensity_values)
        intensity_range = np.max(intensity_values) - np.min(intensity_values)
        
        if intensity_std > 20:
            score -= 2
        if intensity_range > 50:
            score -= 2
        
        if 10 <= intensity_std <= 18:
            score += 1
        
        return max(5, min(10, score))
    
    def _calculate_emphasis_score(self, emphasis_points, duration, pitch_values, intensity_values):
        """Calculate score for emphasis points"""
        score = 10.0
        
        ideal_emphasis_count = duration / 4
        actual_count = len(emphasis_points)
        
        emphasis_ratio = actual_count / ideal_emphasis_count
        if emphasis_ratio < 0.4:
            score -= 3
        elif emphasis_ratio > 2.5:
            score -= 2
        
        distribution = self._calculate_emphasis_distribution(emphasis_points, duration)
        if distribution and max(distribution) > len(emphasis_points) * 0.6:
            score -= 2
        
        emphasis_intensities = [intensity_values[p] for p in emphasis_points if p < len(intensity_values)]
        if emphasis_intensities:
            avg_emphasis_intensity = np.mean(emphasis_intensities)
            base_intensity = np.mean(intensity_values)
            
            if avg_emphasis_intensity < base_intensity * 1.05:
                score -= 1
            elif avg_emphasis_intensity > base_intensity * 1.6:
                score -= 1
        
        if emphasis_ratio >= 0.4 and emphasis_ratio <= 2.5:
            score += 1
        
        return max(5, min(10, score))
    
    def _calculate_emphasis_distribution(self, emphasis_points, duration):
        """Calculate emphasis distribution"""
        if not emphasis_points:
            return []
        
        segments = 4
        segment_duration = duration / segments
        distribution = [0] * segments
        
        for point in emphasis_points:
            segment = int((point / len(emphasis_points)) * segments)
            if segment >= segments:
                segment = segments - 1
            distribution[segment] += 1
        
        return distribution
    
    def _assess_audio_quality(self, y, sr):
        """Assess audio quality"""
        noise_floor = np.mean(np.abs(y[y < np.mean(y)]))
        signal_power = np.mean(np.abs(y))
        snr = 20 * np.log10(signal_power / (noise_floor + 1e-10))
        
        spec_cent = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
        cent_stability = 1.0 / (np.std(spec_cent) + 1e-10)
        
        quality_score = min(1.0, max(0.0, 
            (snr / 60.0) * 0.6 +
            (cent_stability / 100.0) * 0.4
        ))
        
        return quality_score
    
    def _calculate_quality_compensation(self, quality_factor):
        """Calculate quality compensation"""
        if quality_factor < 0.5:
            return 2.0
        elif quality_factor < 0.7:
            return 1.5
        elif quality_factor < 0.9:
            return 1.0
        return 0.0
    
    def _adjust_score_for_quality(self, score, compensation):
        """Adjust score based on quality"""
        return min(10.0, score + compensation)