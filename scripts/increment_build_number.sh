#!/bin/bash

# Script to automatically increment build number
# This should be run before each build

# When run manually, use current directory; when run in Xcode, use PROJECT_DIR
if [ -n "$PROJECT_DIR" ]; then
    PROJECT_FILE="${PROJECT_DIR}/AndyApp.xcodeproj/project.pbxproj"
else
    PROJECT_FILE="./AndyApp.xcodeproj/project.pbxproj"
fi

# Get the current build number from the project file
CURRENT_BUILD_NUMBER=$(grep -o 'CURRENT_PROJECT_VERSION = [0-9]*;' "$PROJECT_FILE" | head -1 | grep -o '[0-9]*')

# Check if we got a valid build number
if [[ "$CURRENT_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    # Increment the build number
    NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
    
    # Update the build number in the project file
    sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $NEW_BUILD_NUMBER;/g" "$PROJECT_FILE"
    
    echo "Build number incremented from $CURRENT_BUILD_NUMBER to $NEW_BUILD_NUMBER"
else
    echo "Error: Could not parse current build number: $CURRENT_BUILD_NUMBER"
    exit 1
fi