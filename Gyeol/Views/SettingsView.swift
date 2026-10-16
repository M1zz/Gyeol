import SwiftUI
import LeeoKit

/// 설정 — 사용법 다시 보기와 개발자에게 닿는 길(앱 안 피드백 · 메일 · 인스타그램 · 리뷰).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingOnboarding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingOnboarding = true
                    } label: {
                        Label("여울 사용법", systemImage: "book")
                    }
                } footer: {
                    Text("처음 열었을 때 보았던 안내를 다시 볼 수 있어요.")
                }

                Section {
                    // 앱 안 피드백 · 보낸 의견의 답장 · 리뷰 남기기 · 개인정보 처리방침 · 지원 페이지 · 버전
                    LeeoSupportSection<YeoulSpec>()
                    Link(destination: Self.mailURL) {
                        Label("메일로 문의하기", systemImage: "envelope")
                    }
                    Link(destination: URL(string: "https://instagram.com/lee25_ios")!) {
                        Label("인스타그램 DM (@lee25_ios)", systemImage: "paperplane")
                    }
                } header: {
                    Text("지원")
                } footer: {
                    Text("보내 주신 의견은 개발자가 모두 직접 읽어요. 불편했던 점이나 바라는 기능을 알려 주세요.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                YeoulOnboardingView()
            }
        }
    }

    /// 메일 앱이 없는 기기에서도 링크가 열리도록 mailto: 로 둔다. 제목에 앱 이름과 버전을 적어
    /// 받는 쪽이 어느 앱·어느 버전 이야기인지 바로 알 수 있게 한다.
    static var mailURL: URL {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = YeoulSpec.developerEmail
        components.queryItems = [URLQueryItem(name: "subject", value: "[여울 \(version)] 문의")]
        return components.url ?? URL(string: "mailto:\(YeoulSpec.developerEmail)")!
    }
}

#Preview {
    SettingsView()
}
