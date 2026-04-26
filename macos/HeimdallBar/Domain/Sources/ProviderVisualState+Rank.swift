public extension ProviderVisualState {
    /// Integer severity rank used for sorting providers: higher is more urgent.
    var severityRank: Int {
        switch self {
        case .error: return 5
        case .incident: return 4
        case .degraded: return 3
        case .stale: return 2
        case .refreshing: return 1
        case .healthy: return 0
        }
    }
}
