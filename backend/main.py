from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import logging
import os
from datetime import datetime
import asyncio
from contextlib import asynccontextmanager

# Import services
from app.services.speech_service import SpeechAnalysisService
from app.services.audio_service import AudioProcessingService
from app.services.storage_service import StorageService
from app.services.auth_service import AuthService
from config.settings import Settings
from app.utils.logger import setup_logger
from app.utils.exceptions import VocalLabsException, AudioProcessingError, AnalysisError

# Setup
settings = Settings()
logger = setup_logger(__name__)

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle application startup and shutdown"""
    logger.info("🚀 Starting VocalLabs Backend...")
    
    # Initialize services
    app.state.speech_service = SpeechAnalysisService()
    app.state.audio_service = AudioProcessingService()
    app.state.storage_service = StorageService()
    app.state.auth_service = AuthService()
    
    # Download required models
    await app.state.speech_service.initialize()
    
    logger.info("Backend started successfully")
    
    yield
    
    # Cleanup
    logger.info("Shutting down  Backend...")
    await app.state.speech_service.cleanup()

# Create FastAPI app
app = FastAPI(
    title="VocalLabs API",
    description="Advanced Speech Analysis and Feedback System",
    version="2.0.0",
    lifespan=lifespan
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================
# Request/Response Models
# =====================

class AnalysisRequest(BaseModel):
    """Request model for speech analysis"""
    user_id: str = Field(..., description="User identifier")
    speech_title: Optional[str] = Field(None, description="Title of the speech")
    topic: Optional[str] = Field(None, description="Expected topic for relevance analysis")
    expected_duration: Optional[str] = Field("5-7 minutes", description="Expected speech duration")
    gender: Optional[str] = Field("auto", description="Speaker gender for analysis")
    analysis_depth: Optional[str] = Field("standard", description="Analysis depth: basic, standard, advanced")

class AnalysisResponse(BaseModel):
    """Response model for speech analysis"""
    analysis_id: str
    status: str
    scores: Dict[str, Any]
    transcription: Optional[str]
    detailed_analysis: Dict[str, Any]
    timestamp: datetime
    processing_time: float

class HealthCheck(BaseModel):
    """Health check response"""
    status: str
    version: str
    timestamp: datetime
    services: Dict[str, str]

# =====================
# API Endpoints
# =====================

@app.get("/", tags=["Health"])
async def root():
    """Root endpoint"""
    return {
        "message": "Speak Sharp API v2.0",
        "status": "operational",
        "docs": "/docs"
    }

@app.get("/health", response_model=HealthCheck, tags=["Health"])
async def health_check():
    """
    Health check endpoint
    Returns system status and service availability
    """
    try:
        services_status = {
            "speech_analysis": "operational",
            "audio_processing": "operational",
            "storage": "operational",
            "authentication": "operational"
        }
        
        return HealthCheck(
            status="healthy",
            version="2.0.0",
            timestamp=datetime.now(),
            services=services_status
        )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail="Service unhealthy")

@app.post("/api/v2/analyze", tags=["Analysis"])
async def analyze_speech(
    audio_file: UploadFile = File(...),
    user_id: str = "anonymous",
    speech_title: Optional[str] = None,
    topic: Optional[str] = None,
    expected_duration: str = "5-7 minutes",
    gender: str = "auto",
    analysis_depth: str = "standard",
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """
    Analyze uploaded speech audio
    
    - **audio_file**: Audio file (wav, mp3, m4a, ogg)
    - **user_id**: User identifier
    - **speech_title**: Optional title for the speech
    - **topic**: Optional topic for relevance analysis
    - **expected_duration**: Expected duration (e.g., "5-7 minutes")
    - **gender**: Speaker gender (auto, male, female)
    - **analysis_depth**: Analysis depth (basic, standard, advanced)
    
    Returns comprehensive speech analysis results
    """
    analysis_start_time = datetime.now()
    
    try:
        logger.info(f"Starting analysis for user: {user_id}")
        
        # Validate audio file
        if not audio_file.filename:
            raise HTTPException(status_code=400, detail="No file provided")
        
        file_extension = audio_file.filename.split('.')[-1].lower()
        if file_extension not in settings.ALLOWED_AUDIO_FORMATS:
            raise HTTPException(
                status_code=400, 
                detail=f"Unsupported format. Allowed: {settings.ALLOWED_AUDIO_FORMATS}"
            )
        
        # Get services
        speech_service: SpeechAnalysisService = app.state.speech_service
        audio_service: AudioProcessingService = app.state.audio_service
        storage_service: StorageService = app.state.storage_service
        
        # Process audio file
        audio_path = await audio_service.save_upload(audio_file, user_id)
        
        # Perform analysis
        analysis_results = await speech_service.analyze(
            audio_path=audio_path,
            topic=topic,
            expected_duration=expected_duration,
            gender=gender,
            analysis_depth=analysis_depth
        )
        
        # Calculate processing time
        processing_time = (datetime.now() - analysis_start_time).total_seconds()
        
        # Save results to storage
        analysis_id = await storage_service.save_analysis(
            user_id=user_id,
            speech_title=speech_title,
            results=analysis_results
        )
        
        # Schedule cleanup
        background_tasks.add_task(audio_service.cleanup_file, audio_path)
        
        logger.info(f"Analysis completed in {processing_time:.2f}s")
        
        return {
            "analysis_id": analysis_id,
            "status": "completed",
            "scores": analysis_results.get("scores", {}),
            "transcription": analysis_results.get("transcription", ""),
            "detailed_analysis": analysis_results.get("detailed_analysis", {}),
            "timestamp": datetime.now().isoformat(),
            "processing_time": round(processing_time, 2)
        }
        
    except AudioProcessingError as e:
        logger.error(f"Audio processing error: {e}")
        raise HTTPException(status_code=422, detail=f"Audio processing failed: {str(e)}")
    except AnalysisError as e:
        logger.error(f"Analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/api/v2/analysis/{analysis_id}", tags=["Analysis"])
async def get_analysis(analysis_id: str, user_id: str):
    """
    Retrieve a specific analysis by ID
    """
    try:
        storage_service: StorageService = app.state.storage_service
        result = await storage_service.get_analysis(analysis_id, user_id)
        
        if not result:
            raise HTTPException(status_code=404, detail="Analysis not found")
        
        return result
    except Exception as e:
        logger.error(f"Error retrieving analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v2/history/{user_id}", tags=["Analysis"])
async def get_user_history(
    user_id: str,
    limit: int = 20,
    offset: int = 0
):
    """
    Get analysis history for a user
    """
    try:
        storage_service: StorageService = app.state.storage_service
        history = await storage_service.get_user_history(user_id, limit, offset)
        
        return {
            "user_id": user_id,
            "total": len(history),
            "analyses": history
        }
    except Exception as e:
        logger.error(f"Error retrieving history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v2/analysis/{analysis_id}", tags=["Analysis"])
async def delete_analysis(analysis_id: str, user_id: str):
    """
    Delete a specific analysis
    """
    try:
        storage_service: StorageService = app.state.storage_service
        success = await storage_service.delete_analysis(analysis_id, user_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Analysis not found")
        
        return {"message": "Analysis deleted successfully"}
    except Exception as e:
        logger.error(f"Error deleting analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v2/quick-analyze", tags=["Analysis"])
async def quick_analyze(
    audio_file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """
    Quick analysis without saving results (for demo/testing)
    """
    try:
        logger.info("Starting quick analysis")
        
        # Validate file
        if not audio_file.filename:
            raise HTTPException(status_code=400, detail="No file provided")
        
        # Get services
        speech_service: SpeechAnalysisService = app.state.speech_service
        audio_service: AudioProcessingService = app.state.audio_service
        
        # Process
        audio_path = await audio_service.save_upload(audio_file, "quick_analysis")
        results = await speech_service.analyze(audio_path, analysis_depth="basic")
        
        # Cleanup
        background_tasks.add_task(audio_service.cleanup_file, audio_path)
        
        return {
            "status": "completed",
            "scores": results.get("scores", {}),
            "summary": results.get("summary", {})
        }
        
    except Exception as e:
        logger.error(f"Quick analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =====================
# Error Handlers
# =====================

@app.exception_handler(VocalLabsException)
async def vocallabs_exception_handler(request, exc: VocalLabsException):
    """Handle custom VocalLabs exceptions"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.message, "details": exc.details}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc: Exception):
    """Handle general exceptions"""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "details": str(exc)}
    )

# =====================
# Startup Message
# =====================

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
