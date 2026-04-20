import AppKit
import HeimdallBarShared
import SwiftUI

struct RootMenuView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Provider", selection: self.$model.selectedProvider) {
                ForEach(self.model.visibleProviders) { provider in
                    Text(provider.title).tag(provider)
                }
            }
            .pickerStyle(.segmented)

            ProviderMenuCard(snapshot: self.model.snapshot(for: self.model.selectedProvider))

            Divider()

            Button("Refresh Now") {
                Task { await self.model.refresh(force: true) }
            }
            Button("Open Dashboard") {
                if let url = URL(string: "http://127.0.0.1:\(self.model.config.helperPort)") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Quit HeimdallBar") {
                NSApplication.shared.terminate(nil)
            }

            if let lastError = self.model.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 360)
    }
}

struct ProviderMenuView: View {
    @Bindable var model: AppModel
    let provider: ProviderID

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProviderMenuCard(snapshot: self.model.snapshot(for: self.provider))

            Divider()

            Button("Refresh \(self.provider.title)") {
                Task { await self.model.refresh(force: true) }
            }
            Button("Open Dashboard") {
                if let url = URL(string: "http://127.0.0.1:\(self.model.config.helperPort)") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Quit HeimdallBar") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 340)
    }
}

struct ProviderMenuCard: View {
    let snapshot: ProviderSnapshot?

    var body: some View {
        if let snapshot {
            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.provider.capitalized)
                    .font(.headline)
                UsageLane(title: "Session", window: snapshot.primary)
                UsageLane(title: "Weekly", window: snapshot.secondary)
                if let tertiary = snapshot.tertiary {
                    UsageLane(title: "Extra", window: tertiary)
                }
                if let credits = snapshot.credits {
                    Text("Credits: \(credits, specifier: "%.2f")")
                        .font(.caption)
                }
                Text("Today: $\(snapshot.costSummary.todayCostUSD, specifier: "%.2f") · \(snapshot.costSummary.todayTokens) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let status = snapshot.status {
                    Text("[\(status.indicator.uppercased())] \(status.description)")
                        .font(.caption)
                        .foregroundStyle(status.indicator == "major" || status.indicator == "critical" ? .red : .secondary)
                }
                if let error = snapshot.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text("No provider snapshot available yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct UsageLane: View {
    let title: String
    let window: ProviderRateWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let window {
                ProgressView(value: window.usedPercent, total: 100)
                HStack {
                    Text("\(Int((100 - window.usedPercent).rounded()))% left")
                    Spacer()
                    Text(window.resetLabel ?? window.resetsAt ?? "—")
                }
                .font(.caption2)
            } else {
                Text("Unavailable")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
