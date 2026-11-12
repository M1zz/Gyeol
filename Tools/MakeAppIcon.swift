import AppKit

// Flattens the Icon Composer icon (Shared/AppIcon.icon) into the plain PNGs of
// AppIcon.appiconset, so systems older than iOS 26 / macOS 26 show the same 여울.
//
//   swift Tools/MakeAppIcon.swift Shared/AppIcon.icon Shared/Assets.xcassets/AppIcon.appiconset
//
// ictool renders the glass icon already clipped to its rounded shape. iOS wants a full
// square without alpha and clips it itself, so each iOS render is laid on the icon's own
// background; the Mac keeps its shape and sits in the usual 824-of-1024 grid.

let ictool = "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
let args = CommandLine.arguments
let (icon, out) = (args[1], args[2])
let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("yeoul-icon")
try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

func export(_ platform: String, _ rendition: String) -> CGImage {
    let file = tmp.appendingPathComponent("\(platform)-\(rendition).png").path
    let p = Process()
    p.executableURL = URL(fileURLWithPath: ictool)
    p.arguments = [icon, "--export-image", "--output-file", file, "--platform", platform,
                   "--rendition", rendition, "--width", "1024", "--height", "1024", "--scale", "1"]
    p.standardOutput = FileHandle.nullDevice
    try! p.run(); p.waitUntilExit()
    return NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: file)))!.cgImage!
}

func p3(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!, components: [r, g, b, 1])!
}

func write(_ ctx: CGContext, _ name: String) {
    let png = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
    print("wrote \(name).png")
}

// iOS — opaque squares. Background = icon.json fill (top → bottom), black for tinted.
let ios: [(name: String, rendition: String, top: CGColor, bottom: CGColor, gray: Bool)] = [
    ("AppIcon", "Default", p3(0.18431, 0.65882, 0.59216), p3(0.07451, 0.41569, 0.38039), false),
    ("AppIcon-Dark", "Dark", p3(0.05882, 0.23137, 0.21176), p3(0.02353, 0.12157, 0.10980), false),
    ("AppIcon-Tinted", "ClearDark", p3(0, 0, 0), p3(0, 0, 0), true),
]
for v in ios {
    let space = v.gray ? CGColorSpaceCreateDeviceGray() : CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: (v.gray ? CGImageAlphaInfo.none
                                                                  : .noneSkipLast).rawValue)!
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.displayP3),
                       colors: [v.top, v.bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 512, y: 1024), end: CGPoint(x: 512, y: 0), options: [])
    ctx.draw(export("iOS", v.rendition), in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    write(ctx, v.name)
}

// macOS — keeps the rounded shape with transparent margin, at every size the set lists.
let mac = export("macOS", "Default")
for px in [16, 32, 64, 128, 256, 512, 1024] {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    let inset = CGFloat(px) * 100 / 1024
    ctx.draw(mac, in: CGRect(x: 0, y: 0, width: px, height: px).insetBy(dx: inset, dy: inset))
    write(ctx, "AppIcon-mac-\(px)")
}
