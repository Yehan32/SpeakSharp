# File: backend/app/models/proficiency_evaluation.py

def get_duration_adjusted_thresholds(expected_duration):
    """
    Adjust scoring thresholds based on speech length.
    Longer speeches naturally have more fillers, so we adjust expectations.
    
    Args:
        expected_duration: String like "5-7 minutes" or "1-2 minutes"
        
    Returns:
        Dictionary with adjusted thresholds
    """
    try:
        # Parse expected duration (e.g., "5-7 minutes" or "1-2 minutes")
        expected_duration = expected_duration.lower().replace('–', '-')
        
        # Extract the maximum minutes
        if '-' in expected_duration:
            max_minutes = float(expected_duration.split('-')[1].split()[0])
        else:
            max_minutes = float(expected_duration.split()[0])
        
        # Calculate scaling factor (1.0 for 7 minutes, less for shorter)
        scaling_factor = min(max_minutes / 7.0, 1.0)
        
        return {
            'filler_thresholds': {
                'minimal': round(2 * scaling_factor),   # 0-2 fillers for 7 min
                'low': round(5 * scaling_factor),       # 3-5 fillers for 7 min
                'moderate': round(8 * scaling_factor),  # 6-8 fillers for 7 min
            },
            'pause_thresholds': {
                'short': round(5 * scaling_factor),     # up to 5 short pauses
                'medium': round(3 * scaling_factor),    # up to 3 medium pauses
                'long': round(2 * scaling_factor),      # up to 2 long pauses
                'very_long': 0                          # 0 very long pauses allowed
            }
        }
    except (ValueError, AttributeError):
        # If parsing fails, return defaults for 7-minute speech
        return {
            'filler_thresholds': {'minimal': 2, 'low': 5, 'moderate': 8},
            'pause_thresholds': {'short': 5, 'medium': 3, 'long': 2, 'very_long': 0}
        }

def evaluate_filler_words(filler_analysis, expected_duration):
    """
    Score filler word usage (0-10 points).
    Strict penalties for excessive fillers.
    
    Args:
        filler_analysis: Dictionary from filler_word_detection.py
        expected_duration: Expected speech length
        
    Returns:
        Score from 0-10
    """
    max_score = 10
    score = max_score
    
    # Get total filler count
    total_fillers = filler_analysis.get('Total Filler Words', 0)
    
    # Get per-minute breakdown
    per_minute_data = filler_analysis['Filler Words Per Minute']
    
    # Get filler density (percentage)
    filler_density = filler_analysis.get('Filler Density', 0)
    
    # Harsh penalties for high density
    if filler_density > 0.15:       # More than 15% = automatic fail
        return 0
    elif filler_density > 0.10:     # 10-15% = very poor
        score = 2
    elif filler_density > 0.05:     # 5-10% = poor
        score = 4
    else:
        # Check per-minute violations
        if isinstance(per_minute_data, dict):
            for minute, count in per_minute_data.items():
                if count > 8:       # More than 8 in any minute
                    score -= 3
                elif count > 5:     # 5-8 in any minute
                    score -= 2
                elif count > 2:     # 2-5 in any minute
                    score -= 1
    
    return max(0, min(score, max_score))

def evaluate_pauses(pause_analysis, expected_duration):
    """
    Score pause usage (0-10 points).
    Strategic pauses are good, but too many or too long is bad.
    
    Args:
        pause_analysis: Dictionary from analyze_mid_sentence_pauses()
        expected_duration: Expected speech length
        
    Returns:
        Score from 0-10
    """
    max_score = 10
    score = max_score
    
    # Penalize mid-sentence pauses (worse than end-of-sentence)
    if pause_analysis['Pauses under 1.5 seconds'] > 3:
        score -= 2      # Too many short pauses
    
    if pause_analysis['Pauses between 1.5-3 seconds'] > 2:
        score -= 3      # Medium pauses are distracting
    
    if pause_analysis['Pauses exceeding 3 seconds'] > 1:
        score -= 4      # Long pauses are very bad
    
    if pause_analysis['Pauses exceeding 5 seconds'] > 0:
        score = 0       # Any 5+ second pause = automatic fail
    
    # Check total pauses
    total_pauses = sum(pause_analysis.values())
    if total_pauses > 8:    # Too many pauses overall
        score = max(0, score - 5)
    
    return max(0, score)

def calculate_proficiency_score(filler_analysis, pause_analysis, 
                                actual_duration_str=None, expected_duration=None):
    """
    Calculate overall proficiency score (0-20 points).
    Combines filler word and pause scores.
    
    Args:
        filler_analysis: From filler_word_detection.py
        pause_analysis: From analyze_mid_sentence_pauses()
        actual_duration_str: Actual speech duration (not used for scoring)
        expected_duration: Expected duration string
        
    Returns:
        Dictionary with scores and details
    """
    if not expected_duration:
        expected_duration = "5-7 minutes"  # Default
        
    # Get individual scores (each 0-10)
    filler_score = evaluate_filler_words(filler_analysis, expected_duration)
    pause_score = evaluate_pauses(pause_analysis, expected_duration)
    
    # Weight: 60% filler words, 40% pauses
    # Then multiply by 2 to get 0-20 scale
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
