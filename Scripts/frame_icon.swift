//
//  frame_icon.swift
//  FinderForge
//
//  Copyright (C) 2026 thappatan chanphen
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import AppKit

// Trims the transparent border of a square icon and rescales the artwork so its
// larger dimension fills `target` px inside a 1024×1024 transparent canvas
// (centered). Fixes icons that look "too small" in the Dock due to baked-in padding.
//
// Usage: swift frame_icon.swift <input.png> <output.png> [target=950]

let args = CommandLine.arguments
guard args.count >= 3 else { print("usage: frame_icon.swift <in> <out> [target]"); exit(1) }
let inPath = args[1], outPath = args[2]
let target = CGFloat(args.count >= 4 ? (Double(args[3]) ?? 950) : 950)
let canvas: CGFloat = 1024

guard let srcImg = NSImage(contentsOfFile: inPath),
      let tiff = srcImg.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cg = rep.cgImage else { print("load fail: \(inPath)"); exit(1) }

let w = rep.pixelsWide, h = rep.pixelsHigh

// Opaque bounding box (top-left origin, matches CGImage cropping coords).
var minX = w, minY = h, maxX = 0, maxY = 0
for y in 0..<h {
    for x in 0..<w {
        if let c = rep.colorAt(x: x, y: y), c.alphaComponent > 0.04 {
            if x < minX { minX = x }; if x > maxX { maxX = x }
            if y < minY { minY = y }; if y > maxY { maxY = y }
        }
    }
}
guard maxX >= minX, maxY >= minY else { print("empty image"); exit(1) }
let cw = maxX - minX + 1, ch = maxY - minY + 1

// Expand the content bbox to a SQUARE crop centred on the content, so a
// wider-than-tall (or taller-than-wide) design still fills the square Dock
// tile evenly instead of floating with top/bottom margin. Clamp to bounds.
let side = max(cw, ch)
let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
let sx = max(0, min(cx - side / 2, w - side))
let sy = max(0, min(cy - side / 2, h - side))

guard let cropped = cg.cropping(to: CGRect(x: sx, y: sy, width: side, height: side)) else {
    print("crop fail"); exit(1)
}

// Draw the square crop filling a `target`×`target` square, centred in 1024.
let destRect = NSRect(x: (canvas - target) / 2, y: (canvas - target) / 2,
                      width: target, height: target)

let out = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
NSGraphicsContext.current?.imageInterpolation = .high
let img = NSImage(cgImage: cropped, size: NSSize(width: side, height: side))
img.draw(in: destRect, from: .zero, operation: .copy, fraction: 1.0)
NSGraphicsContext.restoreGraphicsState()

guard let png = out.representation(using: .png, properties: [:]) else { print("encode fail"); exit(1) }
try! png.write(to: URL(fileURLWithPath: outPath))
print("content \(cw)x\(ch) → square crop \(side)x\(side) → \(Int(target))x\(Int(target)) in \(Int(canvas)) → \(outPath)")
