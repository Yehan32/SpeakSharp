import re

# List of common filler words we want to detect
FILLER_WORDS = {
    'um', 'uh', 'ah', 'er', 'like', 'you know', 'sort of', 'kind of', 'basically',
    'literally', 'actually', 'hmm', 'huh', 'yeah', 'right', 'okay', 'well',
    'kinda', 'gonna', 'wanna', 'i guess', 'so yeah'
}

def clean_word(word):
    """Remove punctuation from a word and convert to lowercase"""
    # Remove punctuation like commas, periods, quotes
    cleaned = re.sub(r'[.,!?"]', '', word.lower()).strip()
    return cleaned

def analyze_filler_words(result):
    """
    Analyze filler words from Whisper transcription result.
    
    Args:
        result: Dictionary from Whisper containing 'segments' with word timestamps
        
    Returns:
        Dictionary with filler word analysis and score
    """
    total_filler_words = 0
    filler_words_per_minute = {}  # Track fillers by minute
    total_words = 0
    
    # Loop through each segment (Whisper breaks audio into segments)
    for segment in result['segments']:
        # Get words with timestamps from this segment
        for word_info in segment.get('words', []):
            total_words += 1
            word = clean_word(word_info['word'])
            
            # Check if this word is a filler word
            if word in FILLER_WORDS:
                timestamp = word_info['start']  # When the word was said
                minute = int(timestamp // 60)   # Which minute (0, 1, 2, etc.)
                total_filler_words += 1
                
                # Count fillers for this minute
                if minute not in filler_words_per_minute:
                    filler_words_per_minute[minute] = 0
                filler_words_per_minute[minute] += 1

    # Calculate filler word density (percentage)
    filler_density = total_filler_words / total_words if total_words > 0 else 0
    
    # Format the per-minute breakdown nicely
    minute_breakdown = {}
    for minute, count in sorted(filler_words_per_minute.items()):
        minute_breakdown[f"Minute {minute + 1}"] = count

    # Calculate score (0-10, strict scoring)
    score = 10.0  # Start with perfect score
    
    # Penalize based on density
    if filler_density >= 0.15:      # 15%+ fillers = very bad
        score = 0.0
    elif filler_density >= 0.10:    # 10-15% fillers = bad
        score = 2.0
    elif filler_density >= 0.05:    # 5-10% fillers = poor
        score = 4.0
    else:
        # For lower densities, gradually reduce score
        score = max(0, 10 - (filler_density * 100))
    
    # Additional penalties for too many fillers in any single minute
    for count in filler_words_per_minute.values():
        if count > 6:        # More than 6 fillers in a minute
            score = max(0, score - 4)
        elif count > 4:      # 4-6 fillers in a minute
            score = max(0, score - 3)
        elif count > 2:      # 2-4 fillers in a minute
            score = max(0, score - 2)

    # Return all the analysis
    return {
        'Total Filler Words': total_filler_words,
        'Filler Words Per Minute': minute_breakdown,
        'Filler Density': filler_density,
        'Score': round(score, 1)
    }

def analyze_mid_sentence_pauses(transcription):
    """
    Analyze pauses that occur mid-sentence (not at the end).
    
    Args:
        transcription: Text with pause markers like "[2.3 second pause]"
        
    Returns:
        Dictionary with pause analysis
    """
    # Define pause categories
    pause_categories = {
        'under_1.5': 0,
        'between_1.5_3': 0,
        'exceeding_3': 0,
        'exceeding_5': 0
    }
    
    # Pattern to find pause markers like "[2.3 second pause]"
    pause_pattern = r'\[([\d.]+) second pause\]'
    segments = transcription.split('[')
    
    # Check each pause
    for i, segment in enumerate(segments[1:], 1):
        pause_match = re.match(pause_pattern, '[' + segment)
        if pause_match:
            pause_duration = float(pause_match.group(1))
            # Check if previous text ends with a period (end of sentence)
            previous_text = segments[i-1].strip()
            
            # Only count if NOT at end of sentence
            if not previous_text.endswith('.'):
                # Categorize the pause by duration
                if pause_duration < 1.5:
                    pause_categories['under_1.5'] += 1
                elif 1.5 <= pause_duration <= 3:
                    pause_categories['between_1.5_3'] += 1
                elif 3 < pause_duration <= 5:
                    pause_categories['exceeding_3'] += 1
                else:
                    pause_categories['exceeding_5'] += 1

    # Return nicely formatted results
    return {
        'Pauses under 1.5 seconds': pause_categories['under_1.5'],
        'Pauses between 1.5-3 seconds': pause_categories['between_1.5_3'],
        'Pauses exceeding 3 seconds': pause_categories['exceeding_3'],
        'Pauses exceeding 5 seconds': pause_categories['exceeding_5']
    }