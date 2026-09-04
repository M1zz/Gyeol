import UIKit

enum ImageCompressor {
    /// Downscales so the longest side is at most `maxDimension`, then re-encodes as JPEG.
    static func jpeg(from data: Data, maxDimension: CGFloat = 1200, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = scale < 1 ? (image.preparingThumbnail(of: target) ?? image) : image
        return resized.jpegData(compressionQuality: quality)
    }
}
