#!/bin/zsh
# Copyright (C) 2026 thappatan chanphen — part of FinderForge.
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Build FinderForge, reload the Finder extension cleanly (no ghost instances),
# and launch the app. Run from anywhere: ./Scripts/run.sh
set -e
cd "$(dirname "$0")/.."

EXT="com.devsun.FinderForge.FinderMenuExtension"

echo "▶︎ Building…"
xcodebuild -project FinderForge.xcodeproj -scheme FinderForge \
  -configuration Debug -destination 'platform=macOS' \
  -allowProvisioningUpdates build 2>&1 | grep -iE "error:|\*\* BUILD" || true

APP=$(find ~/Library/Developer/Xcode/DerivedData/FinderForge-*/Build/Products/Debug -maxdepth 1 -name "FinderForge.app" | head -1)
STANDALONE=$(find ~/Library/Developer/Xcode/DerivedData/FinderForge-*/Build/Products/Debug -maxdepth 1 -name "FinderMenuExtension.appex" | head -1)
[ -z "$APP" ] && { echo "✗ build product not found"; exit 1; }

echo "▶︎ Reloading extension…"
pluginkit -e ignore -i "$EXT" 2>/dev/null || true
killall FinderForge FinderMenuExtension Finder 2>/dev/null || true
sleep 1
[ -n "$STANDALONE" ] && rm -rf "$STANDALONE"   # avoid duplicate menu from standalone copy
open "$APP"
sleep 2
pluginkit -e use -i "$EXT" 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "✅ Running: $APP"
echo "   (First time only: System Settings → General → Login Items & Extensions"
echo "    → Added Extensions / Finder → enable FinderForge)"
