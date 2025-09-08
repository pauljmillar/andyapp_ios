#!/bin/bash

# Pre-build script to increment build number
# Run this before each build to auto-increment the build number

echo "🚀 Pre-build: Incrementing build number..."

# Run the increment script
./scripts/increment_build_number.sh

echo "✅ Build number incremented successfully!"
echo "📱 Your app will now show the new build number in the Profile menu"
