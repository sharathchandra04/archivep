import logging
from logging.handlers import RotatingFileHandler
import os

def setup_logging(app):
    log_level = app.config['LOGGING_LEVEL']
    
    # Set up logging for console (development)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(formatter)
    app.logger.addHandler(console_handler)
    
    # Set up logging for file (production)
    if not app.debug:
        log_file = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'app.log')
        file_handler = RotatingFileHandler(log_file, maxBytes=10000, backupCount=3)
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(formatter)
        app.logger.addHandler(file_handler)
