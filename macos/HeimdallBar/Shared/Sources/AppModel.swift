import Foundation
import Observation

@MainActor
@Observable
public final class AppModel {
    public var config: HeimdallBarConfig
    public var snapshots: [ProviderSnapshot]
    public var selectedProvider: ProviderID
    public var lastError: String?
    public var isRefreshing: Bool

    private let configStore: ConfigStore
    private let helperController: HeimdallHelperController
    private var hasStarted: Bool

    public init(
        configStore: ConfigStore = .shared,
        helperController: HeimdallHelperController = HeimdallHelperController()
    ) {
        self.configStore = configStore
        self.helperController = helperController
        self.config = configStore.load()
        self.snapshots = []
        self.selectedProvider = .claude
        self.lastError = nil
        self.isRefreshing = false
        self.hasStarted = false
    }

    public var visibleProviders: [ProviderID] {
        ProviderID.allCases.filter { self.config.providerConfig(for: $0).enabled }
    }

    public func start() {
        guard !self.hasStarted else { return }
        self.hasStarted = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.refresh(force: false)
            self.startRefreshLoop()
        }
    }

    public func refresh(force: Bool) async {
        self.isRefreshing = true
        defer { self.isRefreshing = false }
        await self.helperController.ensureServerRunning(port: self.config.helperPort)
        let client = HeimdallAPIClient(port: self.config.helperPort)
        do {
            let envelope = force ? try await client.refresh(provider: nil) : try await client.fetchSnapshots()
            self.snapshots = envelope.providers
            self.lastError = nil
            try? WidgetSnapshotStore.save(self.makeWidgetSnapshot())
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    public func saveConfig() {
        do {
            try self.configStore.save(self.config)
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    public func snapshot(for provider: ProviderID) -> ProviderSnapshot? {
        self.snapshots.first(where: { $0.providerID == provider })
    }

    public func menuTitle(for provider: ProviderID?) -> String {
        let snapshot = provider.flatMap(self.snapshot(for:)) ?? self.visibleProviders.compactMap(self.snapshot(for:)).first
        guard let snapshot, let primary = snapshot.primary else {
            return provider?.title ?? "Heimdall"
        }
        let value = self.config.showUsedValues ? primary.usedPercent : max(0, 100 - primary.usedPercent)
        let suffix = self.config.showUsedValues ? "used" : "left"
        return "\(snapshot.provider.capitalized) \(Int(value.rounded()))% \(suffix)"
    }

    public func makeWidgetSnapshot() -> WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            entries: self.visibleProviders.compactMap { provider in
                guard let snapshot = self.snapshot(for: provider) else { return nil }
                return WidgetProviderEntry(
                    provider: provider,
                    title: provider.title,
                    primary: snapshot.primary,
                    secondary: snapshot.secondary,
                    credits: snapshot.credits,
                    costSummary: snapshot.costSummary,
                    updatedAt: snapshot.lastRefresh
                )
            }
        )
    }

    private func startRefreshLoop() {
        Task { @MainActor [weak self] in
            while let self {
                let refreshIntervalSeconds = self.config.refreshIntervalSeconds
                try? await Task.sleep(for: .seconds(refreshIntervalSeconds))
                await self.refresh(force: false)
            }
        }
    }
}
