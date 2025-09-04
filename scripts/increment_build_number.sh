#!/bin/bash

# Script to automatically increment marketing version
# This should be run as a "Run Script" build phase in Xcode

# When run manually, use current directory; when run in Xcode, use PROJECT_DIR
if [ -n "$PROJECT_DIR" ]; then
    PROJECT_FILE="${PROJECT_DIR}/AndyApp.xcodeproj/project.pbxproj"
else
    PROJECT_FILE="./AndyApp.xcodeproj/project.pbxproj"
fi

# Get the current marketing version from the project file
CURRENT_MARKETING_VERSION=$(grep -o 'MARKETING_VERSION = [0-9.]*;' "$PROJECT_FILE" | head -1 | grep -o '[0-9.]*')

# Check if we got a valid version
if [[ "$CURRENT_MARKETING_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Parse the version components
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_MARKETING_VERSION"
    MAJOR="${VERSION_PARTS[0]}"
    MINOR="${VERSION_PARTS[1]}"
    PATCH="${VERSION_PARTS[2]}"
    
    # Increment the patch version
    NEW_PATCH=$((PATCH + 1))
    NEW_MARKETING_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
    
    # Update the marketing version in the project file
    sed -i '' "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = $NEW_MARKETING_VERSION;/g" "$PROJECT_FILE"
    
    echo "Marketing version incremented from $CURRENT_MARKETING_VERSION to $NEW_MARKETING_VERSION"
    echo "Build number remains at 1"
else
    echo "Error: Could not parse current marketing version: $CURRENT_MARKETING_VERSION"
    exit 1
fi
