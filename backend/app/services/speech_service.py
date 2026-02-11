import asyncio
import whisper
import torch
from typing import Dict, Any, Optional
from datetime import datetime
import spacy

from analyzers.transcription_analyzer import TranscriptionAnalyzer
from analyzers.filler_word_analyzer import FillerWordAnalyzer
from analyzers.pronunciation_analyzer import PronunciationAnalyzer
from analyzers.voice_modulation_analyzer import VoiceModulationAnalyzer
from analyzers.grammar_analyzer import GrammarAnalyzer
from analyzers.structure_analyzer import StructureAnalyzer
from analyzers.emphasis_analyzer import EmphasisAnalyzer
from analyzers.topic_relevance_analyzer import TopicRelevanceAnalyzer
from analyzers.proficiency_calculator import ProficiencyCalculator
from app.utils.logger import setup_logger
from app.utils.exceptions import AnalysisError
from config.settings import settings

logger = setup_logger(__name__)

class SpeechAnalysisService:
    _whisper_model_cache = None
    _nlp_model_cache = None
    
    async def initialize(self):
        """Initialize models (cached)"""
        # Check cache first
        if SpeechAnalysisService._whisper_model_cache is not None:
            self.whisper_model = SpeechAnalysisService._whisper_model_cache
            self.nlp_model = SpeechAnalysisService._nlp_model_cache
            logger.info("Using cached models")
            return
        
        # Load models
        logger.info("Loading ML models...")
        
        self.whisper_model = whisper.load_model(settings.DEFAULT_MODEL)
        SpeechAnalysisService._whisper_model_cache = self.whisper_model
    
    def __init__(self):
        self.whisper_model = None
        self.nlp_model = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        
        # Initialize analyzers
        self.transcription_analyzer = TranscriptionAnalyzer()
        self.filler_analyzer = FillerWordAnalyzer()
        self.pronunciation_analyzer = PronunciationAnalyzer()
        self.voice_analyzer = VoiceModulationAnalyzer()
        self.grammar_analyzer = GrammarAnalyzer()
        self.structure_analyzer = StructureAnalyzer()
        self.emphasis_analyzer = EmphasisAnalyzer()
        self.topic_analyzer = TopicRelevanceAnalyzer()
        self.proficiency_calculator = ProficiencyCalculator()
        
        logger.info(f"Speech Analysis Service initialized (device: {self.device})")
    
    async def initialize(self):
        """Initialize models and resources"""
        try:
            logger.info("Loading ML models...")
            
            # Load Whisper model
            self.whisper_model = whisper.load_model(settings.DEFAULT_MODEL)
            logger.info(f"Whisper model '{settings.DEFAULT_MODEL}' loaded")
            
            # Load spaCy model
            try:
                self.nlp_model = spacy.load('en_core_web_sm')
                logger.info("spaCy model loaded")
            except:
                logger.warning("spaCy model not found, downloading...")
                import subprocess
                subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
                self.nlp_model = spacy.load('en_core_web_sm')
            
            # Download NLTK resources
            await self._download_nltk_resources()
            
            logger.info("All models initialized successfully")
            
        except Exception as e:
            logger.error(f"Model initialization failed: {e}")
            raise AnalysisError(f"Failed to initialize models: {str(e)}")
    
    async def _download_nltk_resources(self):
        """Download required NLTK resources"""
        import nltk
        
        resources = ['punkt', 'stopwords', 'wordnet', 'averaged_perceptron_tagger_eng']
        
        for resource in resources:
            try:
                nltk.download(resource, quiet=True)
            except Exception as e:
                logger.warning(f"Failed to download NLTK resource {resource}: {e}")
    
    async def analyze(
        self,
        audio_path: str,
        topic: Optional[str] = None,
        expected_duration: str = "5-7 minutes",
        gender: str = "auto",
        analysis_depth: str = "standard"
    ) -> Dict[str, Any]:
        """
        Perform comprehensive speech analysis
        
        Args:
            audio_path: Path to audio file
            topic: Optional topic for relevance analysis
            expected_duration: Expected speech duration
            gender: Speaker gender (auto, male, female)
            analysis_depth: Analysis depth (basic, standard, advanced)
        
        Returns:
            Complete analysis results dictionary
        """
        start_time = datetime.now()
        
        try:
            logger.info(f"Starting {analysis_depth} analysis")
            
            # Step 1: Transcription
            logger.info("Step 1/8: Transcribing audio...")
            transcription_result = await self._transcribe(audio_path)
            
            # Step 2: Filler Word Detection
            logger.info("Step 2/8: Analyzing filler words...")
            filler_analysis = await self._analyze_filler_words(transcription_result)
            
            # Step 3: Proficiency (Pauses & Fluency)
            logger.info("Step 3/8: Evaluating proficiency...")
            proficiency_analysis = await self._analyze_proficiency(
                transcription_result,
                filler_analysis,
                expected_duration
            )
            
            # Step 4: Voice Modulation
            logger.info("Step 4/8: Analyzing voice modulation...")
            voice_analysis = await self._analyze_voice(audio_path)
            
            # Step 5: Grammar & Vocabulary
            logger.info("Step 5/8: Checking grammar and vocabulary...")
            grammar_analysis = await self._analyze_grammar(
                transcription_result['text']
            )
            
            # Step 6: Speech Structure
            logger.info("Step 6/8: Analyzing speech structure...")
            structure_analysis = await self._analyze_structure(
                transcription_result['text']
            )
            
            # Step 7: Pronunciation (if advanced)
            pronunciation_analysis = {}
            if analysis_depth in ["standard", "advanced"]:
                logger.info("Step 7/8: Analyzing pronunciation...")
                pronunciation_analysis = await self._analyze_pronunciation(
                    audio_path,
                    transcription_result
                )
            
            # Step 8: Topic Relevance & Emphasis (if topic provided and advanced)
            topic_analysis = {}
            emphasis_analysis = {}
            
            if analysis_depth == "advanced":
                if topic and settings.ENABLE_TOPIC_RELEVANCE:
                    logger.info("Step 8a/8: Analyzing topic relevance...")
                    topic_analysis = await self._analyze_topic_relevance(
                        transcription_result['text'],
                        topic
                    )
                
                if settings.ENABLE_EMPHASIS_ANALYSIS:
                    logger.info("Step 8b/8: Analyzing emphasis...")
                    emphasis_analysis = await self._analyze_emphasis(
                        audio_path,
                        transcription_result
                    )
            
            # Calculate overall scores
            logger.info("Calculating final scores...")
            overall_scores = self._calculate_overall_scores(
                filler_analysis,
                proficiency_analysis,
                voice_analysis,
                grammar_analysis,
                structure_analysis,
                pronunciation_analysis,
                emphasis_analysis,
                topic_analysis
            )
            
            # Generate improvement suggestions
            suggestions = self._generate_suggestions(
                overall_scores,
                filler_analysis,
                proficiency_analysis,
                voice_analysis,
                grammar_analysis,
                structure_analysis,
                pronunciation_analysis
            )
            
            processing_time = (datetime.now() - start_time).total_seconds()
            logger.info(f"Analysis completed in {processing_time:.2f}s")
            
            # Compile results
            return {
                "scores": overall_scores,
                "transcription": transcription_result['text'],
                "detailed_analysis": {
                    "transcription": {
                        "full_text": transcription_result['text'],
                        "duration": transcription_result.get('duration', 0),
                        "word_count": len(transcription_result['text'].split())
                    },
                    "filler_words": filler_analysis,
                    "proficiency": proficiency_analysis,
                    "voice_modulation": voice_analysis,
                    "grammar_and_vocabulary": grammar_analysis,
                    "structure": structure_analysis,
                    "pronunciation": pronunciation_analysis,
                    "emphasis": emphasis_analysis,
                    "topic_relevance": topic_analysis
                },
                "summary": {
                    "overall_score": overall_scores.get('overall', 0),
                    "performance_level": self._get_performance_level(
                        overall_scores.get('overall', 0)
                    ),
                    "top_strengths": self._identify_strengths(overall_scores),
                    "areas_for_improvement": suggestions
                },
                "metadata": {
                    "analysis_depth": analysis_depth,
                    "processing_time": round(processing_time, 2),
                    "timestamp": datetime.now().isoformat(),
                    "model_version": settings.APP_VERSION
                }
            }
            
        except Exception as e:
            logger.error(f"Analysis failed: {e}")
            raise AnalysisError(f"Speech analysis failed: {str(e)}")
    
    async def _transcribe(self, audio_path: str) -> Dict[str, Any]:
        """Transcribe audio with word timestamps"""
        return await self.transcription_analyzer.transcribe(
            self.whisper_model,
            audio_path
        )
    
    async def _analyze_filler_words(self, transcription_result: Dict) -> Dict:
        """Analyze filler word usage"""
        return await self.filler_analyzer.analyze(transcription_result)
    
    async def _analyze_proficiency(
        self,
        transcription_result: Dict,
        filler_analysis: Dict,
        expected_duration: str
    ) -> Dict:
        """Analyze speech proficiency including pauses"""
        return await self.proficiency_calculator.calculate(
            transcription_result,
            filler_analysis,
            expected_duration
        )
    
    async def _analyze_voice(self, audio_path: str) -> Dict:
        """Analyze voice modulation"""
        return await self.voice_analyzer.analyze(audio_path)
    
    async def _analyze_grammar(self, text: str) -> Dict:
        """Analyze grammar and vocabulary"""
        return await self.grammar_analyzer.analyze(text, self.nlp_model)
    
    async def _analyze_structure(self, text: str) -> Dict:
        """Analyze speech structure"""
        return await self.structure_analyzer.analyze(text, self.nlp_model)
    
    async def _analyze_pronunciation(
        self,
        audio_path: str,
        transcription_result: Dict
    ) -> Dict:
        """Analyze pronunciation quality"""
        return await self.pronunciation_analyzer.analyze(
            audio_path,
            transcription_result,
            self.whisper_model
        )
    
    async def _analyze_topic_relevance(self, text: str, topic: str) -> Dict:
        """Analyze topic relevance"""
        return await self.topic_analyzer.analyze(text, topic)
    
    async def _analyze_emphasis(
        self,
        audio_path: str,
        transcription_result: Dict
    ) -> Dict:
        """Analyze vocal emphasis"""
        return await self.emphasis_analyzer.analyze(
            audio_path,
            transcription_result
        )
    
    def _calculate_overall_scores(self, *analyses) -> Dict[str, float]:
        """Calculate weighted overall scores"""
        filler, proficiency, voice, grammar, structure, pronunciation, emphasis, topic = analyses
        
        # Component scores
        scores = {
            "filler_words": filler.get('Score', 5),
            "proficiency": proficiency.get('final_score', 10),
            "voice_modulation": voice.get('scores', {}).get('total_score', 10),
            "grammar": grammar.get('grammar_score', 25),
            "vocabulary": grammar.get('word_selection_score', 25),
            "structure": structure.get('structure_score', 50),
            "pronunciation": pronunciation.get('pronunciation_score', 50) if pronunciation else 50,
            "emphasis": emphasis.get('emphasis_score', 50) if emphasis else 50,
            "topic_relevance": topic.get('topic_relevance_score', 50) if topic else None
        }
        
        # Calculate overall (weighted average)
        weights = {
            "filler_words": 0.10,
            "proficiency": 0.10,
            "voice_modulation": 0.15,
            "grammar": 0.15,
            "vocabulary": 0.10,
            "structure": 0.15,
            "pronunciation": 0.15,
            "emphasis": 0.10
        }
        
        if scores["topic_relevance"] is not None:
            weights = {k: v * 0.9 for k, v in weights.items()}
            weights["topic_relevance"] = 0.10
        
        # Normalize scores to 0-100
        normalized_scores = {}
        for key, value in scores.items():
            if value is not None:
                if key in ["filler_words", "proficiency"]:
                    normalized_scores[key] = (value / 20) * 100  # /20 max
                elif key == "voice_modulation":
                    normalized_scores[key] = (value / 20) * 100  # /20 max
                elif key in ["grammar", "vocabulary"]:
                    normalized_scores[key] = (value / 50) * 100  # /50 max
                else:
                    normalized_scores[key] = value  # already 0-100
        
        # Calculate weighted overall
        overall = sum(
            normalized_scores.get(key, 50) * weight
            for key, weight in weights.items()
        )
        
        return {
            **normalized_scores,
            "overall": round(overall, 1)
        }
    
    def _get_performance_level(self, score: float) -> str:
        """Get performance level from score"""
        if score >= 90:
            return "Outstanding"
        elif score >= 80:
            return "Excellent"
        elif score >= 70:
            return "Very Good"
        elif score >= 60:
            return "Good"
        elif score >= 50:
            return "Fair"
        else:
            return "Needs Improvement"
    
    def _identify_strengths(self, scores: Dict[str, float]) -> list:
        """Identify top 3 strengths"""
        strength_map = {
            "filler_words": "Minimal filler words",
            "proficiency": "Excellent fluency",
            "voice_modulation": "Engaging voice modulation",
            "grammar": "Strong grammar",
            "vocabulary": "Rich vocabulary",
            "structure": "Well-structured speech",
            "pronunciation": "Clear pronunciation",
            "emphasis": "Effective emphasis",
            "topic_relevance": "Strong topic relevance"
        }
        
        # Sort by score, exclude overall
        sorted_scores = sorted(
            [(k, v) for k, v in scores.items() if k != "overall" and v is not None],
            key=lambda x: x[1],
            reverse=True
        )
        
        return [strength_map.get(k, k) for k, _ in sorted_scores[:3]]
    
    def _generate_suggestions(self, scores, *analyses) -> list:
        """Generate improvement suggestions"""
        suggestions = []
        
        # Find weak areas (scores < 60)
        weak_areas = {k: v for k, v in scores.items() if k != "overall" and v is not None and v < 60}
        
        # Sort by score (lowest first)
        sorted_weak = sorted(weak_areas.items(), key=lambda x: x[1])
        
        suggestion_map = {
            "filler_words": "Reduce filler words like 'um', 'uh', and 'like' for better fluency",
            "proficiency": "Work on reducing pauses and improving speech flow",
            "voice_modulation": "Practice varying your pitch and volume for better engagement",
            "grammar": "Review grammar fundamentals and sentence structure",
            "vocabulary": "Expand your vocabulary with more sophisticated words",
            "structure": "Improve speech organization with clear introduction, body, and conclusion",
            "pronunciation": "Focus on clearer articulation of words",
            "emphasis": "Emphasize key points more effectively with voice variation",
            "topic_relevance": "Stay more focused on the main topic throughout your speech"
        }
        
        # Add suggestions for weak areas
        for area, _ in sorted_weak[:3]:
            if area in suggestion_map:
                suggestions.append(suggestion_map[area])
        
        return suggestions
    
    async def cleanup(self):
        """Cleanup resources"""
        logger.info("🧹 Cleaning up Speech Analysis Service...")
        # Cleanup code here
        self.whisper_model = None
        self.nlp_model = None
