from flask import Blueprint, jsonify
from src.methods.main import get_data
from src.db.models import User

main_bp = Blueprint('main', __name__)

@main_bp.route('/data', methods=['GET'])
def data():
    data = get_data()
    return jsonify(data)


