import librosa
import numpy as np
import parselmouth
from parselmouth.praat import call
import statistics

def analyze_voice_modulation(audio_path):
    """
    Analyze voice modulation: pitch, volume, and emphasis.
    
    Args:
        audio_path: Path to audio file
        
    Returns:
        Dictionary with pitch analysis, volume analysis, emphasis, and scores
    """
    try:
        # Load audio file with librosa (for general audio processing)
        y, sr = librosa.load(audio_path)
        
        # Load audio with parselmouth (specialized for voice analysis)
        sound = parselmouth.Sound(audio_path)
        
        # === PITCH ANALYSIS ===
        pitch = sound.to_pitch()
        pitch_values = pitch.selected_array['frequency']
        pitch_values = pitch_values[pitch_values != 0]  # Remove silence (0 Hz)
        
        # Calculate pitch statistics
        mean_pitch = np.mean(pitch_values)          # Average pitch
        std_pitch = np.std(pitch_values)            # Variation in pitch
        pitch_range = np.max(pitch_values) - np.min(pitch_values)  # Range
        
        # === VOLUME/INTENSITY ANALYSIS ===
        intensity = sound.to_intensity()
        intensity_values = intensity.values[0]
        mean_intensity = np.mean(intensity_values)
        intensity_range = np.max(intensity_values) - np.min(intensity_values)
        
        # === EMPHASIS DETECTION ===
        emphasis_points = detect_emphasis_points(pitch_values, intensity_values)
        
        # === AUDIO QUALITY ASSESSMENT ===
        audio_quality = assess_audio_quality(y, sr)
        quality_compensation = calculate_quality_compensation(audio_quality)
        
        # === CALCULATE SCORES ===
        # Pitch & Volume score (0-10)
        pitch_vol_score = (
            calculate_pitch_score(mean_pitch, std_pitch, pitch_range) + 
            calculate_volume_score(intensity_values)
        ) / 2
        pitch_vol_score = adjust_score_for_quality(pitch_vol_score, quality_compensation)
        
        # Emphasis score (0-10)
        emphasis_score = calculate_emphasis_score(
            emphasis_points, len(y)/sr, pitch_values, intensity_values
        )
        emphasis_score = adjust_score_for_quality(emphasis_score, quality_compensation)
        
        # Total score (0-20)
        total_score = pitch_vol_score + emphasis_score
        
        # Debug output
        print(f"\nVoice Modulation Analysis:")
        print(f"Audio Quality Factor: {audio_quality:.2f}")
        print(f"Quality Compensation: +{quality_compensation:.2f}")
        print(f"Pitch/Volume Score: {pitch_vol_score:.2f}")
        print(f"Emphasis Score: {emphasis_score:.2f}")
        print(f"Final Total Score: {total_score:.2f}")
        
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
                'emphasis_distribution': calculate_emphasis_distribution(
                    emphasis_points, len(y)/sr
                )
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
            'error': f"Error analyzing voice modulation: {str(e)}"
        }

def detect_emphasis_points(pitch_values, intensity_values):
    """
    Find points where speaker emphasizes (sudden pitch/volume changes).
    
    Args:
        pitch_values: Array of pitch values over time
        intensity_values: Array of volume values over time
        
    Returns:
        List of indices where emphasis occurs
    """
    emphasis_points = []
    pitch_threshold = np.std(pitch_values) * 1.5
    intensity_threshold = np.std(intensity_values) * 1.5
    
    # Look for sudden changes
    for i in range(1, len(pitch_values) - 1):
        # Big change in pitch OR volume = emphasis
        if (abs(pitch_values[i] - pitch_values[i-1]) > pitch_threshold or 
            abs(intensity_values[i] - intensity_values[i-1]) > intensity_threshold):
            emphasis_points.append(i)
    
    return emphasis_points

def calculate_pitch_score(mean_pitch, std_pitch, pitch_range):
    """
    Score pitch variation (0-10).
    Too monotone = bad, too erratic = bad, just right = good.
    
    Args:
        mean_pitch: Average pitch
        std_pitch: Standard deviation (variation)
        pitch_range: Total range (max - min)
        
    Returns:
        Score 0-10
    """
    score = 10.0
    
    # Check variation (std_pitch)
    if std_pitch < 8:           # Too monotone
        score -= 5
    elif std_pitch < 15:        # Slightly monotone
        score -= 3
    elif std_pitch > 60:        # Too erratic
        score -= 4
    
    # Check range
    if pitch_range < 40:        # Too flat
        score -= 3
    elif pitch_range > 250:     # Too extreme
        score -= 2
    
    # Bonus for good variation
    if 15 <= std_pitch <= 50 and 50 <= pitch_range <= 200:
        score += 1
    
    return max(5, min(10, score))  # Between 5 and 10

def calculate_volume_score(intensity_values):
    """
    Score volume consistency (0-10).
    
    Args:
        intensity_values: Array of volume levels
        
    Returns:
        Score 0-10
    """
    score = 10.0
    
    intensity_std = np.std(intensity_values)
    intensity_range = np.max(intensity_values) - np.min(intensity_values)
    
    # Penalties for inconsistency
    if intensity_std > 20:      # High variation
        score -= 2
    if intensity_range > 50:    # Extreme changes
        score -= 2
    
    # Bonus for good dynamic range
    if 10 <= intensity_std <= 18:
        score += 1
    
    return max(5, min(10, score))

def calculate_emphasis_score(emphasis_points, duration, pitch_values, intensity_values):
    """
    Score emphasis usage (0-10).
    Too few = boring, too many = chaotic, just right = engaging.
    
    Args:
        emphasis_points: List of emphasis locations
        duration: Total audio duration in seconds
        pitch_values: Pitch array
        intensity_values: Volume array
        
    Returns:
        Score 0-10
    """
    score = 10.0
    
    # Ideal: ~1 emphasis every 4 seconds
    ideal_emphasis_count = duration / 4
    actual_count = len(emphasis_points)
    
    # Score based on count
    emphasis_ratio = actual_count / ideal_emphasis_count if ideal_emphasis_count > 0 else 0
    
    if emphasis_ratio < 0.4:        # Too few
        score -= 3
    elif emphasis_ratio > 2.5:      # Too many
        score -= 2
    
    # Check distribution (should be spread out, not clustered)
    distribution = calculate_emphasis_distribution(emphasis_points, duration)
    if max(distribution) > len(emphasis_points) * 0.6:  # Too clustered
        score -= 2
    
    # Check emphasis intensity
    emphasis_intensities = [intensity_values[p] for p in emphasis_points 
                          if p < len(intensity_values)]
    if emphasis_intensities:
        avg_emphasis_intensity = np.mean(emphasis_intensities)
        base_intensity = np.mean(intensity_values)
        
        if avg_emphasis_intensity < base_intensity * 1.05:  # Weak emphasis
            score -= 1
        elif avg_emphasis_intensity > base_intensity * 1.6:  # Too strong
            score -= 1
    
    # Bonus for good pattern
    if 0.4 <= emphasis_ratio <= 2.5:
        score += 1
    
    return max(5, min(10, score))

def calculate_emphasis_distribution(emphasis_points, duration):
    """
    Check how emphasis is distributed across the speech.
    
    Args:
        emphasis_points: List of emphasis indices
        duration: Total duration in seconds
        
    Returns:
        List showing count per quarter
    """
    if not emphasis_points:
        return [0, 0, 0, 0]
    
    segments = 4  # Divide into 4 quarters
    distribution = [0] * segments
    
    for point in emphasis_points:
        segment = int((point / len(emphasis_points)) * segments)
        if segment >= segments:
            segment = segments - 1
        distribution[segment] += 1
    
    return distribution

def assess_audio_quality(y, sr):
    """
    Assess audio quality (0-1 scale).
    
    Args:
        y: Audio samples
        sr: Sample rate
        
    Returns:
        Quality score 0-1
    """
    # Signal-to-noise ratio
    noise_floor = np.mean(np.abs(y[y < np.mean(y)]))
    signal_power = np.mean(np.abs(y))
    snr = 20 * np.log10(signal_power / (noise_floor + 1e-10))
    
    # Spectral stability
    spec_cent = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
    cent_stability = 1.0 / (np.std(spec_cent) + 1e-10)
    
    # Combine into 0-1 score
    quality_score = min(1.0, max(0.0, 
        (snr / 60.0) * 0.6 +
        (cent_stability / 100.0) * 0.4
    ))
    
    return quality_score

def calculate_quality_compensation(quality_factor):
    """
    Add bonus points for poor audio quality.
    
    Args:
        quality_factor: 0-1 quality score
        
    Returns:
        Compensation points to add
    """
    if quality_factor < 0.5:
        return 2.0      # Maximum compensation
    elif quality_factor < 0.7:
        return 1.5
    elif quality_factor < 0.9:
        return 1.0
    return 0.0          # No compensation for good quality

def adjust_score_for_quality(score, compensation):
    """
    Add compensation but cap at 10.
    
    Args:
        score: Original score
        compensation: Bonus points
        
    Returns:
        Adjusted score (max 10)
    """
    return min(10.0, score + compensation)
