#!/usr/bin/env swift
import AppKit
import CoreGraphics
import UniformTypeIdentifiers

// Draws the Relay app icon — a rounded-square Liquid Glass tile with a deep-blue→cyan
// gradient, a soft top highlight, and a bold white forward chevron — and writes the full
// macOS AppIcon set (PNGs + Contents.json).
//
// Usage: swift generate_icon.swift <output-appiconset-dir>

func drawIcon(size S: CGFloat) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // macOS Big Sur icon grid: rounded square inset from the canvas, leaving room for shadow.
    let inset = S * 0.085
    let rect = CGRect(x: inset, y: inset, width: S - inset * 2, height: S - inset * 2)
    let corner = rect.width * 0.2237   // Apple's continuous-corner ratio
    let tile = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Drop shadow under the tile.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.012),
                  blur: S * 0.05,
                  color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(tile)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Deep-blue → cyan diagonal gradient fill, clipped to the tile.
    ctx.saveGState()
    ctx.addPath(tile)
    ctx.clip()
    let deepBlue = NSColor(srgbRed: 0.05, green: 0.27, blue: 0.85, alpha: 1).cgColor
    let cyan = NSColor(srgbRed: 0.20, green: 0.82, blue: 0.98, alpha: 1).cgColor
    let gradient = CGGradient(colorsSpace: cs, colors: [deepBlue, cyan] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.maxX, y: rect.minY),
                           options: [])

    // Glass highlight: a soft bright sheen across the upper portion.
    let sheen = CGGradient(colorsSpace: cs,
                           colors: [NSColor.white.withAlphaComponent(0.45).cgColor,
                                    NSColor.white.withAlphaComponent(0.0).cgColor] as CFArray,
                           locations: [0, 1])!
    ctx.drawLinearGradient(sheen,
                           start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05),
                           options: [])
    ctx.restoreGState()

    // Subtle inner stroke for depth.
    ctx.saveGState()
    ctx.addPath(tile)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    ctx.setLineWidth(S * 0.006)
    ctx.strokePath()
    ctx.restoreGState()

    // Bold white forward chevron (">") centered — relay / forward motion.
    let cx = rect.midX
    let cy = rect.midY
    let h = rect.height * 0.34       // chevron half-height span
    let w = rect.width * 0.17        // chevron horizontal reach
    let lineWidth = S * 0.085

    ctx.saveGState()
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.006),
                  blur: S * 0.02,
                  color: NSColor(srgbRed: 0.0, green: 0.15, blue: 0.4, alpha: 0.35).cgColor)
    let chevron = CGMutablePath()
    chevron.move(to: CGPoint(x: cx - w, y: cy + h))
    chevron.addLine(to: CGPoint(x: cx + w, y: cy))
    chevron.addLine(to: CGPoint(x: cx - w, y: cy - h))
    ctx.addPath(chevron)
    ctx.strokePath()
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// macOS AppIcon specification: (point size, scale).
let specs: [(Int, Int)] = [
    (16, 1), (16, 2), (32, 1), (32, 2),
    (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)
]

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: generate_icon.swift <output-dir>\n".utf8))
    exit(1)
}
let outDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

var entries: [[String: String]] = []
var rendered: [Int: CGImage] = [:]

for (point, scale) in specs {
    let pixels = point * scale
    let image = rendered[pixels] ?? drawIcon(size: CGFloat(pixels))
    rendered[pixels] = image
    let filename = "icon_\(point)x\(point)@\(scale)x.png"
    writePNG(image, to: outDir.appendingPathComponent(filename))
    entries.append([
        "size": "\(point)x\(point)",
        "idiom": "mac",
        "filename": filename,
        "scale": "\(scale)x"
    ])
}

let contents: [String: Any] = [
    "images": entries,
    "info": ["version": 1, "author": "relay-icon-generator"]
]
let data = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try data.write(to: outDir.appendingPathComponent("Contents.json"))

print("Wrote \(specs.count) icon images + Contents.json to \(outDir.path)")
