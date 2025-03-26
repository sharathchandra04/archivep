import os
from flask import Flask
from flask_migrate import Migrate
from flask_cors import CORS
from .db import db
from .logging.logger import setup_logging
from .extensions import cors
from .config.config import DevelopmentConfig, ProductionConfig, Config
from flask_jwt_extended import JWTManager, create_access_token, jwt_required
from flask_bcrypt import Bcrypt
# from flask_wtf.csrf import CSRFProtect
from flask import send_from_directory


bcrypt = None
config_obj = None
csrf = None
def create_app():
    # app = Flask(__name__)
    app = Flask(__name__, static_folder="build/static")
    global config_obj
    if os.environ.get('FLASK_ENV') == 'production' or True:
        app.config.from_object(ProductionConfig)
        config_obj = ProductionConfig
    else:
        app.config.from_object(DevelopmentConfig)
        config_obj = DevelopmentConfig

    # CORS setup
    # CORS(app)
    # CORS(app, resources={r"/*": {"origins": "http://localhost:3000"}})
    CORS(app, origins=["http://localhost:3000"], supports_credentials=True)

    # Initialize DB
    db.init_app(app)

    # Setup logging
    setup_logging(app)

    # Migrate setup
    Migrate(app, db)
    jwt = JWTManager(app)
    global bcrypt
    bcrypt = Bcrypt(app)
    global csrf
    # csrf = CSRFProtect(app)
    # csrf._disable_on_debug = True
    # Register Blueprints
    from .routes.main import main_bp
    from .routes.users import users_bp
    from .routes.data import data_bp
    app.register_blueprint(main_bp, url_prefix='/api/v1/main')
    app.register_blueprint(users_bp, url_prefix='/api/v1/users')
    app.register_blueprint(data_bp, url_prefix='/api/v1/data')

    # Serve the static files (React build) from the build folder
    @app.route('/')
    def serve_react_app():
        return send_from_directory('build', 'index.html')

    return app
