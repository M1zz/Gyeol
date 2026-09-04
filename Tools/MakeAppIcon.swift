import AppKit
import CoreText

// Renders the 결 app icon. The glyph is set in AppleMyungjo to match the serif the
// timeline uses for dates and titles; the faint ruled ground is the "결" (grain) itself.

let size: CGFloat = 1024

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF)/255, green: CGFloat((v >> 8) & 0xFF)/255,
            blue: CGFloat(v & 0xFF)/255, alpha: a)
}

struct Variant {
    let name: String
    let top: NSColor
    let bottom: NSColor
    let ink: NSColor
    let grain: NSColor
}

func render(_ v: Variant) -> Data {
    // No alpha channel: the App Store rejects icons with transparency.
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                        bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

    let colors = [v.top.cgColor, v.bottom.cgColor] as CFArray
    if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    }

    ctx.setFillColor(v.grain.cgColor)
    var y: CGFloat = 60
    while y < size {
        ctx.fill(CGRect(x: 0, y: size - y, width: size, height: 3))
        y += 46
    }

    func line(_ pt: CGFloat) -> CTLine {
        let font = NSFont(name: "AppleMyungjo", size: pt) ?? NSFont.systemFont(ofSize: pt, weight: .medium)
        return CTLineCreateWithAttributedString(
            NSAttributedString(string: "결", attributes: [.font: font, .foregroundColor: v.ink])
        )
    }

    // Scale so the glyph's ink — not its line box — fills the target, then centre that ink.
    let probe: CGFloat = 600
    let probeInk = CTLineGetImageBounds(line(probe), ctx)
    let pt = probe * (620 / max(probeInk.width, probeInk.height))
    let glyph = line(pt)
    let ink = CTLineGetImageBounds(glyph, ctx)
    ctx.textPosition = CGPoint(x: size/2 - ink.midX, y: size/2 - ink.midY)
    CTLineDraw(glyph, ctx)

    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

let variants = [
    Variant(name: "AppIcon", top: hex(0x35786A), bottom: hex(0x1B4036),
            ink: hex(0xF4EEE1), grain: hex(0xFFFFFF, 0.05)),
    Variant(name: "AppIcon-Dark", top: hex(0x16302A), bottom: hex(0x070D0B),
            ink: hex(0xBFE6DA), grain: hex(0x7CC0AE, 0.06)),
    Variant(name: "AppIcon-Tinted", top: hex(0x2E2E2E), bottom: hex(0x000000),
            ink: hex(0xFFFFFF), grain: hex(0xFFFFFF, 0.06)),
]

let out = CommandLine.arguments[1]
for v in variants {
    try! render(v).write(to: URL(fileURLWithPath: "\(out)/\(v.name).png"))
    print("wrote \(v.name).png")
}
