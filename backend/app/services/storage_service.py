"""
Storage Service
Handles data persistence using Firebase Firestore
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import uuid

from firebase_admin import credentials, firestore, initialize_app
import firebase_admin

from utils.logger import setup_logger
from utils.exceptions import StorageError
from config.settings import settings

logger = setup_logger(__name__)

class StorageService:
    """Service for data storage operations using Firebase"""
    
    def __init__(self):
        self.db = None
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK"""
        try:
            # Check if already initialized
            if firebase_admin._apps:
                self.db = firestore.client()
                logger.info("✅ Firebase already initialized")
                return
            
            # Firebase credentials
            private_key = settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n")
            
            service_account_key = {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key_id": settings.FIREBASE_PRIVATE_KEY_ID,
                "private_key": private_key,
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "universe_domain": "googleapis.com"
            }
            
            cred = credentials.Certificate(service_account_key)
            initialize_app(cred, {
                'storageBucket': settings.FIREBASE_STORAGE_BUCKET
            })
            
            self.db = firestore.client()
            logger.info("✅ Firebase initialized successfully")
            
        except Exception as e:
            logger.error(f"❌ Firebase initialization failed: {e}")
            raise StorageError(f"Failed to initialize storage: {str(e)}")
    
    async def save_analysis(
        self,
        user_id: str,
        speech_title: Optional[str],
        results: Dict[str, Any]
    ) -> str:
        """
        Save analysis results to Firestore
        
        Args:
            user_id: User identifier
            speech_title: Optional speech title
            results: Analysis results
        
        Returns:
            Analysis ID
        """
        try:
            analysis_id = str(uuid.uuid4())
            
            doc_data = {
                "analysis_id": analysis_id,
                "user_id": user_id,
                "speech_title": speech_title or "Untitled Speech",
                "timestamp": datetime.now(),
                "scores": results.get("scores", {}),
                "summary": results.get("summary", {}),
                "metadata": results.get("metadata", {}),
                "transcription_preview": results.get("transcription", "")[:500]  # First 500 chars
            }
            
            # Save main document
            self.db.collection('analyses').document(analysis_id).set(doc_data)
            
            # Save detailed analysis in subcollection
            self.db.collection('analyses').document(analysis_id).collection('details').document('full').set({
                "detailed_analysis": results.get("detailed_analysis", {}),
                "full_transcription": results.get("transcription", "")
            })
            
            logger.info(f"✅ Analysis saved: {analysis_id}")
            
            return analysis_id
            
        except Exception as e:
            logger.error(f"❌ Failed to save analysis: {e}")
            raise StorageError(f"Failed to save analysis: {str(e)}")
    
    async def get_analysis(
        self,
        analysis_id: str,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Retrieve analysis by ID
        
        Args:
            analysis_id: Analysis identifier
            user_id: User identifier (for access control)
        
        Returns:
            Analysis data or None
        """
        try:
            doc = self.db.collection('analyses').document(analysis_id).get()
            
            if not doc.exists:
                return None
            
            data = doc.to_dict()
            
            # Verify user access
            if data.get('user_id') != user_id:
                raise StorageError("Unauthorized access")
            
            # Get detailed analysis
            details_doc = self.db.collection('analyses').document(analysis_id).collection('details').document('full').get()
            
            if details_doc.exists:
                details = details_doc.to_dict()
                data['detailed_analysis'] = details.get('detailed_analysis', {})
                data['full_transcription'] = details.get('full_transcription', '')
            
            return data
            
        except Exception as e:
            logger.error(f"❌ Failed to retrieve analysis: {e}")
            raise StorageError(f"Failed to retrieve analysis: {str(e)}")
    
    async def get_user_history(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get user's analysis history
        
        Args:
            user_id: User identifier
            limit: Maximum number of results
            offset: Result offset for pagination
        
        Returns:
            List of analyses
        """
        try:
            query = self.db.collection('analyses')\
                .where('user_id', '==', user_id)\
                .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                .limit(limit)\
                .offset(offset)
            
            docs = query.stream()
            
            results = []
            for doc in docs:
                data = doc.to_dict()
                # Remove detailed data for list view
                data.pop('detailed_analysis', None)
                results.append(data)
            
            return results
            
        except Exception as e:
            logger.error(f"❌ Failed to get history: {e}")
            raise StorageError(f"Failed to get history: {str(e)}")
    
    async def delete_analysis(
        self,
        analysis_id: str,
        user_id: str
    ) -> bool:
        """
        Delete an analysis
        
        Args:
            analysis_id: Analysis identifier
            user_id: User identifier (for access control)
        
        Returns:
            True if deleted
        """
        try:
            doc_ref = self.db.collection('analyses').document(analysis_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                return False
            
            data = doc.to_dict()
            
            # Verify user access
            if data.get('user_id') != user_id:
                raise StorageError("Unauthorized access")
            
            # Delete main document and details
            doc_ref.delete()
            
            # Delete details subcollection
            details_ref = doc_ref.collection('details').document('full')
            details_ref.delete()
            
            logger.info(f"✅ Analysis deleted: {analysis_id}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to delete analysis: {e}")
            raise StorageError(f"Failed to delete analysis: {str(e)}")
    
    async def update_analysis(
        self,
        analysis_id: str,
        user_id: str,
        updates: Dict[str, Any]
    ) -> bool:
        """
        Update analysis metadata
        
        Args:
            analysis_id: Analysis identifier
            user_id: User identifier
            updates: Fields to update
        
        Returns:
            True if updated
        """
        try:
            doc_ref = self.db.collection('analyses').document(analysis_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                return False
            
            data = doc.to_dict()
            
            # Verify user access
            if data.get('user_id') != user_id:
                raise StorageError("Unauthorized access")
            
            # Update allowed fields
            allowed_fields = ['speech_title', 'notes', 'tags']
            filtered_updates = {k: v for k, v in updates.items() if k in allowed_fields}
            
            if filtered_updates:
                doc_ref.update(filtered_updates)
                logger.info(f"✅ Analysis updated: {analysis_id}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to update analysis: {e}")
            raise StorageError(f"Failed to update analysis: {str(e)}")
