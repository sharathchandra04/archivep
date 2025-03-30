from src import create_app
from flask import jsonify, request
import os

app = create_app()


@app.before_request
def filter_request():
    # Get all cookies from the request
    # cookies = request.cookies
    # print(cookies)
    # # Example filter: Look for a specific cookie, e.g., 'user_id'
    # if 'user_id' in cookies:
    #     user_id = cookies['user_id']
    #     print(f"User ID Cookie: {user_id}")
    # else:
    #     print("User ID cookie not found.")
    pass

if __name__ == "__main__":
    if os.environ.get('FLASK_ENV') == 'production':
        # app.config.from_object(ProductionConfig)
        # config_obj = ProductionConfig
        app.run(host='0.0.0.0', port=5000, debug=True)

    else:
        app.run(debug=True)