#!/bin/bash

# AndyApp Build Organizer Script
# Usage: ./organize-build.sh [version] [build-type]

VERSION=${1:-$(date +"%Y-%m-%d")}
BUILD_TYPE=${2:-"development"}
BUILD_DIR="$HOME/Documents/builds/AndyApp/releases/$VERSION-$BUILD_TYPE"

echo "🏗️  Organizing AndyApp build..."
echo "📁 Version: $VERSION"
echo "📦 Build Type: $BUILD_TYPE"
echo "📂 Target Directory: $BUILD_DIR"

# Create version directory
mkdir -p "$BUILD_DIR"

echo "✅ Created directory: $BUILD_DIR"
echo ""
echo "📋 Next steps:"
echo "1. Archive your app in Xcode (Product > Archive)"
echo "2. Distribute App > Ad Hoc (or your preferred method)"
echo "3. Save the .ipa file to: $BUILD_DIR"
echo "4. Optionally add release notes to: $BUILD_DIR/release-notes.txt"
echo ""
echo "🎯 Your build structure:"
echo "   $BUILD_DIR/"
echo "   ├── AndyApp.ipa"
echo "   └── release-notes.txt (optional)"
