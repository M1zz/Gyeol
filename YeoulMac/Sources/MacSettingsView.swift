import SwiftUI
import LeeoKit

/// 맥의 설정 창. 요금제(지금 쓰는 칸 · 요금제 보기 · 구매 복원 · iCloud 동기화)와 개발자에게 닿는 길.
struct MacSettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                PlanSettingsSection()
                Section("지원") {
                    LeeoSupportSection<YeoulSpec>()
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 560)
    }
}
