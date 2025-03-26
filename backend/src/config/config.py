import os
from datetime import timedelta

class Config:
    # General Config
    SECRET_KEY = os.environ.get('SECRET_KEY', 'mysecretkey')
    SQLALCHEMY_DATABASE_URI = f'postgresql://{os.environ.get("DB_USERNAME")}:{os.environ.get("DB_PASSWORD")}@{os.environ.get("DB_ADDRESS")}:{os.environ.get("DB_PORT")}/{os.environ.get("DB_DATABASE")}'
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # Logging config
    LOGGING_LEVEL = os.environ.get('LOGGING_LEVEL', 'INFO')
    JWT_TOKEN_LOCATION = ['cookies']
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_COOKIE_CSRF_PROTECT = False 
    JWT_VERIFY_SUB = False

    # Configure the app for file uploads
    UPLOAD_FOLDER = 'uploads'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # Max file size: 16 MB

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_ECHO = True
    HELLO = 'MY_DEV $$$$$$$$$$$$'

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_ECHO = False
    HELLO = 'MY_PROD $$$$$$$$$$$$'