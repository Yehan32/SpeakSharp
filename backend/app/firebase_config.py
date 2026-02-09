# File: backend/app/firebase_config.py
import os
from firebase_admin import credentials, firestore, storage
import firebase_admin
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get environment variables
private_key = os.getenv("FIREBASE_PRIVATE_KEY")
private_key_id = os.getenv("FIREBASE_PRIVATE_KEY_ID")

# Check if credentials exist
if not private_key or not private_key_id:
    raise RuntimeError("FIREBASE_PRIVATE_KEY or FIREBASE_PRIVATE_KEY_ID is not set in the environment variables")

# Replace escaped newlines with actual newlines in the private key
private_key = private_key.replace("\\n", "\n")

# Firebase service account key configuration
service_account_key = {
    "type": "service_account",
    "project_id": "speak-sharp-6bd84",
    "private_key_id": private_key_id,
    "private_key": private_key,
    "client_email": "firebase-adminsdk-fbsvc@speak-sharp-6bd84.iam.gserviceaccount.com",
    "client_id": "107155883031098895083",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40speak-sharp-6bd84.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
}

# Initialize Firebase
cred = credentials.Certificate(service_account_key)

firebase_admin.initialize_app(cred, {
    'storageBucket': 'speak-sharp-6bd84.firebasestorage.app'
})

# Create database instance
db = firestore.client()