#!/bin/bash

REPO_URL="https://github.com/sharathchandra04/archivep.git"
git clone $REPO_URL
REPO_NAME=$(basename $REPO_URL .git)
cd $REPO_NAME
sudo apt update -y # y
sudo apt install pip -y
VENV_DIR="venv"
if ! command -v python3 &> /dev/null; then
    echo "Error: Python3 is not installed. Please install it and try again."
    exit 1
fi
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment in '$VENV_DIR'..."
    sudo apt install python3-venv -y
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists in '$VENV_DIR'."
fi
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
pip install -r requirements.txt

# source devenv.sh
# flask --app=./app:app db migrate
# flask --app=./app:app db upgrade
# Start the Flask server
# echo "Starting Flask server..."
# python app.py
