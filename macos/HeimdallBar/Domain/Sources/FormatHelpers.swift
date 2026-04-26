import Foundation

public enum FormatHelpers {
    /// Shared formatter instance. `NumberFormatter` is thread-safe for formatting
    /// operations when accessed read-only after configuration.
    public static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_US")
        f.currencyCode = "USD"
        f.currencySymbol = "$"
        f.positiveFormat = "¤#,##0.00"
        f.negativeFormat = "-¤#,##0.00"
        return f
    }()

    /// Format a USD dollar amount.
    ///
    /// Precision rule: values >= $1 use 2 decimal places; values < $1 use 4
    /// decimal places to preserve meaningful sub-cent precision.
    ///
    /// Examples: 1.5 → "$1.50", 0.0034 → "$0.0034"
    public static func formatUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(value >= 1 ? 2 : 4)))
    }
}
