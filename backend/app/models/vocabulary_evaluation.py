# File: backend/app/models/vocabulary_evaluation.py

import re
import spacy
from collections import Counter
import json
import os

# Load spaCy language model
nlp = spacy.load('en_core_web_sm')

# Load word frequency data (optional, for advanced scoring)
WORD_FREQ_PATH = os.path.join(os.path.dirname(__file__), '..', 'word_frequency_metadata.json')

def load_word_frequencies():
    """Load word frequency data if available"""
    try:
        if os.path.exists(WORD_FREQ_PATH):
            with open(WORD_FREQ_PATH, 'r') as f:
                return json.load(f)
    except:
        pass
    return None

WORD_FREQ_DATA = load_word_frequencies()

def evaluate_speech(transcription_result, transcription_text, audio_path, speech_type):
    """
    Main function to evaluate vocabulary and grammar.
    
    Args:
        transcription_result: Whisper result (not used here but kept for compatibility)
        transcription_text: Full speech text
        audio_path: Audio file path (not used here)
        speech_type: Type of speech (not used here)
        
    Returns:
        Dictionary with vocabulary scores and analysis
    """
    # Clean text (remove pause markers)
    clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', transcription_text)
    
    # Analyze grammar and word selection
    result = analyze_grammar_and_word_selection(clean_text)
    
    if result is None:
        # Return default scores if analysis fails
        return {
            'vocabulary_score': 50.0,
            'grammar_score': 25,
            'word_selection_score': 25,
            'lexical_diversity': 0.5,
            'unique_words': 0,
            'advanced_vocab_count': 0,
            'feedback': ['Unable to analyze vocabulary. Please try again.']
        }
    
    # Calculate overall vocabulary score (0-100 scale for this model)
    # Then we'll convert to 0-20 in main.py
    vocabulary_score = result['grammar_score'] + result['word_selection_score']
    
    return {
        'vocabulary_score': vocabulary_score,
        'grammar_score': result['grammar_score'],
        'word_selection_score': result['word_selection_score'],
        'lexical_diversity': result['lexical_diversity'],
        'unique_words': result['unique_words'],
        'repeated_words': result.get('repeated_words', []),
        'advanced_vocab_count': result['advanced_vocab_count'],
        'grammar_issues': result.get('grammar_issues', 0),
        'feedback': result['feedback']
    }

def analyze_grammar_and_word_selection(text):
    """
    Analyze grammar correctness and word selection quality.
    
    Args:
        text: Speech text (cleaned)
        
    Returns:
        Dictionary with detailed analysis
    """
    if not text or len(text.strip()) < 10:
        return None
    
    try:
        # Clean text further
        clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)
        
        # Process with spaCy
        doc = nlp(clean_text)
        
        # === GRAMMAR ANALYSIS ===
        grammar_issues = 0
        subject_verb_issues = 0
        preposition_issues = 0
        
        sentences = list(doc.sents)
        total_sentences = len(sentences)
        
        # Check each sentence for grammar issues
        for sent in sentences:
            # Find subjects and verbs
            subjects = [token for token in sent if "subj" in token.dep_]
            verbs = [token for token in sent if token.pos_ == "VERB"]
            
            # Check subject-verb agreement
            if subjects and verbs:
                for subj in subjects:
                    for verb in verbs:
                        # If subject and verb are far apart, might be an issue
                        if subj.is_ancestor(verb) and abs(subj.i - verb.i) > 5:
                            subject_verb_issues += 1
            
            # Check preposition usage
            for token in sent:
                if token.dep_ == "prep" and token.head.pos_ in ["VERB", "NOUN"]:
                    # Preposition without object
                    if len([child for child in token.children]) == 0:
                        preposition_issues += 1
        
        grammar_issues = subject_verb_issues + preposition_issues
        
        # === WORD SELECTION ANALYSIS ===
        # Get all words (excluding stopwords)
        words = [token.text.lower() for token in doc 
                if token.is_alpha and not token.is_stop]
        total_words = len(words)
        
        if total_words == 0:
            return None
        
        # Calculate lexical diversity (unique words / total words)
        unique_words = len(set(words))
        lexical_diversity = unique_words / total_words
        
        # Find repeated words (used more than 3 times)
        word_counter = Counter(words)
        repeated_words = [word for word, count in word_counter.items() if count > 3]
        
        # Count advanced vocabulary
        # Words longer than 7 letters, excluding common basic words
        basic_words = {
            "good", "bad", "nice", "thing", "stuff", "big", "small", 
            "very", "really", "like", "said", "went", "got", "put", 
            "took", "made", "did", "get", "know", "people", "because",
            "something", "anything", "everything", "nothing"
        }
        
        advanced_vocab_count = 0
        for word in set(words):
            if len(word) > 7 and word not in basic_words:
                advanced_vocab_count += 1
        
        # === CALCULATE SCORES ===
        
        # Grammar score (0-50 points)
        grammar_score = 0
        
        if total_sentences > 0:
            grammar_issue_ratio = grammar_issues / total_sentences
            
            if grammar_issue_ratio < 0.1:       # Less than 10% issues
                grammar_score = 50
            elif grammar_issue_ratio < 0.2:     # 10-20% issues
                grammar_score = 40
            elif grammar_issue_ratio < 0.3:     # 20-30% issues
                grammar_score = 30
            elif grammar_issue_ratio < 0.5:     # 30-50% issues
                grammar_score = 20
            else:                                # 50%+ issues
                grammar_score = 10
        
        # Word selection score (0-50 points)
        word_selection_score = 0
        
        # Lexical diversity component (0-20 points)
        if lexical_diversity > 0.7:
            word_selection_score += 20
        elif lexical_diversity > 0.5:
            word_selection_score += 15
        elif lexical_diversity > 0.3:
            word_selection_score += 10
        else:
            word_selection_score += 5
        
        # Advanced vocabulary component (0-20 points)
        if total_words > 0:
            advanced_ratio = advanced_vocab_count / total_words
            if advanced_ratio > 0.2:
                word_selection_score += 20
            elif advanced_ratio > 0.1:
                word_selection_score += 15
            elif advanced_ratio > 0.05:
                word_selection_score += 10
            else:
                word_selection_score += 5
        
        # Penalty for too many repeated words (0-10 points penalty)
        if len(repeated_words) > 5:
            word_selection_score = max(0, word_selection_score - 10)
        elif len(repeated_words) > 3:
            word_selection_score = max(0, word_selection_score - 5)
        
        # === GENERATE FEEDBACK ===
        feedback = []
        
        # Grammar feedback
        if grammar_score >= 40:
            feedback.append("Grammar is generally correct and well-structured")
        elif grammar_score >= 20:
            feedback.append("Some grammatical issues detected. Review subject-verb agreement and preposition usage")
        else:
            feedback.append("Several grammatical errors detected. Consider reviewing basic grammar rules")
        
        # Vocabulary diversity feedback
        if lexical_diversity > 0.5:
            feedback.append("Good vocabulary diversity and word choice")
        else:
            feedback.append("Consider using a wider range of vocabulary to enhance your speech")
        
        # Repeated words feedback
        if len(repeated_words) > 3:
            top_repeated = repeated_words[:3]
            feedback.append(f"Repetitive use of words detected: {', '.join(top_repeated)}...")
        
        # Advanced vocabulary feedback
        if advanced_vocab_count > 10:
            feedback.append("Excellent use of advanced vocabulary")
        elif advanced_vocab_count > 5:
            feedback.append("Good use of complex words. Consider incorporating more advanced vocabulary")
        else:
            feedback.append("Consider using more sophisticated vocabulary where appropriate")
        
        # Calculate combined score
        combined_score = grammar_score + word_selection_score
        
        return {
            'grammar_score': grammar_score,
            'word_selection_score': word_selection_score,
            'combined_score': combined_score,
            'lexical_diversity': round(lexical_diversity, 2),
            'unique_words': unique_words,
            'repeated_words': repeated_words[:5],  # Top 5 most repeated
            'advanced_vocab_count': advanced_vocab_count,
            'grammar_issues': grammar_issues,
            'feedback': feedback
        }
    
    except Exception as e:
        print(f"Error in grammar and word selection analysis: {e}")
        return None
