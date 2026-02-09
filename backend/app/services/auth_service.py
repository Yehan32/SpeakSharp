"""
Authentication Service
Handles user authentication and authorization
"""

from typing import Optional, Dict
from firebase_admin import auth as firebase_auth

from utils.logger import setup_logger
from utils.exceptions import AuthenticationError

logger = setup_logger(__name__)

class AuthService:
    """Service for authentication operations"""
    
    def __init__(self):
        logger.info("🔐 Auth Service initialized")
    
    async def verify_token(self, token: str) -> Optional[Dict]:
        """
        Verify Firebase ID token
        
        Args:
            token: Firebase ID token
        
        Returns:
            User information if valid
        """
        try:
            decoded_token = firebase_auth.verify_id_token(token)
            return {
                "uid": decoded_token["uid"],
                "email": decoded_token.get("email"),
                "name": decoded_token.get("name")
            }
        except Exception as e:
            logger.error(f"Token verification failed: {e}")
            raise AuthenticationError("Invalid authentication token")
    
    async def get_user(self, uid: str) -> Optional[Dict]:
        """Get user by UID"""
        try:
            user = firebase_auth.get_user(uid)
            return {
                "uid": user.uid,
                "email": user.email,
                "name": user.display_name,
                "created_at": user.user_metadata.creation_timestamp
            }
        except Exception as e:
            logger.error(f"Failed to get user: {e}")
            return None
