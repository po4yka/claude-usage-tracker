import Foundation

public enum LiveMonitorFocus: String, Codable, CaseIterable, Sendable, Identifiable {
    case all
    case claude
    case codex

    public var id: String { self.rawValue }

    public var title: String {
        switch self {
        case .all: return "All"
        case .claude: return "Claude"
        case .codex: return "Codex"
        }
    }
}

public struct LiveMonitorFreshness: Codable, Sendable {
    public var newestProviderRefresh: String?
    public var oldestProviderRefresh: String?
    public var staleProviders: [String]
    public var hasStaleProviders: Bool
    public var refreshState: String

    public init(
        newestProviderRefresh: String? = nil,
        oldestProviderRefresh: String? = nil,
        staleProviders: [String],
        hasStaleProviders: Bool,
        refreshState: String
    ) {
        self.newestProviderRefresh = newestProviderRefresh
        self.oldestProviderRefresh = oldestProviderRefresh
        self.staleProviders = staleProviders
        self.hasStaleProviders = hasStaleProviders
        self.refreshState = refreshState
    }

    enum CodingKeys: String, CodingKey {
        case newestProviderRefresh = "newest_provider_refresh"
        case oldestProviderRefresh = "oldest_provider_refresh"
        case staleProviders = "stale_providers"
        case hasStaleProviders = "has_stale_providers"
        case refreshState = "refresh_state"
    }
}

public struct LiveMonitorBurnRate: Codable, Sendable {
    public var tokensPerMin: Double
    public var costPerHourNanos: Int
    public var tier: String?

    public init(tokensPerMin: Double, costPerHourNanos: Int, tier: String? = nil) {
        self.tokensPerMin = tokensPerMin
        self.costPerHourNanos = costPerHourNanos
        self.tier = tier
    }

    enum CodingKeys: String, CodingKey {
        case tokensPerMin = "tokens_per_min"
        case costPerHourNanos = "cost_per_hour_nanos"
        case tier
    }
}

public struct LiveMonitorProjection: Codable, Sendable {
    public var projectedCostNanos: Int
    public var projectedTokens: Int

    public init(projectedCostNanos: Int, projectedTokens: Int) {
        self.projectedCostNanos = projectedCostNanos
        self.projectedTokens = projectedTokens
    }

    enum CodingKeys: String, CodingKey {
        case projectedCostNanos = "projected_cost_nanos"
        case projectedTokens = "projected_tokens"
    }
}

public struct LiveMonitorQuota: Codable, Sendable {
    public var limitTokens: Int
    public var usedTokens: Int
    public var projectedTokens: Int
    public var currentPercent: Double
    public var projectedPercent: Double
    public var remainingTokens: Int
    public var currentSeverity: String
    public var projectedSeverity: String

    public init(
        limitTokens: Int,
        usedTokens: Int,
        projectedTokens: Int,
        currentPercent: Double,
        projectedPercent: Double,
        remainingTokens: Int,
        currentSeverity: String,
        projectedSeverity: String
    ) {
        self.limitTokens = limitTokens
        self.usedTokens = usedTokens
        self.projectedTokens = projectedTokens
        self.currentPercent = currentPercent
        self.projectedPercent = projectedPercent
        self.remainingTokens = remainingTokens
        self.currentSeverity = currentSeverity
        self.projectedSeverity = projectedSeverity
    }

    enum CodingKeys: String, CodingKey {
        case limitTokens = "limit_tokens"
        case usedTokens = "used_tokens"
        case projectedTokens = "projected_tokens"
        case currentPercent = "current_pct"
        case projectedPercent = "projected_pct"
        case remainingTokens = "remaining_tokens"
        case currentSeverity = "current_severity"
        case projectedSeverity = "projected_severity"
    }
}

public struct DepletionForecastSignal: Codable, Sendable, Identifiable, Equatable {
    public var kind: String
    public var title: String
    public var usedPercent: Double
    public var projectedPercent: Double?
    public var remainingTokens: Int?
    public var remainingPercent: Double?
    public var resetsInMinutes: Int?
    public var paceLabel: String?
    public var endTime: String?

    public var id: String { "\(self.kind):\(self.title)" }

    public init(
        kind: String,
        title: String,
        usedPercent: Double,
        projectedPercent: Double? = nil,
        remainingTokens: Int? = nil,
        remainingPercent: Double? = nil,
        resetsInMinutes: Int? = nil,
        paceLabel: String? = nil,
        endTime: String? = nil
    ) {
        self.kind = kind
        self.title = title
        self.usedPercent = usedPercent
        self.projectedPercent = projectedPercent
        self.remainingTokens = remainingTokens
        self.remainingPercent = remainingPercent
        self.resetsInMinutes = resetsInMinutes
        self.paceLabel = paceLabel
        self.endTime = endTime
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case title
        case usedPercent = "used_percent"
        case projectedPercent = "projected_percent"
        case remainingTokens = "remaining_tokens"
        case remainingPercent = "remaining_percent"
        case resetsInMinutes = "resets_in_minutes"
        case paceLabel = "pace_label"
        case endTime = "end_time"
    }
}

public struct DepletionForecast: Codable, Sendable, Equatable {
    public var primarySignal: DepletionForecastSignal
    public var secondarySignals: [DepletionForecastSignal]
    public var summaryLabel: String
    public var severity: String
    public var note: String?

    public init(
        primarySignal: DepletionForecastSignal,
        secondarySignals: [DepletionForecastSignal],
        summaryLabel: String,
        severity: String,
        note: String? = nil
    ) {
        self.primarySignal = primarySignal
        self.secondarySignals = secondarySignals
        self.summaryLabel = summaryLabel
        self.severity = severity
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case primarySignal = "primary_signal"
        case secondarySignals = "secondary_signals"
        case summaryLabel = "summary_label"
        case severity
        case note
    }
}

public struct QuotaSuggestionLevel: Codable, Sendable, Identifiable, Equatable {
    public var key: String
    public var label: String
    public var limitTokens: Int

    public var id: String { self.key }

    public init(key: String, label: String, limitTokens: Int) {
        self.key = key
        self.label = label
        self.limitTokens = limitTokens
    }

    enum CodingKeys: String, CodingKey {
        case key
        case label
        case limitTokens = "limit_tokens"
    }
}

public struct QuotaSuggestions: Codable, Sendable, Equatable {
    public var sampleCount: Int
    public var populationCount: Int?
    public var sampleStrategy: String?
    public var sampleLabel: String?
    public var recommendedKey: String
    public var levels: [QuotaSuggestionLevel]
    public var note: String?

    public init(
        sampleCount: Int,
        recommendedKey: String,
        levels: [QuotaSuggestionLevel],
        note: String? = nil,
        populationCount: Int? = nil,
        sampleStrategy: String? = nil,
        sampleLabel: String? = nil
    ) {
        self.sampleCount = sampleCount
        self.populationCount = populationCount
        self.sampleStrategy = sampleStrategy
        self.sampleLabel = sampleLabel
        self.recommendedKey = recommendedKey
        self.levels = levels
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case sampleCount = "sample_count"
        case populationCount = "population_count"
        case sampleStrategy = "sample_strategy"
        case sampleLabel = "sample_label"
        case recommendedKey = "recommended_key"
        case levels
        case note
    }
}

public struct LiveMonitorBlock: Codable, Sendable {
    public var start: String
    public var end: String
    public var firstTimestamp: String
    public var lastTimestamp: String
    public var tokens: TokenBreakdown
    public var costNanos: Int
    public var entryCount: Int
    public var burnRate: LiveMonitorBurnRate?
    public var projection: LiveMonitorProjection?
    public var quota: LiveMonitorQuota?

    public init(
        start: String,
        end: String,
        firstTimestamp: String,
        lastTimestamp: String,
        tokens: TokenBreakdown,
        costNanos: Int,
        entryCount: Int,
        burnRate: LiveMonitorBurnRate? = nil,
        projection: LiveMonitorProjection? = nil,
        quota: LiveMonitorQuota? = nil
    ) {
        self.start = start
        self.end = end
        self.firstTimestamp = firstTimestamp
        self.lastTimestamp = lastTimestamp
        self.tokens = tokens
        self.costNanos = costNanos
        self.entryCount = entryCount
        self.burnRate = burnRate
        self.projection = projection
        self.quota = quota
    }

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case firstTimestamp = "first_timestamp"
        case lastTimestamp = "last_timestamp"
        case tokens
        case costNanos = "cost_nanos"
        case entryCount = "entry_count"
        case burnRate = "burn_rate"
        case projection
        case quota
    }
}

public struct LiveMonitorContextWindow: Codable, Sendable {
    public var totalInputTokens: Int
    public var contextWindowSize: Int
    public var pct: Double
    public var severity: String
    public var sessionID: String?
    public var capturedAt: String?

    public init(
        totalInputTokens: Int,
        contextWindowSize: Int,
        pct: Double,
        severity: String,
        sessionID: String? = nil,
        capturedAt: String? = nil
    ) {
        self.totalInputTokens = totalInputTokens
        self.contextWindowSize = contextWindowSize
        self.pct = pct
        self.severity = severity
        self.sessionID = sessionID
        self.capturedAt = capturedAt
    }

    enum CodingKeys: String, CodingKey {
        case totalInputTokens = "total_input_tokens"
        case contextWindowSize = "context_window_size"
        case pct
        case severity
        case sessionID = "session_id"
        case capturedAt = "captured_at"
    }
}

public struct LiveMonitorProvider: Codable, Sendable, Identifiable {
    public var provider: String
    public var title: String
    public var visualState: String
    public var sourceLabel: String
    public var warnings: [String]
    public var identityLabel: String?
    public var primary: ProviderRateWindow?
    public var secondary: ProviderRateWindow?
    public var todayCostUSD: Double
    public var projectedWeeklySpendUSD: Double?
    public var lastRefresh: String
    public var lastRefreshLabel: String
    public var activeBlock: LiveMonitorBlock?
    public var contextWindow: LiveMonitorContextWindow?
    public var recentSession: ProviderSession?
    public var quotaSuggestions: QuotaSuggestions?
    public var depletionForecast: DepletionForecast?
    public var predictiveInsights: LivePredictiveInsights?

    public var id: String { self.provider }
    public var providerID: ProviderID? { ProviderID(rawValue: self.provider) }

    public init(
        provider: String,
        title: String,
        visualState: String,
        sourceLabel: String,
        warnings: [String],
        identityLabel: String? = nil,
        primary: ProviderRateWindow? = nil,
        secondary: ProviderRateWindow? = nil,
        todayCostUSD: Double,
        projectedWeeklySpendUSD: Double? = nil,
        lastRefresh: String,
        lastRefreshLabel: String,
        activeBlock: LiveMonitorBlock? = nil,
        contextWindow: LiveMonitorContextWindow? = nil,
        recentSession: ProviderSession? = nil,
        quotaSuggestions: QuotaSuggestions? = nil,
        depletionForecast: DepletionForecast? = nil,
        predictiveInsights: LivePredictiveInsights? = nil
    ) {
        self.provider = provider
        self.title = title
        self.visualState = visualState
        self.sourceLabel = sourceLabel
        self.warnings = warnings
        self.identityLabel = identityLabel
        self.primary = primary
        self.secondary = secondary
        self.todayCostUSD = todayCostUSD
        self.projectedWeeklySpendUSD = projectedWeeklySpendUSD
        self.lastRefresh = lastRefresh
        self.lastRefreshLabel = lastRefreshLabel
        self.activeBlock = activeBlock
        self.contextWindow = contextWindow
        self.recentSession = recentSession
        self.quotaSuggestions = quotaSuggestions
        self.depletionForecast = depletionForecast
        self.predictiveInsights = predictiveInsights
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case title
        case visualState = "visual_state"
        case sourceLabel = "source_label"
        case warnings
        case identityLabel = "identity_label"
        case primary
        case secondary
        case todayCostUSD = "today_cost_usd"
        case projectedWeeklySpendUSD = "projected_weekly_spend_usd"
        case lastRefresh = "last_refresh"
        case lastRefreshLabel = "last_refresh_label"
        case activeBlock = "active_block"
        case contextWindow = "context_window"
        case recentSession = "recent_session"
        case quotaSuggestions = "quota_suggestions"
        case depletionForecast = "depletion_forecast"
        case predictiveInsights = "predictive_insights"
    }
}

public struct LiveMonitorEnvelope: Codable, Sendable {
    public var contractVersion: Int
    public var generatedAt: String
    public var defaultFocus: LiveMonitorFocus
    public var globalIssue: String?
    public var freshness: LiveMonitorFreshness
    public var providers: [LiveMonitorProvider]

    public init(
        contractVersion: Int = LiveMonitorContract.version,
        generatedAt: String,
        defaultFocus: LiveMonitorFocus,
        globalIssue: String? = nil,
        freshness: LiveMonitorFreshness,
        providers: [LiveMonitorProvider]
    ) {
        self.contractVersion = contractVersion
        self.generatedAt = generatedAt
        self.defaultFocus = defaultFocus
        self.globalIssue = globalIssue
        self.freshness = freshness
        self.providers = providers
    }

    enum CodingKeys: String, CodingKey {
        case contractVersion = "contract_version"
        case generatedAt = "generated_at"
        case defaultFocus = "default_focus"
        case globalIssue = "global_issue"
        case freshness
        case providers
    }
}

public struct CostSummaryEnvelope: Codable, Sendable {
    public var provider: String
    public var summary: ProviderCostSummary

    public init(provider: String, summary: ProviderCostSummary) {
        self.provider = provider
        self.summary = summary
    }
}
