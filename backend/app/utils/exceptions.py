"""
Custom exceptions for VocalLabs
"""

class VocalLabsException(Exception):
    """Base exception for VocalLabs"""
    def __init__(self, message: str, status_code: int = 500, details: dict = None):
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)

class AudioProcessingError(VocalLabsException):
    """Raised when audio processing fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=422, details=details)

class AnalysisError(VocalLabsException):
    """Raised when analysis fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=500, details=details)

class StorageError(VocalLabsException):
    """Raised when storage operations fail"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=500, details=details)

class AuthenticationError(VocalLabsException):
    """Raised when authentication fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=401, details=details)

class ValidationError(VocalLabsException):
    """Raised when validation fails"""
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, status_code=400, details=details)
