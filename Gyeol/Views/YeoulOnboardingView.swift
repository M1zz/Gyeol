import SwiftUI

/// 첫 실행 안내 — 여울이 다른 기록 앱과 다른 세 가지를 보여 준다.
/// 처음 한 번은 목록 화면이 띄우고(`hasSeenOnboarding`), 그 뒤로는 설정 > 여울 사용법에서 다시 연다.
struct YeoulOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page: Identifiable {
        let id: Int
        let symbol: String
        let title: LocalizedStringKey
        let body: LocalizedStringKey
    }

    private let pages: [Page] = [
        Page(id: 0, symbol: "calendar.day.timeline.left",
             title: "흐른 시간만큼 벌어지는 타임라인",
             body: "사건 사이의 간격이 실제로 흐른 시간에 비례해요. 사흘과 닷새는 3:5로 벌어지고, 긴 공백은 점선으로 접어 “2년 4개월”처럼 적어 둬요."),
        Page(id: 1, symbol: "photo.on.rectangle.angled",
             title: "그 날 찍은 사진을 바로 붙여요",
             body: "사건의 날짜를 고르고 ‘관련된 사진 찾기’를 누르면 그 날 찍은 사진을 모아 보여 줘요. 원하는 사진이 없으면 직접 골라도 돼요."),
        Page(id: 2, symbol: "number",
             title: "태그로 다시 엮어 보세요",
             body: "사건에 태그를 달고 누르면, 모든 타임라인에서 같은 태그가 붙은 순간을 모아 새 타임라인으로 보여 줘요. 기록은 iCloud로 아이폰·아이패드·맥에 이어져요."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages) { item in
                    VStack(spacing: 22) {
                        Spacer(minLength: 0)
                        Image(systemName: item.symbol)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text(item.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(item.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 520)
                    .scrollIfNeeded()
                    .tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .default) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? LocalizedStringKey("다음") : LocalizedStringKey("시작하기"))
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: 420)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .overlay(alignment: .topTrailing) {
            if page < pages.count - 1 {
                Button("건너뛰기") { finish() }
                    .padding()
            }
        }
        .interactiveDismissDisabled()
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: YeoulOnboardingView.seenKey)
        dismiss()
    }

    /// 화면 캡처 자동화는 `-hasSeenOnboarding YES` 인자로 이 안내를 건너뛴다.
    static let seenKey = "hasSeenOnboarding"
}

#Preview {
    YeoulOnboardingView()
}
