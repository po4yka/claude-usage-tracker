import Foundation
import HeimdallDomain
import Observation

public final class UserDefaultsAppSessionStateStore: @unchecked Sendable, AppSessionStatePersisting {
    private enum Keys {
        static let selectedProvider = "heimdallbar.app_session.selected_provider"
        static let selectedMergeTab = "heimdallbar.app_session.selected_merge_tab"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadAppSessionState() -> PersistedAppSessionState? {
        guard let providerRaw = self.defaults.string(forKey: Keys.selectedProvider),
              let mergeTabRaw = self.defaults.string(forKey: Keys.selectedMergeTab),
              let provider = ProviderID(rawValue: providerRaw),
              let mergeTab = MergeMenuTab(rawValue: mergeTabRaw) else {
            return nil
        }
        return PersistedAppSessionState(
            selectedProvider: provider,
            selectedMergeTab: mergeTab
        )
    }

    public func saveAppSessionState(_ state: PersistedAppSessionState) {
        self.defaults.set(state.selectedProvider.rawValue, forKey: Keys.selectedProvider)
        self.defaults.set(state.selectedMergeTab.rawValue, forKey: Keys.selectedMergeTab)
    }
}

@MainActor
@Observable
public final class AppSessionStore {
    public var config: HeimdallBarConfig
    public var selectedProvider: ProviderID {
        didSet {
            self.persistSelections()
        }
    }
    public var selectedMergeTab: MergeMenuTab {
        didSet {
            self.persistSelections()
        }
    }

    private let persistence: any AppSessionStatePersisting

    public init(
        config: HeimdallBarConfig = .default,
        selectedProvider: ProviderID = .claude,
        selectedMergeTab: MergeMenuTab = .overview,
        persistence: any AppSessionStatePersisting = UserDefaultsAppSessionStateStore()
    ) {
        self.config = config
        self.persistence = persistence
        let persistedState = persistence.loadAppSessionState()
        self.selectedProvider = persistedState?.selectedProvider ?? selectedProvider
        self.selectedMergeTab = persistedState?.selectedMergeTab ?? selectedMergeTab
    }

    public var visibleProviders: [ProviderID] {
        ProviderID.allCases.filter { self.config.providerConfig(for: $0).enabled }
    }

    public var visibleTabs: [MergeMenuTab] {
        MenuProjectionBuilder.availableTabs(config: self.config)
    }

    private func persistSelections() {
        self.persistence.saveAppSessionState(
            PersistedAppSessionState(
                selectedProvider: self.selectedProvider,
                selectedMergeTab: self.selectedMergeTab
            )
        )
    }
}
