"""
Speech Analyzer Service - Main Orchestration Layer
Coordinates all speech analysis components and ML models
"""

import asyncio
from typing import Dict, Any, Optional
from pathlib import Path

from app.ml_engine.transcription_engine import TranscriptionEngine
from app.ml_engine.voice_analysis_engine import VoiceAnalysisEngine
from app.ml_engine.content_analysis_engine import ContentAnalysisEngine
from app.ml_engine.speech_evaluation_engine import SpeechEvaluationEngine
from app.utils.logger import get_logger

logger = get_logger(__name__)


class SpeechAnalyzerService:
    """
    Main service for speech analysis
    Coordinates all analysis engines and aggregates results
    """
    
    def __init__(self):
        """Initialize all analysis engines"""
        logger.info("Initializing Speech Analyzer Service...")
        
        self.transcription_engine = TranscriptionEngine()
        self.voice_engine = VoiceAnalysisEngine()
        self.content_engine = ContentAnalysisEngine()
        self.evaluation_engine = SpeechEvaluationEngine()
        
        logger.info("Speech Analyzer Service initialized successfully")
    
    async def analyze_speech(
        self,
        audio_path: str,
        user_id: str,
        topic: str,
        speech_type: str,
        expected_duration: str,
        actual_duration: str,
        gender: str = 'auto'
    ) -> Dict[str, Any]:
        """
        Perform comprehensive speech analysis
        
        Args:
            audio_path: Path to audio file
            user_id: User identifier
            topic: Speech topic
            speech_type: Type of speech
            expected_duration: Expected duration range
            actual_duration: Actual recording duration
            gender: Speaker gender for voice analysis
        
        Returns:
            Complete analysis results dictionary
        """
        logger.info(f"Starting comprehensive analysis for user {user_id}")
        
        try:
            # Step 1: Transcription (required for all other analyses)
            logger.info("Step 1: Transcribing audio...")
            transcription_result = await self.transcription_engine.transcribe(audio_path)
            
            transcript_text = transcription_result['text']
            transcript_with_pauses = transcription_result['text_with_pauses']
            whisper_result = transcription_result['raw_result']
            
            # Step 2: Run analyses in parallel for efficiency
            logger.info("Step 2: Running parallel analyses...")
            
            voice_task = self.voice_engine.analyze(
                audio_path=audio_path,
                gender=gender,
                transcript_result=whisper_result,
                transcript_text=transcript_with_pauses
            )
            
            content_task = self.content_engine.analyze(
                transcript_text=transcript_text,
                transcript_with_pauses=transcript_with_pauses,
                topic=topic,
                audio_path=audio_path
            )
            
            # Execute in parallel
            voice_results, content_results = await asyncio.gather(
                voice_task,
                content_task
            )
            
            # Step 3: Evaluate and generate final scores
            logger.info("Step 3: Calculating final scores...")
            evaluation_results = await self.evaluation_engine.evaluate(
                voice_results=voice_results,
                content_results=content_results,
                transcription_results=transcription_result,
                expected_duration=expected_duration,
                actual_duration=actual_duration
            )
            
            # Step 4: Aggregate all results
            logger.info("Step 4: Aggregating results...")
            final_result = self._aggregate_results(
                transcription=transcription_result,
                voice=voice_results,
                content=content_results,
                evaluation=evaluation_results,
                metadata={
                    'user_id': user_id,
                    'topic': topic,
                    'speech_type': speech_type,
                    'expected_duration': expected_duration,
                    'actual_duration': actual_duration,
                    'gender': gender
                }
            )
            
            logger.info("Analysis completed successfully")
            return final_result
        
        except Exception as e:
            logger.error(f"Analysis failed: {str(e)}", exc_info=True)
            raise
    
    async def quick_analyze(
        self,
        audio_path: str,
        gender: str = 'auto'
    ) -> Dict[str, Any]:
        """
        Quick analysis for preview/testing
        Only runs essential analyses
        """
        logger.info("⚡ Running quick analysis...")
        
        try:
            # Transcription
            transcription_result = await self.transcription_engine.transcribe(audio_path)
            
            # Basic voice analysis
            voice_results = await self.voice_engine.quick_analyze(
                audio_path=audio_path,
                gender=gender
            )
            
            # Basic content metrics
            content_results = await self.content_engine.quick_analyze(
                transcript_text=transcription_result['text']
            )
            
            return {
                'transcription': transcription_result['text'],
                'duration': transcription_result['duration'],
                'word_count': transcription_result['word_count'],
                'filler_word_count': content_results.get('filler_words', {}).get('count', 0),
                'pitch_score': voice_results.get('pitch_analysis', {}).get('score', 0),
                'voice_score': voice_results.get('voice_modulation', {}).get('total_score', 0)
            }
        
        except Exception as e:
            logger.error(f"Quick analysis failed: {str(e)}")
            raise
    
    def _aggregate_results(
        self,
        transcription: Dict,
        voice: Dict,
        content: Dict,
        evaluation: Dict,
        metadata: Dict
    ) -> Dict[str, Any]:
        """Aggregate all analysis results into final response"""
        
        return {
            # Metadata
            'user_id': metadata['user_id'],
            'topic': metadata['topic'],
            'speech_type': metadata['speech_type'],
            'expected_duration': metadata['expected_duration'],
            'actual_duration': metadata['actual_duration'],
            
            # Overall Scores
            'overall_score': evaluation['overall_score'],
            'score_breakdown': evaluation['score_breakdown'],
            
            # Transcription
            'transcription': transcription['text'],
            'transcription_with_pauses': transcription['text_with_pauses'],
            'duration': transcription['duration'],
            'word_count': transcription['word_count'],
            
            # Voice Analysis
            'voice_analysis': {
                'pitch_analysis': voice.get('pitch_analysis', {}),
                'voice_modulation': voice.get('voice_modulation', {}),
                'emphasis': voice.get('emphasis', {}),
                'pronunciation': voice.get('pronunciation', {})
            },
            
            # Content Analysis
            'content_analysis': {
                'filler_words': content.get('filler_words', {}),
                'proficiency': content.get('proficiency', {}),
                'grammar_and_vocabulary': content.get('grammar_vocabulary', {}),
                'speech_structure': content.get('structure', {}),
                'effectiveness': content.get('effectiveness', {}),
                'topic_relevance': content.get('topic_relevance', {})
            },
            
            # Improvement Suggestions
            'suggestions': evaluation.get('improvement_suggestions', []),
            
            # Detailed Feedback
            'feedback': {
                'strengths': evaluation.get('strengths', []),
                'areas_for_improvement': evaluation.get('areas_for_improvement', []),
                'specific_tips': evaluation.get('specific_tips', [])
            }
        }
