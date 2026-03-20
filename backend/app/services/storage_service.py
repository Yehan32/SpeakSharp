"""
Storage Service - FIXED VERSION
Handles data persistence using Firebase Firestore

KEY FIXES:
1. Uses existing Firebase instance from firebase_config.py (correct project speak-sharp-6bd84)
   instead of re-initializing with env vars that may not be set
2. Saves to users/{user_id}/speeches/ path which matches Firestore security rules
   so the Flutter client can actually READ the data
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import uuid

from firebase_admin import firestore
from app.utils.logger import setup_logger
from app.utils.exceptions import StorageError

logger = setup_logger(__name__)


class StorageService:
    """Service for data storage using Firebase Firestore"""

    def __init__(self):
        # Use the Firebase instance already initialized by firebase_config.py
        # Do NOT initialize again - it will throw "app already exists"
        try:
            self.db = firestore.client()
            logger.info("StorageService ready (using existing Firebase instance)")
        except Exception as e:
            logger.error(f"StorageService: Firestore unavailable: {e}")
            self.db = None

    async def save_analysis(
        self,
        user_id: str,
        speech_title: Optional[str],
        results: Dict[str, Any]
    ) -> str:
        """
        Save analysis to Firestore under users/{user_id}/speeches/

        This path matches the Firestore security rules:
          match /users/{userId}/speeches/{speechId} {
            allow read, write: if request.auth.uid == userId;
          }
        So the Flutter client can read it directly.
        """
        if self.db is None:
            logger.warning("No Firestore connection - skipping save")
            return "no-db"

        try:
            speech_id = str(uuid.uuid4())

            doc_data = {
                "id": speech_id,
                "analysis_id": speech_id,
                "user_id": user_id,

                # Title and topic
                "speech_title": speech_title or results.get("topic") or "Untitled Speech",
                "topic": results.get("topic") or speech_title or "Not specified",

                # Timestamps - both server timestamp and ISO string
                "recorded_at": firestore.SERVER_TIMESTAMP,
                "timestamp": datetime.now().isoformat(),

                # Scores
                "overall_score": results.get("overall_score", 0),
                "scores": results.get("scores", {}),

                # Duration
                "duration": results.get("duration", "N/A"),

                # Flat metrics for list display
                "filler_word_count": results.get("filler_word_count", 0),
                "words_per_minute": results.get("words_per_minute", "N/A"),
                "pitch_variation": results.get("pitch_variation", "N/A"),
                "volume_control": results.get("volume_control", "N/A"),
                "emphasis": results.get("emphasis", "N/A"),
                "has_intro": results.get("has_intro", False),
                "has_body": results.get("has_body", False),
                "has_conclusion": results.get("has_conclusion", False),
                "unique_word_count": results.get("unique_word_count", 0),
                "total_words": results.get("total_words", 0),
                "vocabulary_richness": results.get("vocabulary_richness", "N/A"),

                # Transcription preview (first 500 chars)
                "transcription": results.get("transcription", "")[:500],

                # Suggestions
                "suggestions": results.get("suggestions", []),
            }

            # Save under users/{user_id}/speeches/{speech_id}
            self.db.collection('users')\
                .document(user_id)\
                .collection('speeches')\
                .document(speech_id)\
                .set(doc_data)

            logger.info(f"Saved speech to users/{user_id}/speeches/{speech_id}")
            return speech_id

        except Exception as e:
            logger.error(f"Failed to save analysis: {e}")
            return "save-failed"

    async def get_analysis(
        self,
        analysis_id: str,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """Retrieve a specific analysis"""
        if self.db is None:
            return None

        try:
            doc = self.db.collection('users')\
                .document(user_id)\
                .collection('speeches')\
                .document(analysis_id)\
                .get()

            if not doc.exists:
                return None

            data = doc.to_dict()
            data['id'] = doc.id
            return data

        except Exception as e:
            logger.error(f"Failed to retrieve analysis: {e}")
            return None

    async def get_user_history(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """Get user's speech history from users/{user_id}/speeches/"""
        if self.db is None:
            return []

        try:
            query = self.db.collection('users')\
                .document(user_id)\
                .collection('speeches')\
                .order_by('recorded_at', direction=firestore.Query.DESCENDING)\
                .limit(limit)

            results = []
            for doc in query.stream():
                data = doc.to_dict()
                data['id'] = doc.id
                data['analysis_id'] = doc.id

                # Convert Firestore Timestamp to ISO string for JSON
                recorded_at = data.get('recorded_at')
                if hasattr(recorded_at, 'isoformat'):
                    data['timestamp'] = recorded_at.isoformat()
                elif 'timestamp' not in data:
                    data['timestamp'] = datetime.now().isoformat()

                results.append(data)

            logger.info(f"Retrieved {len(results)} speeches for user {user_id}")
            return results

        except Exception as e:
            logger.error(f"Failed to get history: {e}")
            return []

    async def delete_analysis(
        self,
        analysis_id: str,
        user_id: str
    ) -> bool:
        """Delete a specific analysis"""
        if self.db is None:
            return False

        try:
            doc_ref = self.db.collection('users')\
                .document(user_id)\
                .collection('speeches')\
                .document(analysis_id)

            if not doc_ref.get().exists:
                return False

            doc_ref.delete()
            logger.info(f"Deleted analysis {analysis_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to delete analysis: {e}")
            return False

    async def update_analysis(
        self,
        analysis_id: str,
        user_id: str,
        updates: Dict[str, Any]
    ) -> bool:
        """Update analysis metadata"""
        if self.db is None:
            return False

        try:
            doc_ref = self.db.collection('users')\
                .document(user_id)\
                .collection('speeches')\
                .document(analysis_id)

            if not doc_ref.get().exists:
                return False

            allowed = ['speech_title', 'topic', 'notes', 'tags']
            filtered = {k: v for k, v in updates.items() if k in allowed}
            if filtered:
                doc_ref.update(filtered)

            return True

        except Exception as e:
            logger.error(f"Failed to update analysis: {e}")
            return False