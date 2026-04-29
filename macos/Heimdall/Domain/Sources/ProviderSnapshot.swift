import Foundation

// MARK: - Wire support types (rate window, identity, status)

public struct ProviderRateWindow: Codable, Sendable {
    public var usedPercent: Double
    public var resetsAt: String?
    public var resetsInMinutes: Int?
    public var windowMinutes: Int?
    public var resetLabel: String?

    public init(
        usedPercent: Double,
        resetsAt: String?,
        resetsInMinutes: Int?,
        windowMinutes: Int?,
        resetLabel: String?
    ) {
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
        self.resetsInMinutes = resetsInMinutes
        self.windowMinutes = windowMinutes
        self.resetLabel = resetLabel
    }

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case resetsAt = "resets_at"
        case resetsInMinutes = "resets_in_minutes"
        case windowMinutes = "window_minutes"
        case resetLabel = "reset_label"
    }
}

public struct ProviderIdentity: Codable, Sendable {
    public var provider: String
    public var accountEmail: String?
    public var accountOrganization: String?
    public var loginMethod: String?
    public var plan: String?

    public init(
        provider: String,
        accountEmail: String?,
        accountOrganization: String?,
        loginMethod: String?,
        plan: String?
    ) {
        self.provider = provider
        self.accountEmail = accountEmail
        self.accountOrganization = accountOrganization
        self.loginMethod = loginMethod
        self.plan = plan
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case accountEmail = "account_email"
        case accountOrganization = "account_organization"
        case loginMethod = "login_method"
        case plan
    }
}

public struct ProviderStatusSummary: Codable, Sendable {
    public var indicator: String
    public var description: String
    public var pageURL: String

    public init(indicator: String, description: String, pageURL: String) {
        self.indicator = indicator
        self.description = description
        self.pageURL = pageURL
    }

    enum CodingKeys: String, CodingKey {
        case indicator
        case description
        case pageURL = "page_url"
    }
}

public struct ClaudeAdminSummaryPayload: Codable, Sendable {
    public var organizationName: String
    public var lookbackDays: Int
    public var startDate: String
    public var endDate: String
    public var dataLatencyNote: String
    public var todayActiveUsers: Int
    public var todaySessions: Int
    public var lookbackLinesAccepted: Int
    public var lookbackEstimatedCostUSD: Double
    public var lookbackInputTokens: Int
    public var lookbackOutputTokens: Int
    public var lookbackCacheReadTokens: Int
    public var lookbackCacheCreationTokens: Int
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case organizationName = "organization_name"
        case lookbackDays = "lookback_days"
        case startDate = "start_date"
        case endDate = "end_date"
        case dataLatencyNote = "data_latency_note"
        case todayActiveUsers = "today_active_users"
        case todaySessions = "today_sessions"
        case lookbackLinesAccepted = "lookback_lines_accepted"
        case lookbackEstimatedCostUSD = "lookback_estimated_cost_usd"
        case lookbackInputTokens = "lookback_input_tokens"
        case lookbackOutputTokens = "lookback_output_tokens"
        case lookbackCacheReadTokens = "lookback_cache_read_tokens"
        case lookbackCacheCreationTokens = "lookback_cache_creation_tokens"
        case error
    }
}

/// Per-category breakdown of token usage. Optional on the wire so that
/// Mac app builds keep decoding against older helpers that don't emit it.
public struct TokenBreakdown: Codable, Sendable, Hashable {
    public var input: Int
    public var output: Int
    public var cacheRead: Int
    public var cacheCreation: Int
    public var reasoningOutput: Int

    public init(
        input: Int = 0,
        output: Int = 0,
        cacheRead: Int = 0,
        cacheCreation: Int = 0,
        reasoningOutput: Int = 0
    ) {
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreation = cacheCreation
        self.reasoningOutput = reasoningOutput
    }

    public var total: Int {
        self.input + self.output + self.cacheRead + self.cacheCreation + self.reasoningOutput
    }

    public var isEmpty: Bool { self.total == 0 }

    enum CodingKeys: String, CodingKey {
        case input
        case output
        case cacheRead = "cache_read"
        case cacheCreation = "cache_creation"
        case reasoningOutput = "reasoning_output"
    }
}

public extension TokenBreakdown {
    func merging(_ other: TokenBreakdown) -> TokenBreakdown {
        TokenBreakdown(
            input: self.input + other.input,
            output: self.output + other.output,
            cacheRead: self.cacheRead + other.cacheRead,
            cacheCreation: self.cacheCreation + other.cacheCreation,
            reasoningOutput: self.reasoningOutput + other.reasoningOutput
        )
    }

    static func sum(_ values: [TokenBreakdown]) -> TokenBreakdown? {
        guard let first = values.first else { return nil }
        return values.dropFirst().reduce(first) { $0.merging($1) }
    }
}

// MARK: - Per-provider data rows

public struct CostHistoryPoint: Codable, Sendable, Identifiable {
    public var day: String
    public var totalTokens: Int
    public var costUSD: Double
    public var breakdown: TokenBreakdown?

    public var id: String { self.day }

    public init(
        day: String,
        totalTokens: Int,
        costUSD: Double,
        breakdown: TokenBreakdown? = nil
    ) {
        self.day = day
        self.totalTokens = totalTokens
        self.costUSD = costUSD
        self.breakdown = breakdown
    }

    enum CodingKeys: String, CodingKey {
        case day
        case totalTokens = "total_tokens"
        case costUSD = "cost_usd"
        case breakdown
    }
}

public struct ProviderModelRow: Codable, Sendable, Hashable, Identifiable {
    public let model: String
    public let costUSD: Double
    public let input: Int
    public let output: Int
    public let cacheRead: Int
    public let cacheCreation: Int
    public let reasoningOutput: Int
    public let turns: Int

    public var id: String { self.model }

    public init(
        model: String,
        costUSD: Double,
        input: Int,
        output: Int,
        cacheRead: Int,
        cacheCreation: Int,
        reasoningOutput: Int,
        turns: Int
    ) {
        self.model = model
        self.costUSD = costUSD
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreation = cacheCreation
        self.reasoningOutput = reasoningOutput
        self.turns = turns
    }

    enum CodingKeys: String, CodingKey {
        case model
        case costUSD = "cost_usd"
        case input
        case output
        case cacheRead = "cache_read"
        case cacheCreation = "cache_creation"
        case reasoningOutput = "reasoning_output"
        case turns
    }
}

/// Slice of the Rust `DashboardData` payload (`/api/data`) that the macOS
/// client cares about. Includes only the fields the menubar can usefully
/// render today; expand as new dashboard surfaces gain consumers.
public struct DashboardSnapshot: Codable, Sendable {
    public var generatedAt: String
    public var dailyByModel: [DashboardDailyModelRow]

    public init(
        generatedAt: String = "",
        dailyByModel: [DashboardDailyModelRow] = []
    ) {
        self.generatedAt = generatedAt
        self.dailyByModel = dailyByModel
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt) ?? ""
        self.dailyByModel = try container.decodeIfPresent([DashboardDailyModelRow].self, forKey: .dailyByModel) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case dailyByModel = "daily_by_model"
    }
}

/// All-providers per-day per-model bucket as served by `/api/data`.
/// Differs from `ProviderDailyModelRow` in carrying an explicit `provider`
/// field and the rate-limited `credits` value used by Amp.
public struct DashboardDailyModelRow: Codable, Sendable, Hashable, Identifiable {
    public let day: String
    public let provider: String
    public let model: String
    public let input: Int
    public let output: Int
    public let cacheRead: Int
    public let cacheCreation: Int
    public let reasoningOutput: Int
    public let turns: Int
    public let costUSD: Double

    public var id: String { "\(self.day)|\(self.provider)|\(self.model)" }

    public var totalTokens: Int {
        self.input + self.output + self.cacheRead + self.cacheCreation + self.reasoningOutput
    }

    public init(
        day: String,
        provider: String,
        model: String,
        input: Int,
        output: Int,
        cacheRead: Int,
        cacheCreation: Int,
        reasoningOutput: Int,
        turns: Int,
        costUSD: Double
    ) {
        self.day = day
        self.provider = provider
        self.model = model
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreation = cacheCreation
        self.reasoningOutput = reasoningOutput
        self.turns = turns
        self.costUSD = costUSD
    }

    enum CodingKeys: String, CodingKey {
        case day
        case provider
        case model
        case input
        case output
        case cacheRead = "cache_read"
        case cacheCreation = "cache_creation"
        case reasoningOutput = "reasoning_output"
        case turns
        case costUSD = "cost"
    }
}

/// Per-day per-model bucket within a provider's 30-day window. Mirrors Rust
/// `ProviderDailyModelRow` (`src/models.rs`).
public struct ProviderDailyModelRow: Codable, Sendable, Hashable, Identifiable {
    public let day: String
    public let model: String
    public let costUSD: Double
    public let input: Int
    public let output: Int
    public let cacheRead: Int
    public let cacheCreation: Int
    public let reasoningOutput: Int
    public let turns: Int

    public var id: String { "\(self.day)|\(self.model)" }

    public var totalTokens: Int {
        self.input + self.output + self.cacheRead + self.cacheCreation + self.reasoningOutput
    }

    public init(
        day: String,
        model: String,
        costUSD: Double,
        input: Int,
        output: Int,
        cacheRead: Int,
        cacheCreation: Int,
        reasoningOutput: Int,
        turns: Int
    ) {
        self.day = day
        self.model = model
        self.costUSD = costUSD
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreation = cacheCreation
        self.reasoningOutput = reasoningOutput
        self.turns = turns
    }

    enum CodingKeys: String, CodingKey {
        case day
        case model
        case costUSD = "cost_usd"
        case input
        case output
        case cacheRead = "cache_read"
        case cacheCreation = "cache_creation"
        case reasoningOutput = "reasoning_output"
        case turns
    }
}

public struct ProviderProjectRow: Codable, Sendable, Hashable, Identifiable {
    public let project: String
    public let displayName: String
    public let costUSD: Double
    public let turns: Int
    public let sessions: Int

    public var id: String { self.project }

    public init(
        project: String,
        displayName: String,
        costUSD: Double,
        turns: Int,
        sessions: Int
    ) {
        self.project = project
        self.displayName = displayName
        self.costUSD = costUSD
        self.turns = turns
        self.sessions = sessions
    }

    enum CodingKeys: String, CodingKey {
        case project
        case displayName = "display_name"
        case costUSD = "cost_usd"
        case turns
        case sessions
    }
}

public struct ProviderToolRow: Codable, Sendable, Hashable, Identifiable {
    public let toolName: String
    public let category: String?
    public let mcpServer: String?
    public let invocations: Int
    public let errors: Int
    public let turnsUsed: Int
    public let sessionsUsed: Int

    public var id: String { "\(self.mcpServer ?? "_")/\(self.toolName)" }

    public init(
        toolName: String,
        category: String?,
        mcpServer: String?,
        invocations: Int,
        errors: Int,
        turnsUsed: Int,
        sessionsUsed: Int
    ) {
        self.toolName = toolName
        self.category = category
        self.mcpServer = mcpServer
        self.invocations = invocations
        self.errors = errors
        self.turnsUsed = turnsUsed
        self.sessionsUsed = sessionsUsed
    }

    enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case category
        case mcpServer = "mcp_server"
        case invocations
        case errors
        case turnsUsed = "turns_used"
        case sessionsUsed = "sessions_used"
    }
}

public struct ProviderMcpRow: Codable, Sendable, Hashable, Identifiable {
    public let server: String
    public let invocations: Int
    public let toolsUsed: Int
    public let sessionsUsed: Int

    public var id: String { self.server }

    public init(
        server: String,
        invocations: Int,
        toolsUsed: Int,
        sessionsUsed: Int
    ) {
        self.server = server
        self.invocations = invocations
        self.toolsUsed = toolsUsed
        self.sessionsUsed = sessionsUsed
    }

    enum CodingKeys: String, CodingKey {
        case server
        case invocations
        case toolsUsed = "tools_used"
        case sessionsUsed = "sessions_used"
    }
}

public struct ProviderHourlyBucket: Codable, Sendable, Hashable, Identifiable {
    public let hour: Int
    public let turns: Int
    public let costUSD: Double
    public let tokens: Int
    public var id: Int { self.hour }

    public init(hour: Int, turns: Int, costUSD: Double, tokens: Int) {
        self.hour = hour; self.turns = turns; self.costUSD = costUSD; self.tokens = tokens
    }

    enum CodingKeys: String, CodingKey {
        case hour, turns, tokens
        case costUSD = "cost_usd"
    }
}

public struct ProviderHeatmapCell: Codable, Sendable, Hashable, Identifiable {
    public let dayOfWeek: Int  // 0..6, 0 = Sunday
    public let hour: Int       // 0..23
    public let turns: Int
    public var id: String { "\(self.dayOfWeek)-\(self.hour)" }

    public init(dayOfWeek: Int, hour: Int, turns: Int) {
        self.dayOfWeek = dayOfWeek; self.hour = hour; self.turns = turns
    }

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case hour, turns
    }
}

public struct ProviderSession: Codable, Sendable, Hashable, Identifiable {
    public let sessionID: String
    public let displayName: String
    public let startedAt: String
    public let durationMinutes: Int
    public let turns: Int
    public let costUSD: Double
    public let model: String?
    public var id: String { self.sessionID }

    public init(
        sessionID: String, displayName: String, startedAt: String,
        durationMinutes: Int, turns: Int, costUSD: Double, model: String?
    ) {
        self.sessionID = sessionID; self.displayName = displayName; self.startedAt = startedAt
        self.durationMinutes = durationMinutes; self.turns = turns; self.costUSD = costUSD; self.model = model
    }

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case displayName = "display_name"
        case startedAt = "started_at"
        case durationMinutes = "duration_minutes"
        case turns
        case costUSD = "cost_usd"
        case model
    }
}

public struct ProviderSubagentBreakdown: Codable, Sendable, Hashable {
    public let totalTurns: Int
    public let totalCostUSD: Double
    public let sessionCount: Int
    public let agentCount: Int

    public init(totalTurns: Int, totalCostUSD: Double, sessionCount: Int, agentCount: Int) {
        self.totalTurns = totalTurns; self.totalCostUSD = totalCostUSD
        self.sessionCount = sessionCount; self.agentCount = agentCount
    }

    enum CodingKeys: String, CodingKey {
        case totalTurns = "total_turns"
        case totalCostUSD = "total_cost_usd"
        case sessionCount = "session_count"
        case agentCount = "agent_count"
    }
}

public struct ProviderVersionRow: Codable, Sendable, Hashable, Identifiable {
    public let version: String
    public let turns: Int
    public let sessions: Int
    public let costUSD: Double
    public var id: String { self.version }

    public init(version: String, turns: Int, sessions: Int, costUSD: Double) {
        self.version = version; self.turns = turns; self.sessions = sessions; self.costUSD = costUSD
    }

    enum CodingKeys: String, CodingKey {
        case version, turns, sessions
        case costUSD = "cost_usd"
    }
}

public struct ClaudeUsageFactorSnapshot: Codable, Sendable, Identifiable {
    public var factorKey: String
    public var displayLabel: String
    public var percent: Double
    public var adviceText: String

    public var id: String { self.factorKey }

    public init(factorKey: String, displayLabel: String, percent: Double, adviceText: String) {
        self.factorKey = factorKey
        self.displayLabel = displayLabel
        self.percent = percent
        self.adviceText = adviceText
    }

    enum CodingKeys: String, CodingKey {
        case factorKey = "factor_key"
        case displayLabel = "display_label"
        case percent
        case adviceText = "advice_text"
    }
}

public struct ClaudeUsageSnapshotPayload: Codable, Sendable {
    public var factors: [ClaudeUsageFactorSnapshot]

    public init(factors: [ClaudeUsageFactorSnapshot]) {
        self.factors = factors
    }
}

public struct ProviderSourceAttempt: Codable, Sendable, Identifiable {
    public var source: String
    public var outcome: String
    public var message: String?

    public var id: String { "\(self.source):\(self.outcome):\(self.message ?? "")" }

    public init(source: String, outcome: String, message: String?) {
        self.source = source
        self.outcome = outcome
        self.message = message
    }
}

public struct AuthRecoveryAction: Codable, Sendable, Identifiable {
    public var label: String
    public var actionID: String
    public var command: String?
    public var detail: String?

    public var id: String { self.actionID }

    public init(
        label: String,
        actionID: String,
        command: String?,
        detail: String?
    ) {
        self.label = label
        self.actionID = actionID
        self.command = command
        self.detail = detail
    }

    enum CodingKeys: String, CodingKey {
        case label
        case actionID = "action_id"
        case command
        case detail
    }
}

public struct ProviderAuthHealth: Codable, Sendable {
    public var loginMethod: String?
    public var credentialBackend: String?
    public var authMode: String?
    public var isAuthenticated: Bool
    public var isRefreshable: Bool
    public var isSourceCompatible: Bool
    public var requiresRelogin: Bool
    public var managedRestriction: String?
    public var diagnosticCode: String?
    public var failureReason: String?
    public var lastValidatedAt: String?
    public var recoveryActions: [AuthRecoveryAction]

    public init(
        loginMethod: String?,
        credentialBackend: String?,
        authMode: String?,
        isAuthenticated: Bool,
        isRefreshable: Bool,
        isSourceCompatible: Bool,
        requiresRelogin: Bool,
        managedRestriction: String?,
        diagnosticCode: String?,
        failureReason: String?,
        lastValidatedAt: String?,
        recoveryActions: [AuthRecoveryAction]
    ) {
        self.loginMethod = loginMethod
        self.credentialBackend = credentialBackend
        self.authMode = authMode
        self.isAuthenticated = isAuthenticated
        self.isRefreshable = isRefreshable
        self.isSourceCompatible = isSourceCompatible
        self.requiresRelogin = requiresRelogin
        self.managedRestriction = managedRestriction
        self.diagnosticCode = diagnosticCode
        self.failureReason = failureReason
        self.lastValidatedAt = lastValidatedAt
        self.recoveryActions = recoveryActions
    }

    enum CodingKeys: String, CodingKey {
        case loginMethod = "login_method"
        case credentialBackend = "credential_backend"
        case authMode = "auth_mode"
        case isAuthenticated = "is_authenticated"
        case isRefreshable = "is_refreshable"
        case isSourceCompatible = "is_source_compatible"
        case requiresRelogin = "requires_relogin"
        case managedRestriction = "managed_restriction"
        case diagnosticCode = "diagnostic_code"
        case failureReason = "failure_reason"
        case lastValidatedAt = "last_validated_at"
        case recoveryActions = "recovery_actions"
    }
}

// MARK: - Provider snapshot (main wire type from helper)

public struct ProviderSnapshot: Codable, Sendable, Identifiable {
    public var provider: String
    public var available: Bool
    public var sourceUsed: String
    public var lastAttemptedSource: String?
    public var resolvedViaFallback: Bool
    public var refreshDurationMs: UInt64
    public var sourceAttempts: [ProviderSourceAttempt]
    public var identity: ProviderIdentity?
    public var primary: ProviderRateWindow?
    public var secondary: ProviderRateWindow?
    public var tertiary: ProviderRateWindow?
    public var credits: Double?
    public var status: ProviderStatusSummary?
    public var auth: ProviderAuthHealth
    public var costSummary: ProviderCostSummary
    public var claudeUsage: ClaudeUsageSnapshotPayload?
    public var claudeAdmin: ClaudeAdminSummaryPayload?
    public var quotaSuggestions: QuotaSuggestions?
    public var depletionForecast: DepletionForecast?
    public var predictiveInsights: LivePredictiveInsights?
    public var lastRefresh: String
    public var stale: Bool
    public var error: String?

    public var id: String { self.provider }
    public var providerID: ProviderID? { ProviderID(rawValue: self.provider) }

    public init(
        provider: String,
        available: Bool,
        sourceUsed: String,
        lastAttemptedSource: String?,
        resolvedViaFallback: Bool,
        refreshDurationMs: UInt64,
        sourceAttempts: [ProviderSourceAttempt],
        identity: ProviderIdentity?,
        primary: ProviderRateWindow?,
        secondary: ProviderRateWindow?,
        tertiary: ProviderRateWindow?,
        credits: Double?,
        status: ProviderStatusSummary?,
        auth: ProviderAuthHealth,
        costSummary: ProviderCostSummary,
        claudeUsage: ClaudeUsageSnapshotPayload?,
        claudeAdmin: ClaudeAdminSummaryPayload? = nil,
        quotaSuggestions: QuotaSuggestions? = nil,
        depletionForecast: DepletionForecast? = nil,
        predictiveInsights: LivePredictiveInsights? = nil,
        lastRefresh: String,
        stale: Bool,
        error: String?
    ) {
        self.provider = provider
        self.available = available
        self.sourceUsed = sourceUsed
        self.lastAttemptedSource = lastAttemptedSource
        self.resolvedViaFallback = resolvedViaFallback
        self.refreshDurationMs = refreshDurationMs
        self.sourceAttempts = sourceAttempts
        self.identity = identity
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
        self.credits = credits
        self.status = status
        self.auth = auth
        self.costSummary = costSummary
        self.claudeUsage = claudeUsage
        self.claudeAdmin = claudeAdmin
        self.quotaSuggestions = quotaSuggestions
        self.depletionForecast = depletionForecast
        self.predictiveInsights = predictiveInsights
        self.lastRefresh = lastRefresh
        self.stale = stale
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case available
        case sourceUsed = "source_used"
        case lastAttemptedSource = "last_attempted_source"
        case resolvedViaFallback = "resolved_via_fallback"
        case refreshDurationMs = "refresh_duration_ms"
        case sourceAttempts = "source_attempts"
        case identity
        case primary
        case secondary
        case tertiary
        case credits
        case status
        case auth
        case costSummary = "cost_summary"
        case claudeUsage = "claude_usage"
        case claudeAdmin = "claude_admin"
        case quotaSuggestions = "quota_suggestions"
        case depletionForecast = "depletion_forecast"
        case predictiveInsights = "predictive_insights"
        case lastRefresh = "last_refresh"
        case stale
        case error
    }
}

public struct ProviderSnapshotEnvelope: Codable, Sendable {
    public var contractVersion: Int
    public var providers: [ProviderSnapshot]
    public var fetchedAt: String
    public var requestedProvider: String?
    public var responseScope: String
    public var cacheHit: Bool
    public var refreshedProviders: [String]
    public var localNotificationState: LocalNotificationState?

    public init(
        contractVersion: Int = LiveProviderContract.version,
        providers: [ProviderSnapshot],
        fetchedAt: String,
        requestedProvider: String?,
        responseScope: String,
        cacheHit: Bool,
        refreshedProviders: [String],
        localNotificationState: LocalNotificationState? = nil
    ) {
        self.contractVersion = contractVersion
        self.providers = providers
        self.fetchedAt = fetchedAt
        self.requestedProvider = requestedProvider
        self.responseScope = responseScope
        self.cacheHit = cacheHit
        self.refreshedProviders = refreshedProviders
        self.localNotificationState = localNotificationState
    }

    enum CodingKeys: String, CodingKey {
        case contractVersion = "contract_version"
        case providers
        case fetchedAt = "fetched_at"
        case requestedProvider = "requested_provider"
        case responseScope = "response_scope"
        case cacheHit = "cache_hit"
        case refreshedProviders = "refreshed_providers"
        case localNotificationState = "local_notification_state"
    }
}

// MARK: - Local notification types (travel with ProviderSnapshotEnvelope)

public struct LocalNotificationCondition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var kind: String
    public var provider: String?
    public var serviceLabel: String
    public var isActive: Bool
    public var activationTitle: String
    public var activationBody: String
    public var recoveryTitle: String?
    public var recoveryBody: String?
    public var dayKey: String?

    public init(
        id: String,
        kind: String,
        provider: String?,
        serviceLabel: String,
        isActive: Bool,
        activationTitle: String,
        activationBody: String,
        recoveryTitle: String? = nil,
        recoveryBody: String? = nil,
        dayKey: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.provider = provider
        self.serviceLabel = serviceLabel
        self.isActive = isActive
        self.activationTitle = activationTitle
        self.activationBody = activationBody
        self.recoveryTitle = recoveryTitle
        self.recoveryBody = recoveryBody
        self.dayKey = dayKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case provider
        case serviceLabel = "service_label"
        case isActive = "is_active"
        case activationTitle = "activation_title"
        case activationBody = "activation_body"
        case recoveryTitle = "recovery_title"
        case recoveryBody = "recovery_body"
        case dayKey = "day_key"
    }
}

public struct LocalNotificationState: Codable, Sendable, Equatable {
    public var generatedAt: String
    public var costThresholdUSD: Double?
    public var conditions: [LocalNotificationCondition]

    public init(
        generatedAt: String,
        costThresholdUSD: Double? = nil,
        conditions: [LocalNotificationCondition]
    ) {
        self.generatedAt = generatedAt
        self.costThresholdUSD = costThresholdUSD
        self.conditions = conditions
    }

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case costThresholdUSD = "cost_threshold_usd"
        case conditions
    }
}
