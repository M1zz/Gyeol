import SwiftUI
import TipKit

// Tips point at the two things a person can't discover by looking: cards open in place,
// and tags gather milestones from every timeline. They come one at a time — the tag tip
// waits until the card tip has done its job — and each disappears for good once the
// person has used the feature it describes.

/// Shown on a timeline until a card has been tapped open once.
struct ExpandCardTip: Tip {
    @Parameter static var hasExpandedCard: Bool = false

    var title: Text { Text("카드를 눌러 펼쳐 보세요") }
    var message: Text? { Text("사진과 메모가 그 자리에서 열려요. 다시 누르면 접혀요.") }
    var image: Image? { Image(systemName: "hand.tap") }

    var rules: [Rule] {
        #Rule(Self.$hasExpandedCard) { $0 == false }
    }
}

/// Shown once someone has tagged a milestone, until they open a tag timeline.
struct TagTimelineTip: Tip {
    @Parameter static var hasTaggedEvent: Bool = false
    @Parameter static var hasOpenedTagTimeline: Bool = false

    var title: Text { Text("태그를 누르면 한데 모여요") }
    var message: Text? { Text("같은 태그가 붙은 사건을 모든 타임라인에서 모아 하나의 타임라인으로 보여 줘요.") }
    var image: Image? { Image(systemName: "number") }

    var rules: [Rule] {
        #Rule(ExpandCardTip.$hasExpandedCard) { $0 == true }
        #Rule(Self.$hasTaggedEvent) { $0 == true }
        #Rule(Self.$hasOpenedTagTimeline) { $0 == false }
    }
}
