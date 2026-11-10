import SwiftUI
import StoreKit
import LeeoKit

/// 설정 ▸ 요금제. 지금 쓰는 칸 · 요금제 보기 · 구독 관리 · 평생으로 바꾸기 · 구매 복원 · iCloud 동기화.
struct PlanSettingsSection: View {
    @State private var purchases = PurchaseManager.shared
    @State private var paywall: PaywallRoute?
    @State private var showingGraduation = false
    @State private var showingManage = false
    @State private var syncWanted = ProEntitlement.syncWanted
    @Environment(\.openURL) private var openURL

    private struct PaywallRoute: Identifiable {
        var feature: PlanFeature?
        var term: LeeoPlanTerm?
        var id: String { "\(feature?.rawValue ?? "settings").\(term?.rawValue ?? "")" }
    }

    var body: some View {
        Section {
            LabeledContent("지금 쓰는 칸", value: purchases.ownedTier.title)
            if purchases.isGrandfathered {
                Text("페이월이 생기기 전부터 써 주셔서 Pro를 평생 드려요.")
                    .foregroundStyle(.secondary)
            }
            if !purchases.hasLifetimePro {
                Button("요금제 보기") { paywall = PaywallRoute() }
            }
            if purchases.hasSubscription {
                Button("구독 관리") { showingManage = true }
            }
            if !purchases.hasLifetimePro {
                Button(LeeoLadderText.switchToLifetimeEntry) { switchToLifetime() }
            }
            Button("구매 복원") { Task { await purchases.restore() } }
                .disabled(purchases.isWorking)
            Toggle(isOn: Binding(get: { syncWanted && purchases.allows(.iCloudSync) }, set: setSync)) {
                Label("iCloud 동기화", systemImage: "icloud")
            }
        } header: {
            Text("요금제")
        } footer: {
            Text(syncFooter)
        }
        .sheet(item: $paywall) { route in
            PaywallView(highlight: route.feature, term: route.term)
        }
        .sheet(isPresented: $showingGraduation) {
            LeeoGraduationOfferView(graduate: purchases.product(ProEntitlement.graduateID)) {
                await purchases.refresh()
            }
            .presentationDetents([.medium, .large])
        }
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $showingManage)
        #else
        // 맥에는 구독 관리 시트가 없다. App Store 의 구독 화면을 연다.
        .onChange(of: showingManage) { _, wanted in
            guard wanted else { return }
            showingManage = false
            openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
        }
        #endif
    }

    /// 연 구독 중이면 졸업가를, 아니면 평생을 고른 페이월을 낸다.
    private func switchToLifetime() {
        if purchases.subscription != nil, purchases.product(ProEntitlement.graduateID) != nil {
            showingGraduation = true
        } else {
            paywall = PaywallRoute(feature: purchases.ownedTier == .plus ? .iCloudSync : nil, term: .lifetime)
        }
    }

    private func setSync(_ on: Bool) {
        if on && !purchases.allows(.iCloudSync) {
            paywall = PaywallRoute(feature: .iCloudSync)
            return
        }
        syncWanted = on
        ProEntitlement.syncWanted = on
    }

    /// 저장소는 켤 때 한 번 고른다. 지금 연 것과 다음에 열 것이 다르면 다시 열 때 바뀐다고 알린다.
    private var syncFooter: String {
        let next = LeeoRemoteFlags.isEnabled(YeoulFlag.cloudSyncEnabled) && Store.syncsWithCloud && ProEntitlement.syncsWithICloud
        if next != Store.isMirroring { return String(localized: "앱을 완전히 닫았다가 다시 열면 바뀌어요. 이 기기의 기록은 그대로 남아요.") }
        if Store.isMirroring { return String(localized: "iPhone과 iPad의 기록을 iCloud로 맞추고 있어요.") }
        return purchases.allows(.iCloudSync)
            ? String(localized: "기록은 이 기기에만 저장돼요.")
            : String(localized: "기록은 이 기기에만 저장돼요. iCloud 동기화는 Pro에서 켤 수 있어요.")
    }
}
