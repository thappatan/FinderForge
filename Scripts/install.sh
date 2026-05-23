#!/bin/zsh
# Copyright (C) 2026 thappatan chanphen — part of FinderForge.
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Build a Release FinderForge and install it into /Applications, so you can
# launch it like any other app (double-click, Spotlight, Launchpad, login item).
# Your own development signing is enough to run it on this Mac — no Developer ID
# or notarization needed; that's only for handing the app to other people.
# Run from anywhere: ./Scripts/install.sh
set -e
cd "$(dirname "$0")/.."

EXT="com.devsun.FinderForge.FinderMenuExtension"
DEST="/Applications/FinderForge.app"

echo "▶︎ Generating project…"
xcodegen generate >/dev/null

echo "▶︎ Building (Release)…"
xcodebuild -project FinderForge.xcodeproj -scheme FinderForge \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build -allowProvisioningUpdates build 2>&1 \
  | grep -iE "error:|\*\* BUILD" || true

APP=$(find build/Build/Products/Release -maxdepth 1 -name "FinderForge.app" | head -1)
[ -z "$APP" ] && { echo "✗ build product not found"; exit 1; }

echo "▶︎ Installing to $DEST…"
pluginkit -e ignore -i "$EXT" 2>/dev/null || true
killall FinderForge 2>/dev/null || true
sleep 1
rm -rf "$DEST"
cp -R "$APP" "$DEST"

echo "▶︎ Registering the Finder extension…"
pluginkit -a "$DEST/Contents/PlugIns/FinderMenuExtension.appex" 2>/dev/null || true
pluginkit -e use -i "$EXT" 2>/dev/null || true
killall Finder 2>/dev/null || true

open "$DEST"

echo "✅ Installed: $DEST"
echo "   Launch it from Spotlight / Launchpad — the icon sits in the menu bar."
echo "   First time only: System Settings → General → Login Items & Extensions"
echo "   → Added Extensions / Finder → enable FinderForge."
