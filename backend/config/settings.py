import os
from typing import List
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    """Application configuration settings"""
    
    # Application Info
    APP_NAME: str = "SpeakSharp API"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # OpenAI API Configuration
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # File Upload Settings
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "temp_uploads")
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB
    ALLOWED_AUDIO_FORMATS: List[str] = ["wav", "mp3", "m4a", "ogg", "flac"]
    
    # Firebase Configuration
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "")
    FIREBASE_PRIVATE_KEY: str = os.getenv("FIREBASE_PRIVATE_KEY", "")
    FIREBASE_PRIVATE_KEY_ID: str = os.getenv("FIREBASE_PRIVATE_KEY_ID", "")
    FIREBASE_CLIENT_EMAIL: str = os.getenv("FIREBASE_CLIENT_EMAIL", "")
    FIREBASE_CLIENT_ID: str = os.getenv("FIREBASE_CLIENT_ID", "")
    FIREBASE_AUTH_URI: str = os.getenv(
        "FIREBASE_AUTH_URI",
        "https://accounts.google.com/o/oauth2/auth"
    )
    FIREBASE_TOKEN_URI: str = os.getenv(
        "FIREBASE_TOKEN_URI", 
        "https://oauth2.googleapis.com/token"
    )
    FIREBASE_AUTH_PROVIDER_CERT_URL: str = os.getenv(
        "FIREBASE_AUTH_PROVIDER_CERT_URL",
        "https://www.googleapis.com/oauth2/v1/certs"
    )
    FIREBASE_CLIENT_CERT_URL: str = os.getenv("FIREBASE_CLIENT_CERT_URL", "")
    FIREBASE_STORAGE_BUCKET: str = os.getenv("FIREBASE_STORAGE_BUCKET", "")
    
    # Analysis Configuration
    DEFAULT_MODEL: str = "whisper-1"  # OpenAI Whisper model
    ANALYSIS_TIMEOUT: int = 300  # seconds
    
    # Feature Flags
    ENABLE_TOPIC_RELEVANCE: bool = True
    ENABLE_EMPHASIS_ANALYSIS: bool = True
    ENABLE_ADVANCED_PRONUNCIATION: bool = True
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE: str = os.getenv("LOG_FILE", "SpeakSharp.log")
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"

# Create global settings instance
settings = Settings()