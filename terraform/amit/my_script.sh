#!/bin/bash

# Define the repository URL
REPO_URL="https://github.com/sharathchandra04/archivep.git"

# Clone the repository
echo "Cloning repository..."
git clone $REPO_URL

# Get the repo name from the URL (assumes the repo name is the last part of the URL)
REPO_NAME=$(basename $REPO_URL .git)

# Navigate into the repo/backend directory
echo "Navigating to $REPO_NAME/backend..."
cd $REPO_NAME/backend

# Install the required Python packages
echo "Installing Python dependencies..."
pip install -r requirements.txt

source devenv.sh
flask --app=./app:app db migrate
flask --app=./app:app db upgrade
# Start the Flask server
echo "Starting Flask server..."
python app.py
