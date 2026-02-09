import re
import nltk
from nltk.tokenize import sent_tokenize

def evaluate_speech_development(transcription, duration, expected_duration):
    """
    Evaluate speech structure and time utilization.
    
    Args:
        transcription: Full speech text with pause markers
        duration: Actual speech duration in seconds
        expected_duration: Expected duration string (e.g., "5-7 minutes")
        
    Returns:
        Dictionary with structure and time utilization scores
    """
    # Clean transcription (remove pause markers)
    clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', transcription)
    
    # Analyze structure
    structure_result = analyze_structure(clean_text, duration)
    
    # Analyze time utilization
    time_result = analyze_time_utilization(duration, expected_duration, clean_text)
    
    return {
        'structure': structure_result,
        'time_utilization': time_result
    }

def analyze_structure(text, duration):
    """
    Analyze speech structure: intro, body, conclusion.
    
    Args:
        text: Speech text (without pause markers)
        duration: Speech duration in seconds
        
    Returns:
        Dictionary with structure score and quality assessment
    """
    score = 14.0  # Max structure score
    feedback = []
    
    # Split into sentences
    try:
        sentences = sent_tokenize(text)
    except:
        # If NLTK punkt not available, simple split
        sentences = text.split('.')
    
    total_sentences = len(sentences)
    
    if total_sentences < 3:
        return {
            'score': 0,
            'introduction_quality': 'Poor',
            'body_development': 'Poor',
            'conclusion_quality': 'Poor',
            'feedback': ['Speech is too short to properly analyze structure.']
        }
    
    # Divide speech into sections (based on sentence count)
    # First 20% = intro, Middle 60% = body, Last 20% = conclusion
    intro_count = max(1, int(total_sentences * 0.2))
    conclusion_count = max(1, int(total_sentences * 0.2))
    body_count = total_sentences - intro_count - conclusion_count
    
    intro_sentences = sentences[:intro_count]
    body_sentences = sentences[intro_count:intro_count + body_count]
    conclusion_sentences = sentences[-conclusion_count:]
    
    # === INTRODUCTION ANALYSIS ===
    intro_text = ' '.join(intro_sentences).lower()
    
    # Keywords that indicate good introduction
    intro_keywords = [
        'today', 'going to', 'will discuss', 'talk about', 'purpose',
        'introduce', 'begin', 'start', 'hello', 'good morning', 'good afternoon'
    ]
    
    intro_quality = 'Poor'
    intro_score = 0
    
    if any(keyword in intro_text for keyword in intro_keywords):
        intro_quality = 'Very Good'
        intro_score = 5
        feedback.append("Strong introduction with clear opening")
    elif len(intro_text) > 50:
        intro_quality = 'Good'
        intro_score = 3
        feedback.append("Introduction present but could be stronger")
    else:
        intro_quality = 'Weak'
        intro_score = 1
        feedback.append("Introduction needs improvement - be more direct")
        score -= 4
    
    # === BODY ANALYSIS ===
    body_text = ' '.join(body_sentences).lower()
    
    # Keywords for good body development
    body_keywords = [
        'first', 'second', 'third', 'next', 'then', 'also', 'furthermore',
        'however', 'additionally', 'for example', 'such as', 'because'
    ]
    
    body_transitions = sum(1 for keyword in body_keywords if keyword in body_text)
    
    body_quality = 'Poor'
    body_score = 0
    
    if body_transitions >= 5:
        body_quality = 'Excellent'
        body_score = 5
        feedback.append("Excellent body development with clear transitions")
    elif body_transitions >= 3:
        body_quality = 'Very Good'
        body_score = 4
        feedback.append("Good body development with logical flow")
    elif body_transitions >= 1:
        body_quality = 'Good'
        body_score = 2
        feedback.append("Body needs more transition words for clarity")
        score -= 2
    else:
        body_quality = 'Weak'
        body_score = 0
        feedback.append("Body lacks structure - use more transitions")
        score -= 4
    
    # === CONCLUSION ANALYSIS ===
    conclusion_text = ' '.join(conclusion_sentences).lower()
    
    # Keywords for good conclusion
    conclusion_keywords = [
        'conclusion', 'finally', 'in summary', 'to sum up', 'therefore',
        'thus', 'in closing', 'lastly', 'thank you', 'questions'
    ]
    
    conclusion_quality = 'Poor'
    conclusion_score = 0
    
    if any(keyword in conclusion_text for keyword in conclusion_keywords):
        conclusion_quality = 'Very Good'
        conclusion_score = 4
        feedback.append("Strong conclusion with clear closing")
    elif len(conclusion_text) > 30:
        conclusion_quality = 'Good'
        conclusion_score = 2
        feedback.append("Conclusion present but could be more impactful")
        score -= 1
    else:
        conclusion_quality = 'Weak'
        conclusion_score = 0
        feedback.append("Conclusion needs improvement - summarize key points")
        score -= 3
    
    # Final score calculation
    final_score = max(0, min(14, score))
    
    return {
        'score': round(final_score, 1),
        'introduction_quality': intro_quality,
        'body_development': body_quality,
        'conclusion_quality': conclusion_quality,
        'feedback': feedback,
        'section_counts': {
            'intro_sentences': intro_count,
            'body_sentences': body_count,
            'conclusion_sentences': conclusion_count
        }
    }

def analyze_time_utilization(duration, expected_duration, text):
    """
    Analyze how time is distributed across speech sections.
    
    Args:
        duration: Actual duration in seconds
        expected_duration: Expected duration string
        text: Speech text
        
    Returns:
        Dictionary with time utilization score
    """
    score = 6.0  # Max time utilization score
    feedback = []
    
    # Parse expected duration
    try:
        expected_duration = expected_duration.lower().replace('–', '-')
        if '-' in expected_duration:
            parts = expected_duration.split('-')
            min_minutes = float(parts[0].strip())
            max_minutes = float(parts[1].split()[0].strip())
        else:
            min_minutes = max_minutes = float(expected_duration.split()[0])
        
        min_seconds = min_minutes * 60
        max_seconds = max_minutes * 60
    except:
        # Default to 5-7 minutes if parsing fails
        min_seconds = 300
        max_seconds = 420
    
    # Check if within expected range
    if duration < min_seconds * 0.8:
        score -= 3
        feedback.append(f"Speech is too short. Aim for {min_minutes}-{max_minutes} minutes")
    elif duration > max_seconds * 1.2:
        score -= 3
        feedback.append(f"Speech is too long. Keep within {min_minutes}-{max_minutes} minutes")
    else:
        feedback.append("Good time management - within expected range")
    
    # Estimate section times (rough approximation)
    # Assume: 20% intro, 60% body, 20% conclusion
    intro_time = duration * 0.2
    body_time = duration * 0.6
    conclusion_time = duration * 0.2
    
    # Check if sections are reasonably balanced
    if intro_time < 15:  # Less than 15 seconds intro
        score -= 1
        feedback.append("Introduction seems rushed - take more time to set up")
    
    if conclusion_time < 15:  # Less than 15 seconds conclusion
        score -= 1
        feedback.append("Conclusion seems rushed - strengthen your closing")
    
    final_score = max(0, score)
    
    return {
        'score': round(final_score, 1),
        'total_time': duration,
        'intro_time': round(intro_time, 1),
        'body_time': round(body_time, 1),
        'conclusion_time': round(conclusion_time, 1),
        'feedback': feedback
    }
