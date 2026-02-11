"""
Audio Processing Service
Handles audio file upload, validation, and preprocessing
"""

import os
import shutil
from pathlib import Path
from typing import Optional
import aiofiles
from fastapi import UploadFile
import librosa
import soundfile as sf

from app.utils.logger import setup_logger
from app.utils.exceptions import AudioProcessingError
from config.settings import settings

logger = setup_logger(__name__)

class AudioProcessingService:
    """Service for audio file operations"""
    
    def __init__(self):
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        logger.info(f"Audio upload directory: {self.upload_dir}")
    
    async def save_upload(
        self,
        file: UploadFile,
        user_id: str
    ) -> str:
        """
        Save uploaded audio file
        
        Args:
            file: Uploaded audio file
            user_id: User identifier
        
        Returns:
            Path to saved file
        """
        try:
            # Validate file
            if file.size and file.size > settings.MAX_UPLOAD_SIZE:
                raise AudioProcessingError(
                    f"File too large. Maximum size: {settings.MAX_UPLOAD_SIZE / 1024 / 1024}MB"
                )
            
            # Create user directory
            user_dir = self.upload_dir / user_id
            user_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate unique filename
            filename = f"{user_id}_{os.urandom(8).hex()}.{file.filename.split('.')[-1]}"
            filepath = user_dir / filename
            
            # Save file
            async with aiofiles.open(filepath, 'wb') as f:
                content = await file.read()
                await f.write(content)
            
            logger.info(f"Audio saved: {filepath}")
            
            # Validate audio
            await self._validate_audio(str(filepath))
            
            return str(filepath)
            
        except Exception as e:
            logger.error(f"Failed to save audio: {e}")
            raise AudioProcessingError(f"Failed to save audio file: {str(e)}")
    
    async def _validate_audio(self, filepath: str):
        """Validate audio file can be loaded"""
        try:
            audio, sr = librosa.load(filepath, sr=None, duration=1)
            if len(audio) == 0:
                raise AudioProcessingError("Audio file is empty or corrupted")
        except Exception as e:
            raise AudioProcessingError(f"Invalid audio file: {str(e)}")
    
    async def convert_to_wav(self, filepath: str) -> str:
        """Convert audio to WAV format if needed"""
        if filepath.endswith('.wav'):
            return filepath
        
        try:
            audio, sr = librosa.load(filepath, sr=16000)
            wav_path = filepath.rsplit('.', 1)[0] + '.wav'
            sf.write(wav_path, audio, sr)
            
            # Remove original
            os.remove(filepath)
            
            return wav_path
        except Exception as e:
            raise AudioProcessingError(f"Audio conversion failed: {str(e)}")
    
    async def cleanup_file(self, filepath: str):
        """Delete audio file"""
        try:
            if os.path.exists(filepath):
                os.remove(filepath)
                logger.info(f"Cleaned up: {filepath}")
        except Exception as e:
            logger.warning(f"Failed to cleanup file: {e}")
    
    async def cleanup_user_files(self, user_id: str, keep_recent: int = 5):
        """Cleanup old user files, keeping most recent"""
        try:
            user_dir = self.upload_dir / user_id
            if not user_dir.exists():
                return
            
            files = sorted(user_dir.glob('*'), key=os.path.getmtime, reverse=True)
            for file in files[keep_recent:]:
                file.unlink()
                logger.info(f"Cleaned up old file: {file}")
        except Exception as e:
            logger.warning(f"Failed to cleanup user files: {e}")
