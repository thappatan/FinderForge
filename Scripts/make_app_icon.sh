#!/bin/zsh
# Copyright (C) 2026 thappatan chanphen — part of FinderForge.
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Regenerate the app icon set from the master FinderForgeIcon.png.
# Trims transparent padding and rescales the art to fill the icon footprint,
# then produces every size the asset catalog needs.
# Usage: ./Scripts/make_app_icon.sh   (run from the repo root)
set -e

SRC="FinderForgeIcon.png"
ICONSET="FinderForge/Assets.xcassets/AppIcon.appiconset"
TARGET="${1:-970}"   # px the square icon fills inside the 1024 canvas

if [[ ! -f "$SRC" ]]; then
  echo "error: $SRC not found (run from repo root)"; exit 1
fi

# Trim padding + reframe the master into i1024.png.
swift Scripts/frame_icon.swift "$SRC" "$ICONSET/i1024.png" "$TARGET"

# Downscale to the remaining sizes.
for s in 16 32 64 128 256 512; do
  sips -z $s $s "$ICONSET/i1024.png" --out "$ICONSET/i$s.png" >/dev/null
done

echo "Regenerated icon set in $ICONSET (target ${TARGET}px) from $SRC"
