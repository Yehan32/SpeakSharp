"""
Application Configuration Module
Centralized configuration management using environment variables
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Application Settings
    APP_NAME: str = "VocalLabs API"
    APP_VERSION: str = "2.0.0"
    ENVIRONMENT: str = Field(default="development", env="ENVIRONMENT")
    DEBUG: bool = Field(default=False, env="DEBUG")
    
    # API Settings
    API_PREFIX: str = "/api/v2"
    ALLOWED_HOSTS: list = ["*"]
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB
    
    # Firebase Settings
    FIREBASE_PROJECT_ID: str = Field(default="vocallabs-fc7d5", env="FIREBASE_PROJECT_ID")
    FIREBASE_PRIVATE_KEY: str = Field(..., env="FIREBASE_PRIVATE_KEY")
    FIREBASE_PRIVATE_KEY_ID: str = Field(..., env="FIREBASE_PRIVATE_KEY_ID")
    FIREBASE_CLIENT_EMAIL: str = Field(
        default="firebase-adminsdk-fbsvc@vocallabs-fc7d5.iam.gserviceaccount.com",
        env="FIREBASE_CLIENT_EMAIL"
    )
    FIREBASE_STORAGE_BUCKET: str = Field(
        default="vocallabs-fc7d5.firebasestorage.app",
        env="FIREBASE_STORAGE_BUCKET"
    )
    
    # ML Model Settings
    WHISPER_MODEL: str = Field(default="medium", env="WHISPER_MODEL")
    SPACY_MODEL: str = Field(default="en_core_web_sm", env="SPACY_MODEL")
    BERT_MODEL: str = Field(default="bert-base-uncased", env="BERT_MODEL")
    SENTENCE_TRANSFORMER_MODEL: str = Field(
        default="all-MiniLM-L6-v2",
        env="SENTENCE_TRANSFORMER_MODEL"
    )
    
    # Analysis Settings
    MIN_AUDIO_DURATION: int = 10  # seconds
    MAX_AUDIO_DURATION: int = 1800  # 30 minutes
    DEFAULT_SPEECH_DURATION: str = "5-7 minutes"
    
    # Logging Settings
    LOG_LEVEL: str = Field(default="INFO", env="LOG_LEVEL")
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Cache Settings
    CACHE_TTL: int = 3600  # 1 hour
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
