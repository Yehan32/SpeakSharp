"""
Application Settings and Configuration
"""

import os
from typing import List
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    """Application configuration settings"""
    
    # Application Info
    APP_NAME: str = "VocalLabs API"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # File Upload Settings
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "temp_uploads")
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB
    ALLOWED_AUDIO_FORMATS: List[str] = ["wav", "mp3", "m4a", "ogg", "flac"]
    
    # Firebase Configuration
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "vocallabs-fc7d5")
    FIREBASE_PRIVATE_KEY: str = os.getenv("FIREBASE_PRIVATE_KEY", "")
    FIREBASE_PRIVATE_KEY_ID: str = os.getenv("FIREBASE_PRIVATE_KEY_ID", "")
    FIREBASE_CLIENT_EMAIL: str = os.getenv(
        "FIREBASE_CLIENT_EMAIL",
        "firebase-adminsdk-fbsvc@vocallabs-fc7d5.iam.gserviceaccount.com"
    )
    FIREBASE_STORAGE_BUCKET: str = os.getenv(
        "FIREBASE_STORAGE_BUCKET",
        "vocallabs-fc7d5.firebasestorage.app"
    )
    
    # Analysis Configuration
    DEFAULT_MODEL: str = "medium"  # Whisper model
    ANALYSIS_TIMEOUT: int = 300  # seconds
    
    # Feature Flags
    ENABLE_TOPIC_RELEVANCE: bool = True
    ENABLE_EMPHASIS_ANALYSIS: bool = True
    ENABLE_ADVANCED_PRONUNCIATION: bool = True
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE: str = os.getenv("LOG_FILE", "vocallabs.log")
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Create global settings instance
settings = Settings()
