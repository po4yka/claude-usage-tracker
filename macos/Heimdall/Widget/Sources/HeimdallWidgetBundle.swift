import HeimdallWidgets
import SwiftUI
import WidgetKit

@main
struct HeimdallWidgetBundle: WidgetBundle {
    var body: some Widget {
        HeimdallUsageWidget()
        HeimdallHistoryWidget()
        HeimdallCompactWidget()
        HeimdallSwitcherWidget()
    }
}

struct HeimdallUsageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "HeimdallUsageWidget",
            intent: ProviderSelectionIntent.self,
            provider: SingleProviderTimelineProvider()
        ) { entry in
            UsageWidgetView(entry: entry)
        }
        .configurationDisplayName("Heimdall Usage")
        .description("Live quota, auth state, and credits for one provider.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HeimdallHistoryWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "HeimdallHistoryWidget",
            intent: ProviderSelectionIntent.self,
            provider: SingleProviderTimelineProvider()
        ) { entry in
            HistoryWidgetView(entry: entry)
        }
        .configurationDisplayName("Heimdall History")
        .description("Recent cost and activity for one provider.")
        .supportedFamilies([.systemMedium])
    }
}

struct HeimdallCompactWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "HeimdallCompactWidget",
            intent: ProviderSelectionIntent.self,
            provider: SingleProviderTimelineProvider()
        ) { entry in
            CompactWidgetView(entry: entry)
        }
        .configurationDisplayName("Heimdall Compact")
        .description("A compact auth and quota summary for one provider.")
        .supportedFamilies([.systemSmall])
    }
}

struct HeimdallSwitcherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HeimdallSwitcherWidget", provider: SwitcherTimelineProvider()) { entry in
            SwitcherWidgetView(entry: entry)
        }
        .configurationDisplayName("Heimdall Switcher")
        .description("A dual-provider status surface sorted by severity.")
        .supportedFamilies([.systemMedium])
    }
}
