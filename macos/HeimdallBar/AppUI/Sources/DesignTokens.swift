import SwiftUI

extension ShapeStyle where Self == Color {
    static var accentInteractive: Color { Color.accentColor }
    static var warning: Color { Color("AccentWarning", bundle: .main) }
    static var success: Color { Color("AccentSuccess", bundle: .main) }
    static var accentError: Color { Color("AccentError", bundle: .main) }
}

extension Color {
    static func severity(usedPercent: Double) -> Color {
        if usedPercent >= 80 { return .accentError }
        if usedPercent >= 50 { return .warning }
        return .primary
    }

    static func severity(code: String) -> Color {
        switch code.lowercased() {
        case "danger", "critical", "high":
            return .accentError
        case "warn", "warning", "medium", "moderate":
            return .warning
        default:
            return .primary
        }
    }
}
