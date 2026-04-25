import SwiftUI

extension Color {
    static let accentInteractive = Color.accentColor
    static let warning = Color("AccentWarning", bundle: .main)
    static let success = Color("AccentSuccess", bundle: .main)
    static let accentError = Color("AccentError", bundle: .main)

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
