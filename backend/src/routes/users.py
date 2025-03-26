from flask import Blueprint
from flask import Flask, jsonify, request, make_response
from flask_jwt_extended import JWTManager, create_access_token, jwt_required
from flask_jwt_extended import get_jwt_identity, set_access_cookies
from ..db.models import User
from src import bcrypt, csrf
from ..db import db

users_bp = Blueprint('users', __name__)

@users_bp.route('/<int:user_id>', methods=['GET'])
def user(user_id):
    # Replace with actual user fetching logic (e.g., using SQLAlchemy to query DB)
    return jsonify({"user_id": user_id, "name": "John Doe"})

# Login route that returns JWT token
@users_bp.route('/login', methods=['POST'])
# @csrf.exempt
# @jwt_required()  # Only accessible if the request contains a valid token
def login():
    email = request.json.get('email', None)
    password = request.json.get('password', None)

    if not email or not password:
        return jsonify({"message": "Email and password required"}), 400

    user = User.query.filter_by(email=email).first()

    if user and bcrypt.check_password_hash(user.password, password):
        access_token = create_access_token(identity=user.id)
        print('access_token --> ', access_token)
        response = make_response(jsonify(message="Login successful"))
        response.set_cookie('access_token_cookie', access_token, httponly=True, secure=False, samesite='Lax')
        # response.set_cookie('user_id', '1234', max_age=3600)
        try:
            set_access_cookies(response, access_token)
        except Exception as e:
            print(e)
        return response
    return jsonify({"message": "Invalid credentials"}), 401


# A protected route example (JWT required)
@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def profile():
    current_user = get_jwt_identity()  # This retrieves the user id from the token
    user = User.query.get(current_user)
    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email
    })

@users_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    print(data)
    username = data.get('email')
    email = data.get('email')
    password = data.get('password')

    # Check if email already exists
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({"msg": "User already exists"}), 400

    # Hash the password
    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

    # Create a new user
    new_user = User(username=username, email=email, password=hashed_password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"msg": "User registered successfully"}), 200

@users_bp.route('/protected', methods=['GET'])
@jwt_required()
def protected():
    current_user = get_jwt_identity()  # Get the user ID from the JWT
    return jsonify(logged_in_as=current_user), 200
