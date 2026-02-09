# File: backend/app/models/speech_effectiveness.py

import re
import nltk
from nltk.tokenize import word_tokenize, sent_tokenize

def evaluate_speech_effectiveness(transcription, topic, expected_duration, duration):
    """
    Evaluate overall speech effectiveness.
    
    Args:
        transcription: Full speech text
        topic: Speech topic/title
        expected_duration: Expected duration string
        duration: Actual duration in seconds
        
    Returns:
        Dictionary with effectiveness scores and feedback
    """
    # Clean transcription
    clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', transcription)
    
    # Tokenize
    try:
        words = word_tokenize(clean_text.lower())
        sentences = sent_tokenize(clean_text)
    except:
        words = clean_text.lower().split()
        sentences = clean_text.split('.')
    
    # Analyze different aspects
    purpose_score = analyze_purpose_clarity(clean_text, topic, sentences)
    organization_score = analyze_content_organization(sentences, words)
    engagement_score = analyze_audience_engagement(clean_text, sentences, words)
    achievement_score = analyze_goal_achievement(clean_text, topic, sentences)
    
    # Calculate total (average of 4 components, scaled to 0-20)
    total_score = (purpose_score + organization_score + 
                   engagement_score + achievement_score) / 4
    
    # Generate feedback
    feedback = generate_effectiveness_feedback(
        purpose_score, organization_score, engagement_score, achievement_score
    )
    
    return {
        'total_score': round(total_score, 1),
        'purpose_clarity': purpose_score,
        'content_organization': organization_score,
        'audience_engagement': engagement_score,
        'achievement_of_goals': achievement_score,
        'feedback': feedback
    }

def analyze_purpose_clarity(text, topic, sentences):
    """
    Score how clearly the speech states its purpose (0-20).
    
    Args:
        text: Speech text
        topic: Speech topic
        sentences: List of sentences
        
    Returns:
        Score 0-20
    """
    score = 20
    text_lower = text.lower()
    
    # Purpose indicators in first 20% of speech
    first_portion = ' '.join(sentences[:max(1, len(sentences)//5)]).lower()
    
    purpose_keywords = [
        'purpose', 'goal', 'aim', 'objective', 'today', 'discuss',
        'explain', 'demonstrate', 'show', 'present', 'introduce',
        'talk about', 'share', 'tell you about'
    ]
    
    # Check if purpose is stated early
    purpose_stated = any(keyword in first_portion for keyword in purpose_keywords)
    
    if purpose_stated:
        score = 20
    elif any(keyword in text_lower for keyword in purpose_keywords):
        score = 15  # Purpose stated but not in intro
    else:
        score = 10  # No clear purpose statement
    
    # Check if topic words appear in speech
    if topic:
        topic_words = set(topic.lower().split())
        speech_words = set(text_lower.split())
        topic_coverage = len(topic_words.intersection(speech_words)) / len(topic_words) if topic_words else 0
        
        if topic_coverage < 0.3:  # Less than 30% of topic words mentioned
            score -= 5
    
    return max(0, score)

def analyze_content_organization(sentences, words):
    """
    Score content organization (0-20).
    
    Args:
        sentences: List of sentences
        words: List of words
        
    Returns:
        Score 0-20
    """
    score = 20
    
    # Check average sentence length (15-25 words is ideal)
    avg_sentence_length = len(words) / len(sentences) if sentences else 0
    
    if avg_sentence_length < 8:
        score -= 5  # Too choppy
    elif avg_sentence_length > 35:
        score -= 5  # Too complex
    elif 15 <= avg_sentence_length <= 25:
        score += 0  # Perfect, no change
    else:
        score -= 2  # Slightly off
    
    # Check for organizational markers
    org_markers = [
        'first', 'second', 'third', 'next', 'then', 'finally',
        'lastly', 'to begin', 'to start', 'in addition', 'furthermore'
    ]
    
    text_lower = ' '.join([w.lower() for w in words])
    marker_count = sum(1 for marker in org_markers if marker in text_lower)
    
    if marker_count >= 4:
        score += 0  # Well organized
    elif marker_count >= 2:
        score -= 3  # Some organization
    else:
        score -= 6  # Poor organization
    
    # Check for logical flow indicators
    flow_markers = [
        'therefore', 'thus', 'consequently', 'as a result', 'because',
        'however', 'although', 'despite', 'while', 'whereas'
    ]
    
    flow_count = sum(1 for marker in flow_markers if marker in text_lower)
    
    if flow_count >= 3:
        score += 0
    elif flow_count >= 1:
        score -= 2
    else:
        score -= 4
    
    return max(0, min(20, score))

def analyze_audience_engagement(text, sentences, words):
    """
    Score audience engagement potential (0-20).
    
    Args:
        text: Speech text
        sentences: List of sentences
        words: List of words
        
    Returns:
        Score 0-20
    """
    score = 15  # Start at average
    text_lower = text.lower()
    
    # Check for questions (engages audience)
    question_count = text.count('?')
    if question_count >= 3:
        score += 3
    elif question_count >= 1:
        score += 1
    
    # Check for direct address ("you", "we", "us")
    direct_address = ['you', 'we', 'us', 'our', 'your']
    address_count = sum(1 for word in words if word.lower() in direct_address)
    address_ratio = address_count / len(words) if words else 0
    
    if address_ratio > 0.02:  # More than 2%
        score += 3
    elif address_ratio > 0.01:  # More than 1%
        score += 1
    
    # Check for engaging language
    engaging_words = [
        'imagine', 'picture', 'think about', 'consider', 'interesting',
        'amazing', 'important', 'crucial', 'vital', 'exciting'
    ]
    
    engagement_count = sum(1 for word in engaging_words if word in text_lower)
    if engagement_count >= 3:
        score += 2
    
    # Check for examples
    example_markers = ['for example', 'such as', 'for instance', 'like']
    example_count = sum(1 for marker in example_markers if marker in text_lower)
    
    if example_count >= 2:
        score += 2
    elif example_count >= 1:
        score += 1
    
    # Check for storytelling elements
    story_words = ['when', 'once', 'story', 'time', 'experience']
    story_count = sum(1 for word in story_words if word in text_lower)
    
    if story_count >= 3:
        score += 2
    
    return max(0, min(20, score))

def analyze_goal_achievement(text, topic, sentences):
    """
    Score how well the speech achieves its goals (0-20).
    
    Args:
        text: Speech text
        topic: Speech topic
        sentences: List of sentences
        
    Returns:
        Score 0-20
    """
    score = 15  # Start at average
    text_lower = text.lower()
    
    # Check for conclusion indicators
    conclusion_markers = [
        'conclusion', 'summary', 'to sum up', 'in closing',
        'finally', 'therefore', 'thus', 'in the end'
    ]
    
    last_portion = ' '.join(sentences[-max(1, len(sentences)//5):]).lower()
    has_conclusion = any(marker in last_portion for marker in conclusion_markers)
    
    if has_conclusion:
        score += 5
    else:
        score -= 3
    
    # Check for call to action or takeaway
    action_words = [
        'should', 'must', 'need to', 'encourage', 'urge', 'ask',
        'remember', 'take away', 'keep in mind', 'apply'
    ]
    
    action_count = sum(1 for word in action_words if word in text_lower)
    if action_count >= 2:
        score += 3
    
    # Check for supporting evidence
    evidence_markers = [
        'research', 'study', 'data', 'statistics', 'according to',
        'evidence', 'shows', 'proves', 'demonstrates'
    ]
    
    evidence_count = sum(1 for marker in evidence_markers if marker in text_lower)
    if evidence_count >= 2:
        score += 2
    
    return max(0, min(20, score))

def generate_effectiveness_feedback(purpose_score, organization_score, 
                                   engagement_score, achievement_score):
    """
    Generate specific feedback based on scores.
    
    Args:
        purpose_score: Purpose clarity score
        organization_score: Organization score
        engagement_score: Engagement score
        achievement_score: Achievement score
        
    Returns:
        List of feedback strings
    """
    feedback = []
    
    # Purpose feedback
    if purpose_score >= 18:
        feedback.append("Excellent clarity of purpose")
    elif purpose_score >= 15:
        feedback.append("Good purpose clarity")
    else:
        feedback.append("State your purpose more clearly in the introduction")
    
    # Organization feedback
    if organization_score >= 18:
        feedback.append("Well-organized content with clear structure")
    elif organization_score >= 15:
        feedback.append("Good organization with room for improvement")
    else:
        feedback.append("Use more transition words to improve organization")
    
    # Engagement feedback
    if engagement_score >= 18:
        feedback.append("Highly engaging delivery style")
    elif engagement_score >= 15:
        feedback.append("Good audience engagement techniques")
    else:
        feedback.append("Add more questions or direct address to engage audience")
    
    # Achievement feedback
    if achievement_score >= 18:
        feedback.append("Successfully achieves speech goals")
    elif achievement_score >= 15:
        feedback.append("Generally achieves intended goals")
    else:
        feedback.append("Strengthen conclusion and add clearer takeaways")
    
    return feedback