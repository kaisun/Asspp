#!/bin/bash

set -e

IPA_PATH="$1"
TIPA_PATH="$2"

TEMP_DIR=$(mktemp -d)

echo "Extracting IPA: $IPA_PATH to $TEMP_DIR"
unzip -q "$IPA_PATH" -d "$TEMP_DIR"

APP_PATH=$(find "$TEMP_DIR/Payload" -name "*.app" -type d | head -n 1)
if [ -z "$APP_PATH" ]; then
    echo "Error: No .app bundle found in Payload"
    rm -rf "$TEMP_DIR"
    exit 1
fi

EXECUTABLE_NAME="Asspp"
EXECUTABLE_PATH="$APP_PATH/$EXECUTABLE_NAME"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "Error: Executable $EXECUTABLE_NAME not found in $APP_PATH"
    rm -rf "$TEMP_DIR"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTITLEMENTS_PATH="$SCRIPT_DIR/../Troll/MobileInstall.plist"
ENTITLEMENTS_PATH=$(realpath "$ENTITLEMENTS_PATH")

if [ ! -f "$ENTITLEMENTS_PATH" ]; then
    echo "Error: Entitlements file not found at $ENTITLEMENTS_PATH"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Signing executable: $EXECUTABLE_PATH with entitlements: $ENTITLEMENTS_PATH"
ldid -S"$ENTITLEMENTS_PATH" "$EXECUTABLE_PATH"

echo "Repackaging to TIPA: $TIPA_PATH"
cd "$TEMP_DIR"
zip -q -r "$TIPA_PATH" .

rm -rf "$TEMP_DIR"

echo "TIPA created: $TIPA_PATH"
