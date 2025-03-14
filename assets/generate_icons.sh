#!/bin/bash

# Script to generate app icons from SVG for XCode
# macOS Sizes: 16, 32, 64, 128, 256, 512, 1024
# iOS Size: 1024 (with light, dark, and high contrast variants)

# Check if Inkscape is installed
if ! command -v inkscape &> /dev/null; then
    echo "Inkscape is required but not installed. Please install Inkscape."
    exit 1
fi

# Check if ImageMagick is installed for grayscale conversion
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is required for grayscale conversion but not installed. Please install ImageMagick."
    exit 1
fi

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_DIR="$SCRIPT_DIR/../Containers/Assets.xcassets/AppIcon.appiconset"

# Create destination directory if it doesn't exist
mkdir -p "$ICON_DIR"

# Generate macOS icons from logo.svg
echo "Generating macOS icons from logo.svg..."
SOURCE_SVG="$SCRIPT_DIR/logo-dark.svg"

for SIZE in 16 32 64 128 256 512 1024; do
    echo "Generating macOS $SIZE x $SIZE icon..."
    inkscape --export-filename="$ICON_DIR/icon_${SIZE}x${SIZE}.png" \
             --export-width=$SIZE \
             --export-height=$SIZE \
             "$SOURCE_SVG"
done

# Generate iOS icons in multiple variants
echo "Generating iOS icons..."
LIGHT_SOURCE_SVG="$SCRIPT_DIR/logo-light.svg"
DARK_SOURCE_SVG="$SCRIPT_DIR/logo.svg"

# Generate light icon for iOS
echo "Generating iOS 1024 x 1024 light icon..."
inkscape --export-filename="$ICON_DIR/ios_icon_light.png" \
         --export-width=1024 \
         --export-height=1024 \
         "$LIGHT_SOURCE_SVG"

# Generate dark icon for iOS
echo "Generating iOS 1024 x 1024 dark icon..."
inkscape --export-filename="$ICON_DIR/ios_icon_dark.png" \
         --export-width=1024 \
         --export-height=1024 \
         "$DARK_SOURCE_SVG"

# Generate high contrast (grayscale) icon for iOS by converting dark icon
echo "Generating iOS 1024 x 1024 high contrast (grayscale) icon..."
convert "$ICON_DIR/ios_icon_dark.png" -colorspace gray "$ICON_DIR/ios_icon_tinted.png"

echo "Icons generated successfully in $ICON_DIR"

# Update Contents.json file with macOS and iOS icons (including light/dark/high contrast mode support)
cat > "$ICON_DIR/Contents.json" << EOL
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    },
    {
      "filename" : "ios_icon_light.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "ios_icon_dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "ios_icon_tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOL

echo "Contents.json updated successfully"
echo "Done!"
