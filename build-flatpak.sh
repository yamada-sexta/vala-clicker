#!/bin/bash

# Configuration
APP_ID="com.github.yamada.vala-clicker"
MANIFEST="${APP_ID}.yml"
BUILD_DIR="flatpak-build"
REPO_DIR="flatpak-repo"

# Ensure flatpak-builder is installed
if ! command -v flatpak-builder &> /dev/null; then
    echo "Error: flatpak-builder is not installed."
    exit 1
fi

# Clean up previous builds
echo "Cleaning up..."
rm -rf "$BUILD_DIR" ".flatpak-builder"

# Build the flatpak
echo "Building Flatpak..."
flatpak-builder --force-clean --user --install --bundle-sources "$BUILD_DIR" "$MANIFEST"

echo "Flatpak built and installed for the current user."
echo "You can run it with: flatpak run $APP_ID"
