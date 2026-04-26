import Foundation

public struct LivePredictivePercentiles: Codable, Sendable, Equatable {
    public var average: Double
    public var p50: Double
    public var p75: Double
    public var p90: Double
    public var p95: Double

    public init(
        average: Double,
        p50: Double,
        p75: Double,
        p90: Double,
        p95: Double
    ) {
        self.average = average
        self.p50 = p50
        self.p75 = p75
        self.p90 = p90
        self.p95 = p95
    }
}

public struct LivePredictiveRollingHourBurn: Codable, Sendable, Equatable {
    public var tokensPerMin: Double
    public var costPerHourNanos: Int
    public var coverageMinutes: Double
    public var tier: String?

    public init(
        tokensPerMin: Double,
        costPerHourNanos: Int,
        coverageMinutes: Double,
        tier: String? = nil
    ) {
        self.tokensPerMin = tokensPerMin
        self.costPerHourNanos = costPerHourNanos
        self.coverageMinutes = coverageMinutes
        self.tier = tier
    }

    enum CodingKeys: String, CodingKey {
        case tokensPerMin = "tokens_per_min"
        case costPerHourNanos = "cost_per_hour_nanos"
        case coverageMinutes = "coverage_minutes"
        case tier
    }
}

public struct LivePredictiveHistoricalEnvelope: Codable, Sendable, Equatable {
    public var sampleCount: Int
    public var tokens: LivePredictivePercentiles
    public var costUSD: LivePredictivePercentiles
    public var turns: LivePredictivePercentiles

    public init(
        sampleCount: Int,
        tokens: LivePredictivePercentiles,
        costUSD: LivePredictivePercentiles,
        turns: LivePredictivePercentiles
    ) {
        self.sampleCount = sampleCount
        self.tokens = tokens
        self.costUSD = costUSD
        self.turns = turns
    }

    enum CodingKeys: String, CodingKey {
        case sampleCount = "sample_count"
        case tokens
        case costUSD = "cost_usd"
        case turns
    }
}

public struct LivePredictiveLimitHitAnalysis: Codable, Sendable, Equatable {
    public var sampleCount: Int
    public var hitCount: Int
    public var hitRate: Double
    public var thresholdTokens: Int?
    public var thresholdPercent: Double?
    public var activeCurrentHit: Bool?
    public var activeProjectedHit: Bool?
    public var riskLevel: String
    public var summaryLabel: String

    public init(
        sampleCount: Int,
        hitCount: Int,
        hitRate: Double,
        thresholdTokens: Int? = nil,
        thresholdPercent: Double? = nil,
        activeCurrentHit: Bool? = nil,
        activeProjectedHit: Bool? = nil,
        riskLevel: String,
        summaryLabel: String
    ) {
        self.sampleCount = sampleCount
        self.hitCount = hitCount
        self.hitRate = hitRate
        self.thresholdTokens = thresholdTokens
        self.thresholdPercent = thresholdPercent
        self.activeCurrentHit = activeCurrentHit
        self.activeProjectedHit = activeProjectedHit
        self.riskLevel = riskLevel
        self.summaryLabel = summaryLabel
    }

    enum CodingKeys: String, CodingKey {
        case sampleCount = "sample_count"
        case hitCount = "hit_count"
        case hitRate = "hit_rate"
        case thresholdTokens = "threshold_tokens"
        case thresholdPercent = "threshold_percent"
        case activeCurrentHit = "active_current_hit"
        case activeProjectedHit = "active_projected_hit"
        case riskLevel = "risk_level"
        case summaryLabel = "summary_label"
    }
}

public struct LivePredictiveInsights: Codable, Sendable, Equatable {
    public var rollingHourBurn: LivePredictiveRollingHourBurn?
    public var historicalEnvelope: LivePredictiveHistoricalEnvelope?
    public var limitHitAnalysis: LivePredictiveLimitHitAnalysis?

    public init(
        rollingHourBurn: LivePredictiveRollingHourBurn? = nil,
        historicalEnvelope: LivePredictiveHistoricalEnvelope? = nil,
        limitHitAnalysis: LivePredictiveLimitHitAnalysis? = nil
    ) {
        self.rollingHourBurn = rollingHourBurn
        self.historicalEnvelope = historicalEnvelope
        self.limitHitAnalysis = limitHitAnalysis
    }

    enum CodingKeys: String, CodingKey {
        case rollingHourBurn = "rolling_hour_burn"
        case historicalEnvelope = "historical_envelope"
        case limitHitAnalysis = "limit_hit_analysis"
    }
}
