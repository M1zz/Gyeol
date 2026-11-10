import SwiftUI
import LeeoKit

extension View {
    /// 앱의 맨 바깥 화면에 한 번 붙인다. 지금 칸과 페이월을 아래 화면에 흘리고(`planAccess`),
    /// 켤 때 · 돌아올 때 영수증을 다시 읽고, 때가 되면 구독 졸업을 한 번 권한다.
    func planRoot() -> some View { modifier(PlanRoot()) }
}

private struct PlanRoot: ViewModifier {
    @State private var purchases = PurchaseManager.shared
    @Bindable private var router = YeoulRouter.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingGraduation = false

    func body(content: Content) -> some View {
        content
            .environment(\.planAccess, PlanAccess(tier: purchases.tier) { feature in
                AnyView(PaywallView(highlight: feature))
            })
            // Siri · 단축어가 Pro 를 찾아 앱을 열었다 (→ AddEventIntent).
            .sheet(item: $router.paywall) { PaywallView(highlight: $0) }
            .sheet(isPresented: $showingGraduation) {
                LeeoGraduationOfferView(graduate: purchases.product(ProEntitlement.graduateID)) {
                    await purchases.refresh()
                }
                .presentationDetents([.medium, .large])
            }
            .task { await refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refresh() } }
            }
    }

    private func refresh() async {
        await purchases.refresh()
        // 연 구독 6개월째 · 갱신 7일 전에 한 번씩. 다른 창이 떠 있을 때는 다음 기회로 미룬다.
        if purchases.graduationIsDue, router.paywall == nil, !showingGraduation {
            purchases.markGraduationOffered()
            showingGraduation = true
        }
    }
}
