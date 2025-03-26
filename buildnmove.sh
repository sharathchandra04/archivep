#!/bin/bash

# Define the paths
FRONTEND_DIR="frontend"
BACKEND_DIR="backend"
BUILD_DIR="build"

# Navigate to the frontend directory
echo "Navigating to frontend directory..."
cd $FRONTEND_DIR

# Install dependencies (if not already done)
echo "Installing frontend dependencies..."
npm install

# Build the React application
echo "Building the React application..."
npm run build

# Move the build folder to the backend directory
echo "Moving the build folder to the backend directory..."
mv $BUILD_DIR ../$BACKEND_DIR/src

# Confirm that the build folder has been moved
if [ -d "../$BACKEND_DIR/$BUILD_DIR" ]; then
    echo "Build folder successfully moved to backend."
else
    echo "Failed to move the build folder."
fi

