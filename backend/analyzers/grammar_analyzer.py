import re
from collections import Counter
from nltk.tokenize import word_tokenize


class GrammarAnalyzer:
    """Analyzer for grammar and vocabulary"""
    
    def __init__(self):
        self.basic_words = set([
            "good", "bad", "nice", "thing", "stuff", "big", "small", "very", "really",
            "like", "said", "went", "got", "put", "took", "made", "did", "get", "know"
        ])
    
    async def analyze(self, text: str, nlp_model) -> dict:
        """
        Analyze grammar and word selection
        
        Args:
            text: Transcribed text
            nlp_model: spaCy NLP model
            
        Returns:
            dict with grammar and vocabulary analysis
        """
        if isinstance(text, dict):
            text = text.get('text', '')

        try:
            # Clean text (remove pause markers)
            clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)

            doc = nlp_model(clean_text)

            # Grammar analysis
            grammar_issues = 0
            subject_verb_issues = 0
            preposition_issues = 0

            sentences = list(doc.sents)
            total_sentences = len(sentences)

            for sent in sentences:
                subjects = [token for token in sent if "subj" in token.dep_]
                verbs = [token for token in sent if token.pos_ == "VERB"]

                if subjects and verbs:
                    for subj in subjects:
                        for verb in verbs:
                            if subj.is_ancestor(verb) and abs(subj.i - verb.i) > 5:
                                subject_verb_issues += 1

                for token in sent:
                    if token.dep_ == "prep" and token.head.pos_ in ["VERB", "NOUN"]:
                        if len([child for child in token.children]) == 0:
                            preposition_issues += 1

            grammar_issues = subject_verb_issues + preposition_issues

            # Vocabulary analysis
            words = [token.text.lower() for token in doc if token.is_alpha and not token.is_stop]
            total_words = len(words)

            if total_words > 0:
                unique_words = len(set(words))
                lexical_diversity = unique_words / total_words
            else:
                lexical_diversity = 0

            word_counter = Counter(words)
            repeated_words = [word for word, count in word_counter.items() if count > 3]

            advanced_vocab_count = 0
            for word in set(words):
                if len(word) > 7 and word not in self.basic_words:
                    advanced_vocab_count += 1

            # Calculate scores
            grammar_score = self._calculate_grammar_score(grammar_issues, total_sentences)
            word_selection_score = self._calculate_word_score(
                lexical_diversity,
                advanced_vocab_count,
                total_words,
                repeated_words
            )

            # Generate feedback
            feedback = self._generate_feedback(
                grammar_score,
                lexical_diversity,
                repeated_words,
                advanced_vocab_count
            )

            combined_score = grammar_score + word_selection_score

            return {
                'grammar_score': grammar_score,
                'word_selection_score': word_selection_score,
                'combined_score': combined_score,
                'lexical_diversity': round(lexical_diversity, 2),
                'unique_words': len(set(words)) if words else 0,
                'repeated_words': repeated_words[:5],
                'advanced_vocab_count': advanced_vocab_count,
                'grammar_issues': grammar_issues,
                'feedback': feedback
            }

        except Exception as e:
            print(f"Error in grammar and word selection analysis: {e}")
            return {
                'grammar_score': 25,
                'word_selection_score': 25,
                'combined_score': 50,
                'feedback': ['Analysis error occurred']
            }
    
    def _calculate_grammar_score(self, grammar_issues, total_sentences):
        """Calculate grammar score based on issues"""
        if total_sentences == 0:
            return 25
        
        grammar_issue_ratio = grammar_issues / total_sentences
        if grammar_issue_ratio < 0.1:
            return 50
        elif grammar_issue_ratio < 0.2:
            return 40
        elif grammar_issue_ratio < 0.3:
            return 30
        elif grammar_issue_ratio < 0.5:
            return 20
        else:
            return 10
    
    def _calculate_word_score(self, lexical_diversity, advanced_vocab_count, total_words, repeated_words):
        """Calculate word selection score"""
        score = 0
        
        # Lexical diversity
        if lexical_diversity > 0.7:
            score += 20
        elif lexical_diversity > 0.5:
            score += 15
        elif lexical_diversity > 0.3:
            score += 10
        else:
            score += 5

        # Advanced vocabulary
        if total_words > 0:
            advanced_ratio = advanced_vocab_count / total_words
            if advanced_ratio > 0.2:
                score += 20
            elif advanced_ratio > 0.1:
                score += 15
            elif advanced_ratio > 0.05:
                score += 10
            else:
                score += 5

        # Penalties for repetition
        if len(repeated_words) > 5:
            score = max(0, score - 10)
        elif len(repeated_words) > 3:
            score = max(0, score - 5)
        
        return score
    
    def _generate_feedback(self, grammar_score, lexical_diversity, repeated_words, advanced_vocab_count):
        """Generate feedback messages"""
        feedback = []

        if grammar_score >= 40:
            feedback.append("Grammar is generally correct and well structured.")
        elif grammar_score >= 20:
            feedback.append("Some grammatical issues detected. Pay attention to subject-verb agreement and preposition usage.")
        else:
            feedback.append("Several grammatical errors detected. Consider reviewing basic grammar rules.")

        if lexical_diversity > 0.5:
            feedback.append("Good vocabulary diversity and word choice.")
        else:
            feedback.append("Consider using a wider range of vocabulary to enhance your speech.")

        if len(repeated_words) > 3:
            feedback.append(f"Repetitive use of words detected: {', '.join(repeated_words[:3])}...")

        if advanced_vocab_count > 10:
            feedback.append("Excellent use of advanced vocabulary.")
        elif advanced_vocab_count > 5:
            feedback.append("Good use of complex words. Consider incorporating more advanced vocabulary.")
        else:
            feedback.append("Consider using more sophisticated vocabulary where appropriate.")

        return feedback