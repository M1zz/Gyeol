//
//  PaywallView.swift
//  Yeoul
//
//  Plus · Pro 를 파는 한 장. 칸 카드 둘(칸마다 연 구독 / 평생, 주 · 월은 펼쳐서) → 세 칸 비교표 → 약관.
//
//  ⚠️ 스토어에 아직 없는 상품은 불러와지지 않는다. 그 단추는 서지 않는다(없는 것을 팔지 않는다).
//  첫 해 할인(App Store 첫 구독 할인)과 "연 구독 N년치" 한 줄은 `LeeoTermPicker` 가 알아서 보인다.
//

import SwiftUI
import StoreKit
import LeeoKit

extension PlanTier {
    var title: String {
        switch self {
        case .free: String(localized: "무료")
        case .plus: String(localized: "여울 Plus")
        case .pro:  String(localized: "여울 Pro")
        }
    }

    /// 비교표 머리의 짧은 이름.
    var shortName: String {
        switch self {
        case .free: String(localized: "무료")
        case .plus: "Plus"
        case .pro:  "Pro"
        }
    }

    /// 페이월 카드의 한 줄.
    var tagline: String {
        switch self {
        case .free: String(localized: "흐른 시간만큼 벌어지는 내 연표를 직접 그리기")
        case .plus: String(localized: "주제마다 연표를, 순간마다 어울리는 카드로")
        case .pro:  String(localized: "모든 기기에서 지키고, 말로 바로 남기기")
        }
    }
}

extension PlanFeature {
    var title: String {
        switch self {
        case .moreTimelines: String(localized: "타임라인 무제한")
        case .tagTimelines:  String(localized: "해시태그 타임라인 저장")
        case .cardStyles:    String(localized: "카드 디자인 네 가지 전부")
        case .iCloudSync:    String(localized: "iCloud 동기화")
        case .siri:          String(localized: "Siri · 단축어로 순간 추가") + PlanFeature.otherDevicesOnly
        }
    }

    var note: String {
        switch self {
        case .moreTimelines: String(localized: "아이, 연애, 커리어처럼 주제마다 연표를 따로 그려요.")
        case .tagTimelines:  String(localized: "#여행처럼 태그로 모인 순간을 목록에 두고, 태그가 붙는 대로 계속 채워요.")
        case .cardStyles:    String(localized: "인화지 같은 필름, 날짜가 주인공인 여백까지 골라요.")
        case .iCloudSync:    String(localized: "iPhone과 iPad에서 같은 연표를 보고, 폰을 바꿔도 기록이 그대로예요.")
        case .siri:          String(localized: "앱을 열지 않고 말로 바로 순간을 남겨요.")
        }
    }

    var systemImage: String {
        switch self {
        case .moreTimelines: "calendar.day.timeline.left"
        case .tagTimelines:  "number"
        case .cardStyles:    "rectangle.on.rectangle"
        case .iCloudSync:    "icloud.fill"
        case .siri:          "mic.fill"
        }
    }

    /// 처음 고를 길. 평생 기록을 지키는 동기화는 평생이 맞다. 나머지는 연 구독.
    var suggestedTerm: LeeoPlanTerm { self == .iCloudSync ? .lifetime : .yearly }
}

extension PlanFeature {
    /// 맥 앱에는 Siri · 단축어로 남기기가 없다. 같은 구매로 iPhone · iPad 에서 열리므로, 맥에서는 이름 뒤에 그렇게 적는다.
    static var otherDevicesOnly: String {
        #if os(macOS)
        " (iPhone · iPad)"
        #else
        ""
        #endif
    }
}

struct PaywallView: View {
    /// 어디서 들어왔는가. 그 기능이 든 칸을 맨 위에 세우고 강조한다.
    var highlight: PlanFeature?
    /// 처음 고를 길. 비우면 들어온 기능에 맞춘다(`suggestedTerm`).
    var term: LeeoPlanTerm?

    @State private var purchases = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 **이 페이월이 떠 있는 창**에 띄운다.
    @Environment(\.purchase) private var purchaseAction

    @State private var plusTerm: LeeoPlanTerm = .yearly
    @State private var proTerm: LeeoPlanTerm = .yearly
    @State private var loadingProducts = true
    @State private var redeemingCode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    plansStatus
                    ForEach(tierOrder, id: \.self) { tierCard($0) }
                    PlanComparisonTable()
                    if let message = purchases.failureMessage, !purchases.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                    legal
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.groupedBackground)
            .navigationTitle("요금제")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Label("닫기", systemImage: "xmark") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("복원") { Task { await restore() } }
                        .disabled(purchases.isWorking)
                }
            }
            #if os(iOS)
            .offerCodeRedemption(isPresented: $redeemingCode) { _ in
                Task {
                    await purchases.refresh()
                    if let highlight, purchases.allows(highlight) { dismiss() }
                }
            }
            #endif
            .task {
                let chosen = term ?? highlight?.suggestedTerm ?? .yearly
                switch highlight?.tier {
                case .pro?: proTerm = chosen
                case .plus?: plusTerm = chosen
                default: plusTerm = chosen; proTerm = chosen
                }
                LeeoAnalyticsCenter.track(.paywallShown(reason: highlight?.rawValue ?? "settings"))
                await loadPlans()
            }
        }
        // 맥의 시트는 내용의 이상적 크기로 줄어든다. 요금제는 세로로 길어 크기를 정해 둔다.
        #if os(macOS)
        .frame(minWidth: 560, idealWidth: 640, minHeight: 680, idealHeight: 760)
        #endif
    }

    /// 들어온 기능의 칸을 앞에.
    private var tierOrder: [PlanTier] { highlight?.tier == .pro ? [.pro, .plus] : [.plus, .pro] }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("여울 Plus · Pro")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text("주제마다 연표를, 모든 기기에서 안전하게. 연 구독이나 평생 중에 고르세요.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 칸

    private func tierCard(_ tier: PlanTier) -> some View {
        let owned = purchases.ownedTier == tier
        let highlighted = highlight?.tier == tier && !owned
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(tier.title)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                if owned {
                    Text("지금 쓰는 칸")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                Spacer(minLength: 0)
            }
            Text(tier.tagline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if tier == .pro {
                featureRow(systemImage: "square.stack.3d.up.fill", title: String(localized: "Plus의 모든 것"), note: nil)
            }
            ForEach(features(in: tier)) { feature in
                featureRow(systemImage: feature.systemImage, title: feature.title, note: feature.note,
                           highlighted: feature == highlight)
            }
            // 스토어에서 불러온 상품이 있을 때만 고르기와 구매 단추를 세운다.
            if purchases.canBuy(tier) && (yearly(tier) != nil || lifetime(tier) != nil) {
                LeeoTermPicker(term: termBinding(tier), yearly: yearly(tier), lifetime: lifetime(tier))
                    .padding(.top, 4)
                buyButton(tier)
                shortPlans(tier)
            }
        }
        .planCard()
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(highlighted ? Color.accentColor : .clear, lineWidth: 2)
        }
    }

    /// 그 칸에서 새로 열리는 것. 지금 누른 자리가 맨 위.
    private func features(in tier: PlanTier) -> [PlanFeature] {
        let opened = PlanFeature.opened(by: tier)
        guard let highlight, opened.contains(highlight) else { return opened }
        return [highlight] + opened.filter { $0 != highlight }
    }

    private func featureRow(systemImage: String, title: String, note: String?, highlighted: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(highlighted ? Color.accentColor : .secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                if let note {
                    Text(note)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 상품

    private func termBinding(_ tier: PlanTier) -> Binding<LeeoPlanTerm> {
        tier == .plus ? $plusTerm : $proTerm
    }

    private func yearly(_ tier: PlanTier) -> Product? {
        purchases.product(tier == .plus ? ProEntitlement.plusYearlyID : ProEntitlement.proYearlyID)
    }

    /// 칸의 평생. **Plus 평생을 이미 산 사람에게는 Pro 평생 자리에 올리기 상품을 세운다.**
    private func lifetime(_ tier: PlanTier) -> Product? {
        if tier == .plus { return purchases.product(ProEntitlement.plusLifetimeID) }
        return purchases.product(upgradesToPro ? ProEntitlement.upgradeID : ProEntitlement.proLifetimeID)
    }

    private var upgradesToPro: Bool { purchases.ownsLifetime(.plus) }

    private func buyButton(_ tier: PlanTier) -> some View {
        let chosen = termBinding(tier).wrappedValue
        let product = chosen == .yearly ? yearly(tier) : lifetime(tier)
        let title: String = switch chosen {
        case .yearly: String(localized: "연 구독 시작")
        case .lifetime where tier == .pro && upgradesToPro: String(localized: "Pro 평생으로 올리기")
        case .lifetime: String(localized: "평생으로 사기")
        }
        return Button {
            guard let product else { return }
            Task { await buy(product, opening: tier) }
        } label: {
            Group {
                if purchases.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(purchases.isWorking || product.map { purchases.owns($0.id) } ?? true)
    }

    /// 주 · 월 구독. 연이 기본이고, 짧게 써 보고 싶은 분에게만 펼쳐 보인다. 스토어에 없으면 줄째 숨는다.
    @ViewBuilder
    private func shortPlans(_ tier: PlanTier) -> some View {
        let weekly = purchases.product(tier == .plus ? ProEntitlement.plusWeeklyID : ProEntitlement.proWeeklyID)
        let monthly = purchases.product(tier == .plus ? ProEntitlement.plusMonthlyID : ProEntitlement.proMonthlyID)
        if weekly != nil || monthly != nil {
            DisclosureGroup("주간 · 월간으로 보기") {
                VStack(spacing: 8) {
                    if let weekly { shortPlanButton(weekly, tier, title: String(localized: "주간 \(weekly.displayPrice)")) }
                    if let monthly { shortPlanButton(monthly, tier, title: String(localized: "월간 \(monthly.displayPrice)")) }
                }
                .padding(.top, 8)
            }
        }
    }

    private func shortPlanButton(_ product: Product, _ tier: PlanTier, title: String) -> some View {
        Button {
            Task { await buy(product, opening: tier) }
        } label: {
            Text(title)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .disabled(purchases.isWorking || purchases.owns(product.id))
    }

    private func buy(_ product: Product, opening tier: PlanTier) async {
        await purchases.purchase(product, using: purchaseAction)
        if purchases.ownedTier >= tier { dismiss() }
    }

    private func restore() async {
        await purchases.restore()
        if purchases.ownedTier > .free { dismiss() }
    }

    // MARK: 불러오기

    @ViewBuilder
    private var plansStatus: some View {
        if purchases.products.isEmpty && loadingProducts {
            HStack(spacing: 10) {
                ProgressView()
                Text("요금제를 불러오는 중…").foregroundStyle(.secondary)
            }
        } else if purchases.products.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("요금제를 불러오지 못했어요. 인터넷 연결을 확인하고 다시 불러와 주세요.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label("다시 불러오기", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    /// 샌드박스(심사 환경)는 첫 조회가 빈손으로 돌아오는 일이 잦아 한 번 더 청한다.
    private func loadPlans() async {
        loadingProducts = true
        await purchases.loadProducts()
        if purchases.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await purchases.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 12) {
            if purchases.products.contains(where: { $0.subscription != nil }) {
                Text("구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 값으로 자동 갱신되고, Apple 계정으로 결제돼요. 연 구독을 처음 시작하면 첫 해는 할인된 값으로, 그 뒤로는 정가로 갱신돼요. 해지와 관리는 App Store 계정 설정에서 할 수 있어요. 평생은 구독이 아니라 한 번만 결제해요.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ViewThatFits {
                HStack(spacing: 20) { legalButtons }
                VStack(alignment: .leading, spacing: 12) { legalButtons }
            }
        }
    }

    @ViewBuilder
    private var legalButtons: some View {
        if let terms = YeoulSpec.monetization.subscriptionTermsURL {
            Button("이용약관") { openURL(terms) }
        }
        Button("개인정보 처리방침") { openURL(YeoulSpec.legal.privacyURL) }
        Button("구매 복원") { Task { await restore() } }
            .disabled(purchases.isWorking)
        // 맥의 코드 사용은 App Store 앱에서 한다.
        #if os(iOS)
        Button("코드 사용") { redeemingCode = true }
            .disabled(purchases.isWorking)
        #endif
    }
}

// MARK: - 세 칸 비교표

/// 페이월에 그대로 서는 표. 무료로 되는 것을 먼저 말한다.
struct PlanComparisonTable: View {
    private enum Cell {
        case yes, no, text(String)
    }

    private struct Row: Identifiable {
        let label: String
        let cells: [Cell]   // 무료 · Plus · Pro
        var id: String { label }
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    private var rows: [Row] {
        let unlimited = String(localized: "무제한")
        let freeStyles = PlanFeature.freeCardStyles.count
        let allStyles = CardStyle.allCases.count
        return [
            Row(label: String(localized: "타임라인"),
                cells: [.text(String(localized: "\(PlanFeature.freeTimelineLimit)개")), .text(unlimited), .text(unlimited)]),
            Row(label: String(localized: "순간 · 사진 · 이야기"), cells: [.text(unlimited), .text(unlimited), .text(unlimited)]),
            Row(label: String(localized: "그날 사진 찾기"), cells: [.yes, .yes, .yes]),
            Row(label: String(localized: "해시태그 모아 보기"), cells: [.yes, .yes, .yes]),
            Row(label: String(localized: "텍스트로 내보내기"), cells: [.yes, .yes, .yes]),
            Row(label: PlanFeature.tagTimelines.title, cells: [.no, .yes, .yes]),
            Row(label: String(localized: "카드 디자인"),
                cells: [.text(String(localized: "\(freeStyles)개")), .text(String(localized: "\(allStyles)개")),
                        .text(String(localized: "\(allStyles)개"))]),
            Row(label: String(localized: "iCloud 동기화 · 여러 기기"), cells: [.no, .no, .yes]),
            Row(label: String(localized: "Siri · 단축어") + PlanFeature.otherDevicesOnly, cells: [.no, .no, .yes]),
        ]
    }

    private let tiers: [PlanTier] = [.free, .plus, .pro]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("한눈에 비교")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            if typeSize.isAccessibilitySize {
                stacked
            } else {
                grid
            }
        }
        .planCard()
    }

    /// 보통 글자: 네 칸 표.
    private var grid: some View {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(tiers, id: \.self) { tier in
                    Text(tier.shortName)
                        .font(.body.weight(.semibold))
                        .gridColumnAlignment(.center)
                }
            }
            .accessibilityHidden(true)
            ForEach(rows) { row in
                Divider()
                GridRow {
                    Text(row.label)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                        cellView(cell)
                            .frame(minWidth: 56)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken(row))
            }
        }
    }

    /// 아주 큰 글자: 줄마다 위아래로.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.label).font(.body.weight(.semibold))
                    ForEach(Array(zip(tiers, row.cells)), id: \.0) { tier, cell in
                        HStack {
                            Text(tier.shortName).foregroundStyle(.secondary)
                            Spacer()
                            cellView(cell)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken(row))
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: Cell) -> some View {
        switch cell {
        case .yes:
            Image(systemName: "checkmark")
                .font(.body.weight(.bold))
                .foregroundStyle(.green)
        case .no:
            Text(verbatim: "–").foregroundStyle(.secondary)
        case .text(let value):
            Text(value)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// VoiceOver 가 한 줄을 한 번에 읽는다: "타임라인, 무료 2개, Plus 무제한, Pro 무제한".
    private func spoken(_ row: Row) -> String {
        let parts = zip(tiers, row.cells).map { tier, cell -> String in
            let value: String = switch cell {
            case .yes: String(localized: "포함")
            case .no: String(localized: "없음")
            case .text(let text): text
            }
            return "\(tier.shortName) \(value)"
        }
        return ([row.label] + parts).joined(separator: ", ")
    }
}

private extension View {
    func planCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
