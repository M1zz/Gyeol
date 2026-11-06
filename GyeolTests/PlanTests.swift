import XCTest
import SwiftData

// 칸마다 여는 것(Shared/Support/Plan.swift)과 기본 내보내기. 영수증 쪽(Gyeol/Store)은 LeeoKit 이 있어 여기서 돌지 않는다.

final class PlanAccessTests: XCTestCase {
    private func access(_ tier: PlanTier) -> PlanAccess {
        PlanAccess(tier: tier, paywall: { _ in fatalError("시험에서는 페이월을 띄우지 않는다") })
    }

    func testFreeKeepsTwoTimelines() {
        let free = access(.free)
        XCTAssertTrue(free.canCreateTimeline(having: 0))
        XCTAssertTrue(free.canCreateTimeline(having: 1))
        XCTAssertFalse(free.canCreateTimeline(having: 2))
        XCTAssertTrue(access(.plus).canCreateTimeline(having: 40))
    }

    func testCardStylesByTier() {
        let free = access(.free)
        XCTAssertTrue(free.canPick(.classic))
        XCTAssertTrue(free.canPick(.poster))
        XCTAssertFalse(free.canPick(.film))
        XCTAssertFalse(free.canPick(.editorial))
        XCTAssertTrue(access(.plus).canPick(.film))
    }

    /// 이미 필름으로 만든 카드는 무료가 되어도 그대로 고칠 수 있다.
    func testExistingCardKeepsItsStyle() {
        XCTAssertTrue(access(.free).canPick(.film, current: .film))
        XCTAssertFalse(access(.free).canPick(.editorial, current: .film))
    }

    func testProIncludesPlus() {
        let plus = access(.plus), pro = access(.pro)
        XCTAssertTrue(plus.allows(.tagTimelines))
        XCTAssertFalse(plus.allows(.iCloudSync))
        XCTAssertFalse(plus.allows(.siri))
        for feature in PlanFeature.allCases { XCTAssertTrue(pro.allows(feature), feature.rawValue) }
    }

    func testEveryPaidFeatureBelongsToAPaidTier() {
        XCTAssertTrue(PlanFeature.opened(by: .free).isEmpty)
        XCTAssertEqual(Set(PlanFeature.opened(by: .plus) + PlanFeature.opened(by: .pro)), Set(PlanFeature.allCases))
    }

    /// 맥 · 미리보기는 파는 곳이 없다 — 모두 열려 있어야 한다.
    func testUnlockedIsPro() {
        XCTAssertEqual(PlanAccess.unlocked.tier, .pro)
    }
}

@MainActor
final class TimelineExportTests: XCTestCase {
    func testTextListsEventsInOrderWithNotesAndTags() throws {
        let container = try ModelContainer(
            for: Store.schema,
            configurations: ModelConfiguration(schema: Store.schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let later = TimelineEvent(date: Date(timeIntervalSince1970: 1_700_000_000), title: "졸업식", tags: ["학교"])
        let earlier = TimelineEvent(date: Date(timeIntervalSince1970: 1_600_000_000), title: "입학", note: "  첫날  ")
        container.mainContext.insert(later)
        container.mainContext.insert(earlier)
        let text = TimelineExport.text(name: "학교", events: [later, earlier])
        let lines = text.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, "학교")
        XCTAssertTrue(text.range(of: "입학")!.lowerBound < text.range(of: "졸업식")!.lowerBound)
        XCTAssertTrue(lines.contains("첫날"))
        XCTAssertTrue(lines.contains("#학교"))
    }
}
