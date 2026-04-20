import AppIntents
import HeimdallBarShared
import SwiftUI
import WidgetKit

enum WidgetProviderIntent: String, CaseIterable, AppEnum {
    case claude
    case codex

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Provider")
    static let caseDisplayRepresentations: [WidgetProviderIntent: DisplayRepresentation] = [
        .claude: DisplayRepresentation(title: "Claude"),
        .codex: DisplayRepresentation(title: "Codex"),
    ]

    var providerID: ProviderID {
        switch self {
        case .claude:
            return .claude
        case .codex:
            return .codex
        }
    }
}

struct ProviderSelectionIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Provider"
    static let description = IntentDescription("Choose the provider shown in the widget.")

    @Parameter(title: "Provider", default: .claude)
    var provider: WidgetProviderIntent
}

struct HeimdallBarWidgetEntry: TimelineEntry {
    let date: Date
    let provider: ProviderID
    let snapshot: WidgetSnapshot
}

struct HeimdallBarTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HeimdallBarWidgetEntry {
        HeimdallBarWidgetEntry(date: Date(), provider: .claude, snapshot: WidgetSnapshot(generatedAt: ISO8601DateFormatter().string(from: Date()), entries: []))
    }

    func snapshot(for configuration: ProviderSelectionIntent, in context: Context) async -> HeimdallBarWidgetEntry {
        HeimdallBarWidgetEntry(date: Date(), provider: configuration.provider.providerID, snapshot: WidgetSnapshotStore.load() ?? WidgetSnapshot(generatedAt: ISO8601DateFormatter().string(from: Date()), entries: []))
    }

    func timeline(for configuration: ProviderSelectionIntent, in context: Context) async -> Timeline<HeimdallBarWidgetEntry> {
        let snapshot = WidgetSnapshotStore.load() ?? WidgetSnapshot(generatedAt: ISO8601DateFormatter().string(from: Date()), entries: [])
        let entry = HeimdallBarWidgetEntry(date: Date(), provider: configuration.provider.providerID, snapshot: snapshot)
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
    }
}

struct UsageWidgetView: View {
    let entry: HeimdallBarWidgetEntry

    var body: some View {
        if let provider = self.entry.snapshot.entries.first(where: { $0.provider == self.entry.provider }) {
            VStack(alignment: .leading) {
                Text(provider.title)
                    .font(.headline)
                if let primary = provider.primary {
                    Text("Session \(Int((100 - primary.usedPercent).rounded()))% left")
                }
                if let secondary = provider.secondary {
                    Text("Weekly \(Int((100 - secondary.usedPercent).rounded()))% left")
                }
                Text("$\(provider.costSummary.todayCostUSD, specifier: "%.2f") today")
                    .font(.caption)
            }
            .padding()
        } else {
            Text("No snapshot")
                .padding()
        }
    }
}

struct HistoryWidgetView: View {
    let entry: HeimdallBarWidgetEntry

    var body: some View {
        if let provider = self.entry.snapshot.entries.first(where: { $0.provider == self.entry.provider }) {
            VStack(alignment: .leading) {
                Text(provider.title)
                    .font(.headline)
                Text("30d tokens: \(provider.costSummary.last30DaysTokens)")
                Text("30d cost: $\(provider.costSummary.last30DaysCostUSD, specifier: "%.2f")")
                    .font(.caption)
            }
            .padding()
        } else {
            Text("No history")
                .padding()
        }
    }
}

struct CompactWidgetView: View {
    let entry: HeimdallBarWidgetEntry

    var body: some View {
        if let provider = self.entry.snapshot.entries.first(where: { $0.provider == self.entry.provider }) {
            VStack(alignment: .leading) {
                Text(provider.title)
                if let primary = provider.primary {
                    Text("\(Int((100 - primary.usedPercent).rounded()))%")
                        .font(.title3)
                }
            }
            .padding()
        } else {
            Text("—")
        }
    }
}

@main
struct HeimdallBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        HeimdallBarUsageWidget()
        HeimdallBarHistoryWidget()
        HeimdallBarCompactWidget()
        HeimdallBarSwitcherWidget()
    }
}

struct HeimdallBarUsageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HeimdallBarUsageWidget", intent: ProviderSelectionIntent.self, provider: HeimdallBarTimelineProvider()) { entry in
            UsageWidgetView(entry: entry)
        }
        .configurationDisplayName("HeimdallBar Usage")
        .description("Live session and weekly usage for Claude or Codex.")
    }
}

struct HeimdallBarHistoryWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HeimdallBarHistoryWidget", intent: ProviderSelectionIntent.self, provider: HeimdallBarTimelineProvider()) { entry in
            HistoryWidgetView(entry: entry)
        }
        .configurationDisplayName("HeimdallBar History")
        .description("Today and 30-day cost history.")
    }
}

struct HeimdallBarCompactWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HeimdallBarCompactWidget", intent: ProviderSelectionIntent.self, provider: HeimdallBarTimelineProvider()) { entry in
            CompactWidgetView(entry: entry)
        }
        .configurationDisplayName("HeimdallBar Compact")
        .description("Compact provider usage display.")
    }
}

struct HeimdallBarSwitcherWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HeimdallBarSwitcherWidget", intent: ProviderSelectionIntent.self, provider: HeimdallBarTimelineProvider()) { entry in
            UsageWidgetView(entry: entry)
        }
        .configurationDisplayName("HeimdallBar Switcher")
        .description("Switch between Claude and Codex.")
    }
}
