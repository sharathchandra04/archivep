#!/bin/bash

# Define the mapping of Lambda names to Python files
declare -A lambda_files=(
    ["lambda1"]="archiveobjects.py"
    ["lambda2"]="initiate_restore.py"
    ["lambda3"]="check_restore.py"
    ["lambda4"]="trigger_lambda.py"
)

# Create zip files for each Lambda function
for lambda in "${!lambda_files[@]}"; do
    python_file="${lambda_files[$lambda]}"

    if [[ -f "$python_file" ]]; then
        zip "$lambda.zip" "$python_file"
        echo "Created $lambda.zip"
    else
        echo "Error: $python_file not found!"
    fi
done

