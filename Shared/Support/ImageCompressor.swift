import SwiftUI

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

enum ImageCompressor {
    /// Downscales so the longest side is at most `maxDimension`, then re-encodes as JPEG.
    static func jpeg(from data: Data, maxDimension: CGFloat = 1200, quality: CGFloat = 0.8) -> Data? {
        guard let image = PlatformImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return encode(image, to: scale < 1 ? target : image.size, quality: quality)
    }

    #if canImport(UIKit)
    private static func encode(_ image: UIImage, to target: CGSize, quality: CGFloat) -> Data? {
        let resized = target == image.size ? image : (image.preparingThumbnail(of: target) ?? image)
        return resized.jpegData(compressionQuality: quality)
    }
    #else
    private static func encode(_ image: NSImage, to target: CGSize, quality: CGFloat) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(target.width.rounded()),
            pixelsHigh: Int(target.height.rounded()),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )
        guard let rep else { return nil }
        rep.size = target

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.current = ctx
        ctx.cgContext.interpolationQuality = .high
        ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: target))

        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
    #endif
}
