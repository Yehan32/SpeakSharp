"""
Custom exceptions for SpeakSharp
"""

class SpeakSharpException(Exception):
    """Base exception for SpeakSharp"""
    def __init__(self, message: str, status_code: int = 500, details: dict = None):
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)

class AudioProcessingError(SpeakSharpException):
    """Raised when audio processing fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=422, details=details)

class AnalysisError(SpeakSharpException):
    """Raised when analysis fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=500, details=details)

class StorageError(SpeakSharpException):
    """Raised when storage operations fail"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=500, details=details)

class AuthenticationError(SpeakSharpException):
    """Raised when authentication fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=401, details=details)

class ValidationError(SpeakSharpException):
    """Raised when validation fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=400, details=details)
