import SwiftUI

extension Color {
    init(hex: String) {
        let (r, g, b) = Self.components(hex: hex)
        self.init(red: r, green: g, blue: b)
    }

    /// 타임라인 색처럼 글씨에도 쓰이는 정해진 색. 짙은 색이라 어두운 화면에서는 밝게 올리고,
    /// '대비 증가'를 켜면 한 번 더 벌려 — 어느 모드에서나 카드 위 글씨가 읽히게 한다.
    static func adaptive(hex: String) -> Color {
        let base = components(hex: hex)
        func mix(_ toward: Double, _ amount: Double) -> (Double, Double, Double) {
            (base.0 + (toward - base.0) * amount,
             base.1 + (toward - base.1) * amount,
             base.2 + (toward - base.2) * amount)
        }
        // (어두운 화면?, 대비 증가?) → 섞을 색과 양
        func resolved(dark: Bool, highContrast: Bool) -> (Double, Double, Double) {
            switch (dark, highContrast) {
            case (false, false): base
            case (false, true): mix(0, 0.3)
            case (true, false): mix(1, 0.45)
            case (true, true): mix(1, 0.6)
            }
        }
        #if canImport(UIKit)
        return Color(UIColor { traits in
            let c = resolved(dark: traits.userInterfaceStyle == .dark,
                             highContrast: traits.accessibilityContrast == .high)
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #else
        return Color(NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua,
                                                    .accessibilityHighContrastAqua,
                                                    .accessibilityHighContrastDarkAqua])
            let c = resolved(dark: match == .darkAqua || match == .accessibilityHighContrastDarkAqua,
                             highContrast: match == .accessibilityHighContrastAqua
                                 || match == .accessibilityHighContrastDarkAqua)
            return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #endif
    }

    private static func components(hex: String) -> (Double, Double, Double) {
        var value: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&value)
        return (Double((value >> 16) & 0xFF) / 255,
                Double((value >> 8) & 0xFF) / 255,
                Double(value & 0xFF) / 255)
    }
}

// MARK: - 글씨 크기

/// 카드의 세리프·고정폭 글씨처럼 크기를 정해 둔 글씨도 '더 큰 텍스트'를 따라 커지게.
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default,
                    relativeTo style: Font.TextStyle = .body) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, relativeTo: style))
    }

    /// 화면에 다 들어가면 그대로, 아주 큰 글씨로 넘치면 스크롤되게
    func scrollIfNeeded() -> some View {
        ViewThatFits(in: .vertical) {
            self
            ScrollView { self }
        }
    }
}
