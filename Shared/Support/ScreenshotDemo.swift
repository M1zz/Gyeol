#if DEBUG
import Foundation
import SwiftData

/// 스토어 스크린샷 전용 — DEBUG 빌드에서만 들어간다. 출시 빌드에는 이 파일이 없다.
///
/// scripts/capture_screenshots.sh 가 시뮬레이터에서 이렇게 띄운다:
///   -localOnly -demoSeed <언어별 예시 기록 JSON> -demoPhotos <사진 폴더>
///   -demoScreen trip|tag|list  -demoTimeline <번호>  -demoTag <태그>
///   -demoScroll <사건 번호> [-demoAnchor <0~1, 그 사건이 놓일 화면 높이>]  -demoExpand <사건 번호>  -demoEdit <사건 번호>
/// 예시 기록은 scripts/screenshot_demo/<언어>.json 이다 — 화면 속 기록도 그 언어로 보이게.
enum ScreenshotDemo {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static func value(_ key: String) -> String? {
        guard let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    static func index(_ key: String) -> Int? { value(key).flatMap(Int.init) }

    static var isActive: Bool { value("-demoSeed") != nil }
    static var screen: String? { value("-demoScreen") }

    private struct Seed: Decodable {
        struct Line: Decodable {
            let name: String
            let color: String
            let tagFilter: String?
            let events: [Event]?
        }
        struct Event: Decodable {
            let date: String
            let title: String
            let note: String?
            let tags: [String]?
            let style: String?
            let photo: String?
        }
        let timelines: [Line]
    }

    /// 저장소를 비우고 예시 기록으로 채운다.
    @MainActor
    static func seedIfRequested(into container: ModelContainer) {
        guard let path = value("-demoSeed"),
              let data = FileManager.default.contents(atPath: path),
              let seed = try? JSONDecoder().decode(Seed.self, from: data) else { return }
        let photos = value("-demoPhotos").map { URL(fileURLWithPath: $0) }
        let context = container.mainContext
        try? context.delete(model: TimelineEvent.self)
        try? context.delete(model: Timeline.self)

        let day = DateFormatter()
        day.calendar = Calendar(identifier: .gregorian)
        day.locale = Locale(identifier: "en_US_POSIX")
        day.dateFormat = "yyyy-MM-dd"

        var created = Date(timeIntervalSince1970: 1_700_000_000)
        for line in seed.timelines {
            let timeline = Timeline(name: line.name, colorHex: line.color, createdAt: created, tagFilter: line.tagFilter)
            created.addTimeInterval(60)
            context.insert(timeline)
            for e in line.events ?? [] {
                let photo = e.photo.flatMap { name in
                    photos.flatMap { try? Data(contentsOf: $0.appendingPathComponent(name)) }
                }.flatMap { ImageCompressor.jpeg(from: $0) }
                let event = TimelineEvent(
                    date: (day.date(from: e.date) ?? .now).addingTimeInterval(12 * 3600),
                    title: e.title,
                    note: e.note ?? "",
                    tags: e.tags ?? [],
                    style: CardStyle(rawValue: e.style ?? "") ?? .classic,
                    photoData: photo
                )
                context.insert(event)
                timeline.add(event)
            }
        }
        try? context.save()
    }
}
#endif
