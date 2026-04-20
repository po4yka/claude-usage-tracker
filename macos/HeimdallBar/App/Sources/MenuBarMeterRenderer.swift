import AppKit
import HeimdallBarShared

enum MenuBarMeterRenderer {
    static func image(primary: ProviderRateWindow?, secondary: ProviderRateWindow?, stale: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let primaryRemaining = CGFloat(max(0.0, min(1.0, 1.0 - CGFloat((primary?.usedPercent ?? 100) / 100.0))))
        let secondaryRemaining = CGFloat(max(0.0, min(1.0, 1.0 - CGFloat((secondary?.usedPercent ?? 100) / 100.0))))
        let alpha: CGFloat = stale ? 0.35 : 1.0
        NSColor.labelColor.withAlphaComponent(0.18 * alpha).setFill()
        NSBezierPath(roundedRect: NSRect(x: 2, y: 4, width: 14, height: 8), xRadius: 2, yRadius: 2).fill()
        NSBezierPath(roundedRect: NSRect(x: 2, y: 14, width: 14, height: 2), xRadius: 1, yRadius: 1).fill()

        NSColor.labelColor.withAlphaComponent(alpha).setFill()
        NSBezierPath(roundedRect: NSRect(x: 2, y: 4, width: max(2, 14 * primaryRemaining), height: 8), xRadius: 2, yRadius: 2).fill()
        NSBezierPath(roundedRect: NSRect(x: 2, y: 14, width: max(1, 14 * secondaryRemaining), height: 2), xRadius: 1, yRadius: 1).fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
