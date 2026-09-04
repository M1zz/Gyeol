import Photos
import SwiftUI

/// One picture from the system library, already thumbnailed for the strip.
struct DayPhoto: Identifiable {
    let id: String
    let asset: PHAsset
    let thumbnail: UIImage
}

/// Finds the pictures taken on a particular day, so a card can offer the photos that
/// already exist for its date before the user has to go hunting through the library.
@MainActor
final class DayPhotoFinder: ObservableObject {
    enum State {
        case idle
        case loading
        case denied
        case loaded([DayPhoto])
    }

    @Published private(set) var state: State = .idle

    private static let thumbnailSize = CGSize(width: 220, height: 220)
    private static let limit = 40

    func reset() { state = .idle }

    func find(on date: Date) async {
        state = .loading

        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { continuation.resume(returning: $0) }
        }
        guard status == .authorized || status == .limited else {
            state = .denied
            return
        }

        guard let day = Calendar.current.dateInterval(of: .day, for: date) else {
            state = .loaded([])
            return
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@",
            day.start as NSDate, day.end as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.fetchLimit = Self.limit
        let assets = PHAsset.fetchAssets(with: .image, options: options)

        var found: [DayPhoto] = []
        for index in 0..<assets.count {
            let asset = assets.object(at: index)
            if let thumbnail = await Self.thumbnail(for: asset) {
                found.append(DayPhoto(id: asset.localIdentifier, asset: asset, thumbnail: thumbnail))
            }
        }
        state = .loaded(found)
    }

    /// Full-resolution data for the asset the user tapped, compressed like any other photo.
    func photoData(for photo: DayPhoto) async -> Data? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let raw: Data? = await withCheckedContinuation { continuation in
            let guardOnce = ResumeGuard()
            PHImageManager.default().requestImageDataAndOrientation(for: photo.asset, options: options) { data, _, _, _ in
                guard guardOnce.claim() else { return }
                continuation.resume(returning: data)
            }
        }
        guard let raw else { return nil }
        return ImageCompressor.jpeg(from: raw)
    }

    private static func thumbnail(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        // fastFormat hands back nil when the asset has no cached thumbnail yet — which is
        // exactly the case for recently imported photos — so ask for the real thing.
        // Like fastFormat (and unlike opportunistic) it delivers a single result.
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            let guardOnce = ResumeGuard()
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard guardOnce.claim() else { return }
                continuation.resume(returning: image)
            }
        }
    }
}

/// PhotoKit calls some result handlers more than once, and resuming a continuation twice
/// is a crash — every completion below goes through this first.
private final class ResumeGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if claimed { return false }
        claimed = true
        return true
    }
}
