import XCTest
import SwiftData

// 이 시험 번들은 Shared/ 를 직접 컴파일한다(앱을 띄우지 않는다).
// 앱을 호스트로 띄우면 LeeoKit 부트스트랩과 CloudKit 이 서명·권한에 따라 시험을 흔들기 때문이다.

final class TagTests: XCTestCase {
    func testNormalizeDropsHashesAndWhitespace() {
        XCTAssertEqual(Tag.normalize("# 첫 걸음"), "첫걸음")
        XCTAssertEqual(Tag.normalize("##여행"), "여행")
        XCTAssertEqual(Tag.normalize("  출시\n"), "출시")
    }

    func testNormalizeRejectsEmpty() {
        XCTAssertNil(Tag.normalize(""))
        XCTAssertNil(Tag.normalize("   "))
        XCTAssertNil(Tag.normalize("###"))
    }

    func testMatchesIgnoresCase() {
        XCTAssertTrue(Tag.matches("WWDC", "wwdc"))
        XCTAssertFalse(Tag.matches("wwdc", "wwdc24"))
    }
}

final class DurationLabelTests: XCTestCase {
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testSameDay() {
        XCTAssertEqual(DurationLabel.between(date(2024, 3, 5), date(2024, 3, 5)), "같은 날")
    }

    func testDays() {
        XCTAssertEqual(DurationLabel.between(date(2024, 3, 5), date(2024, 3, 8)), "3일")
    }

    func testMonthsAndDays() {
        XCTAssertEqual(DurationLabel.between(date(2024, 1, 10), date(2024, 3, 15)), "2개월 5일")
        XCTAssertEqual(DurationLabel.between(date(2024, 1, 10), date(2024, 3, 10)), "2개월")
    }

    func testYearsAndMonths() {
        XCTAssertEqual(DurationLabel.between(date(2021, 1, 1), date(2023, 5, 1)), "2년 4개월")
        XCTAssertEqual(DurationLabel.between(date(2021, 1, 1), date(2023, 1, 20)), "2년")
    }
}

final class TrackScaleTests: XCTestCase {
    private let day: TimeInterval = 86_400

    func testSingleEventUsesUnitScale() {
        XCTAssertEqual(TrackScale(dates: [.now]).pointsPerDay, 1)
        XCTAssertEqual(TrackScale(dates: []).pointsPerDay, 1)
    }

    /// 같은 배율이 전체에 걸리므로 사흘과 닷새는 3:5 로 그려진다 — 이 앱의 약속.
    func testGapsAreProportionalToElapsedTime() {
        let start = Date(timeIntervalSince1970: 0)
        let scale = TrackScale(dates: [start, start.addingTimeInterval(8 * day)])
        let three = scale.gap(days: 3)
        let five = scale.gap(days: 5)
        XCTAssertFalse(three.isCompressed)
        XCTAssertFalse(five.isCompressed)
        XCTAssertEqual(three.height / five.height, 3.0 / 5.0, accuracy: 0.0001)
    }

    func testShortGapIsHeldAtMinimum() {
        let start = Date(timeIntervalSince1970: 0)
        let scale = TrackScale(dates: [start, start.addingTimeInterval(3650 * day)])
        let gap = scale.gap(days: 0.01)
        XCTAssertEqual(gap.height, TrackMetrics.minGap)
        XCTAssertFalse(gap.isCompressed)
    }

    func testLongGapIsCutAndMarkedCompressed() {
        let start = Date(timeIntervalSince1970: 0)
        let scale = TrackScale(dates: [start, start.addingTimeInterval(day)])
        let gap = scale.gap(days: 10_000)
        XCTAssertEqual(gap.height, TrackMetrics.maxGap)
        XCTAssertTrue(gap.isCompressed)
    }

    func testNegativeGapNeverGoesBelowMinimum() {
        let scale = TrackScale(dates: [.now, .now.addingTimeInterval(30 * day)])
        XCTAssertEqual(scale.gap(days: -5).height, TrackMetrics.minGap)
    }
}

final class TimelinePaletteTests: XCTestCase {
    /// 태그 색은 실행마다 같아야 한다 (hashValue 를 쓰면 프로세스마다 바뀐다).
    func testTagColourIsStableAndCaseInsensitive() {
        XCTAssertEqual(TimelinePalette.forTag("여행"), TimelinePalette.forTag("여행"))
        XCTAssertEqual(TimelinePalette.forTag("WWDC"), TimelinePalette.forTag("wwdc"))
        XCTAssertTrue(TimelinePalette.hexes.contains(TimelinePalette.forTag("아무 태그")))
    }

    func testNextCyclesThroughPalette() {
        XCTAssertEqual(TimelinePalette.next(after: 0), TimelinePalette.hexes[0])
        XCTAssertEqual(TimelinePalette.next(after: TimelinePalette.hexes.count), TimelinePalette.hexes[0])
        XCTAssertEqual(TimelinePalette.next(after: -1), TimelinePalette.hexes[1])
    }
}

@MainActor
final class TimelineModelTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: Store.schema,
            configurations: ModelConfiguration(schema: Store.schema, isStoredInMemoryOnly: true,
                                               cloudKitDatabase: .none)
        )
    }

    func testSortedEventsAreChronological() throws {
        let context = container.mainContext
        let timeline = Timeline(name: "첫 해", colorHex: TimelinePalette.hexes[0])
        context.insert(timeline)
        let base = Date(timeIntervalSince1970: 1_000_000)
        timeline.add(TimelineEvent(date: base.addingTimeInterval(200), title: "걸음"))
        timeline.add(TimelineEvent(date: base, title: "태어남"))
        timeline.add(TimelineEvent(date: base.addingTimeInterval(100), title: "첫 미소"))
        try context.save()

        XCTAssertEqual(timeline.sortedEvents.map(\.title), ["태어남", "첫 미소", "걸음"])
    }

    func testHasTagIgnoresCase() {
        let event = TimelineEvent(date: .now, title: "키노트", tags: ["WWDC"])
        XCTAssertTrue(event.hasTag("wwdc"))
        XCTAssertFalse(event.hasTag("출시"))
    }

    func testUnknownStyleFallsBackToClassic() {
        let event = TimelineEvent(date: .now, title: "미래 버전에서 온 카드")
        event.styleID = "from-the-future"
        XCTAssertEqual(event.style, .classic)
    }

    func testTagTimelineOwnsNoEvents() {
        let view = Timeline(name: "#여행", colorHex: TimelinePalette.forTag("여행"), tagFilter: "여행")
        XCTAssertTrue(view.isTagTimeline)
        XCTAssertTrue(view.sortedEvents.isEmpty)
    }
}
