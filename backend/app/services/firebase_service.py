"""
Firebase Service - Cloud Storage and Firestore Integration
Handles all Firebase operations including file uploads and database operations
"""

import os
from typing import Dict, Any, List, Optional
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore, storage
from pathlib import Path

from app.core.config import get_settings
from app.utils.logger import get_logger

settings = get_settings()
logger = get_logger(__name__)


class FirebaseService:
    """Firebase integration service"""
    
    def __init__(self):
        """Initialize Firebase Admin SDK"""
        if not firebase_admin._apps:
            self._initialize_firebase()
        
        self.db = firestore.client()
        self.bucket = storage.bucket()
        logger.info("Firebase Service initialized")
    
    def _initialize_firebase(self):
        """Initialize Firebase with service account credentials"""
        try:
            # Prepare private key
            private_key = settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n")
            
            # Service account configuration
            service_account = {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key_id": settings.FIREBASE_PRIVATE_KEY_ID,
                "private_key": private_key,
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "client_id": "113550497977436500236",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": f"https://www.googleapis.com/robot/v1/metadata/x509/{settings.FIREBASE_CLIENT_EMAIL}",
                "universe_domain": "googleapis.com"
            }
            
            cred = credentials.Certificate(service_account)
            firebase_admin.initialize_app(cred, {
                'storageBucket': settings.FIREBASE_STORAGE_BUCKET
            })
            
            logger.info("Firebase Admin SDK initialized successfully")
        
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {str(e)}")
            raise
    
    async def upload_audio(
        self,
        file_path: str,
        user_id: str,
        filename: str
    ) -> str:
        """
        Upload audio file to Firebase Storage
        
        Args:
            file_path: Local path to audio file
            user_id: User identifier
            filename: Original filename
        
        Returns:
            Public URL of uploaded file
        """
        try:
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            file_ext = Path(filename).suffix
            storage_path = f"speeches/{user_id}/{timestamp}{file_ext}"
            
            # Upload file
            blob = self.bucket.blob(storage_path)
            blob.upload_from_filename(file_path)
            
            # Make publicly accessible
            blob.make_public()
            
            logger.info(f"File uploaded to: {storage_path}")
            return blob.public_url
        
        except Exception as e:
            logger.error(f"Failed to upload file: {str(e)}")
            raise
    
    async def save_speech_analysis(
        self,
        user_id: str,
        analysis_data: Dict[str, Any],
        topic: str,
        speech_type: str,
        actual_duration: str
    ) -> str:
        """
        Save speech analysis to Firestore
        
        Args:
            user_id: User identifier
            analysis_data: Complete analysis results
            topic: Speech topic
            speech_type: Type of speech
            actual_duration: Recording duration
        
        Returns:
            Document ID of saved speech
        """
        try:
            # Prepare document data
            doc_data = {
                'user_id': user_id,
                'topic': topic,
                'speech_type': speech_type,
                'actual_duration': actual_duration,
                'recorded_at': firestore.SERVER_TIMESTAMP,
                'overall_score': analysis_data.get('overall_score', 0),
                'transcription': analysis_data.get('transcription', ''),
                'audio_url': analysis_data.get('audio_url', ''),
                
                # Score breakdown
                'speech_development_score': analysis_data['score_breakdown'].get('speech_development', 0),
                'proficiency_score': analysis_data['score_breakdown'].get('proficiency', 0),
                'voice_analysis_score': analysis_data['score_breakdown'].get('voice_analysis', 0),
                'effectiveness_score': analysis_data['score_breakdown'].get('effectiveness', 0),
                'vocabulary_evaluation_score': analysis_data['score_breakdown'].get('vocabulary', 0),
                
                # Detailed metrics
                'voice_metrics': analysis_data.get('voice_analysis', {}),
                'content_metrics': analysis_data.get('content_analysis', {}),
                'suggestions': analysis_data.get('suggestions', []),
                'feedback': analysis_data.get('feedback', {})
            }
            
            # Save to Firestore
            user_ref = self.db.collection('users').document(user_id)
            speech_ref = user_ref.collection('speeches').document()
            speech_ref.set(doc_data)
            
            # Update user statistics
            await self._update_user_stats(user_id, analysis_data['overall_score'])
            
            logger.info(f"Saved speech analysis: {speech_ref.id}")
            return speech_ref.id
        
        except Exception as e:
            logger.error(f"Failed to save analysis: {str(e)}")
            raise
    
    async def _update_user_stats(self, user_id: str, new_score: float):
        """Update user statistics after new speech"""
        try:
            user_ref = self.db.collection('users').document(user_id)
            user_doc = user_ref.get()
            
            if user_doc.exists:
                data = user_doc.to_dict()
                total_speeches = data.get('totalSpeeches', 0)
                current_avg = data.get('averageScore', 0)
                
                # Calculate new average
                new_total = total_speeches + 1
                new_avg = ((current_avg * total_speeches) + new_score) / new_total
                
                user_ref.update({
                    'totalSpeeches': new_total,
                    'averageScore': round(new_avg, 2),
                    'lastSpeechDate': firestore.SERVER_TIMESTAMP
                })
                
                logger.info(f"Updated stats for user {user_id}")
        
        except Exception as e:
            logger.warning(f"Failed to update user stats: {str(e)}")
    
    async def get_user_speeches(
        self,
        user_id: str,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Retrieve user's speech history"""
        try:
            speeches_ref = (
                self.db.collection('users')
                .document(user_id)
                .collection('speeches')
                .order_by('recorded_at', direction=firestore.Query.DESCENDING)
                .limit(limit)
            )
            
            docs = speeches_ref.stream()
            speeches = []
            
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                speeches.append(data)
            
            return speeches
        
        except Exception as e:
            logger.error(f"Failed to retrieve speeches: {str(e)}")
            raise
    
    async def get_user_statistics(self, user_id: str) -> Dict[str, Any]:
        """Get user's overall statistics"""
        try:
            user_ref = self.db.collection('users').document(user_id)
            user_doc = user_ref.get()
            
            if not user_doc.exists:
                return {
                    'totalSpeeches': 0,
                    'averageScore': 0,
                    'lastSpeechDate': None
                }
            
            data = user_doc.to_dict()
            return {
                'totalSpeeches': data.get('totalSpeeches', 0),
                'averageScore': data.get('averageScore', 0),
                'lastSpeechDate': data.get('lastSpeechDate'),
                'isPremium': data.get('isPremium', False)
            }
        
        except Exception as e:
            logger.error(f"Failed to retrieve stats: {str(e)}")
            raise
