import Foundation

public struct ProviderCostSummary: Codable, Sendable {
    public var todayTokens: Int
    public var todayCostUSD: Double
    public var last30DaysTokens: Int
    public var last30DaysCostUSD: Double
    public var daily: [CostHistoryPoint]
    public var todayBreakdown: TokenBreakdown?
    public var last30DaysBreakdown: TokenBreakdown?
    public var cacheHitRateToday: Double?
    public var cacheHitRate30d: Double?
    public var cacheSavings30dUSD: Double?
    public var byModel: [ProviderModelRow]
    public var byProject: [ProviderProjectRow]
    public var byTool: [ProviderToolRow]
    public var byMcp: [ProviderMcpRow]
    public var hourlyActivity: [ProviderHourlyBucket]
    public var activityHeatmap: [ProviderHeatmapCell]
    public var recentSessions: [ProviderSession]
    public var subagentBreakdown: ProviderSubagentBreakdown?
    public var versionBreakdown: [ProviderVersionRow]
    public var dailyByModel: [ProviderDailyModelRow]

    public init(
        todayTokens: Int,
        todayCostUSD: Double,
        last30DaysTokens: Int,
        last30DaysCostUSD: Double,
        daily: [CostHistoryPoint],
        todayBreakdown: TokenBreakdown? = nil,
        last30DaysBreakdown: TokenBreakdown? = nil,
        cacheHitRateToday: Double? = nil,
        cacheHitRate30d: Double? = nil,
        cacheSavings30dUSD: Double? = nil,
        byModel: [ProviderModelRow] = [],
        byProject: [ProviderProjectRow] = [],
        byTool: [ProviderToolRow] = [],
        byMcp: [ProviderMcpRow] = [],
        hourlyActivity: [ProviderHourlyBucket] = [],
        activityHeatmap: [ProviderHeatmapCell] = [],
        recentSessions: [ProviderSession] = [],
        subagentBreakdown: ProviderSubagentBreakdown? = nil,
        versionBreakdown: [ProviderVersionRow] = [],
        dailyByModel: [ProviderDailyModelRow] = []
    ) {
        self.todayTokens = todayTokens
        self.todayCostUSD = todayCostUSD
        self.last30DaysTokens = last30DaysTokens
        self.last30DaysCostUSD = last30DaysCostUSD
        self.daily = daily
        self.todayBreakdown = todayBreakdown
        self.last30DaysBreakdown = last30DaysBreakdown
        self.cacheHitRateToday = cacheHitRateToday
        self.cacheHitRate30d = cacheHitRate30d
        self.cacheSavings30dUSD = cacheSavings30dUSD
        self.byModel = byModel
        self.byProject = byProject
        self.byTool = byTool
        self.byMcp = byMcp
        self.hourlyActivity = hourlyActivity
        self.activityHeatmap = activityHeatmap
        self.recentSessions = recentSessions
        self.subagentBreakdown = subagentBreakdown
        self.versionBreakdown = versionBreakdown
        self.dailyByModel = dailyByModel
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.todayTokens = try container.decode(Int.self, forKey: .todayTokens)
        self.todayCostUSD = try container.decode(Double.self, forKey: .todayCostUSD)
        self.last30DaysTokens = try container.decode(Int.self, forKey: .last30DaysTokens)
        self.last30DaysCostUSD = try container.decode(Double.self, forKey: .last30DaysCostUSD)
        self.daily = try container.decode([CostHistoryPoint].self, forKey: .daily)
        self.todayBreakdown = try container.decodeIfPresent(TokenBreakdown.self, forKey: .todayBreakdown)
        self.last30DaysBreakdown = try container.decodeIfPresent(TokenBreakdown.self, forKey: .last30DaysBreakdown)
        self.cacheHitRateToday = try container.decodeIfPresent(Double.self, forKey: .cacheHitRateToday)
        self.cacheHitRate30d = try container.decodeIfPresent(Double.self, forKey: .cacheHitRate30d)
        self.cacheSavings30dUSD = try container.decodeIfPresent(Double.self, forKey: .cacheSavings30dUSD)
        self.byModel = try container.decodeIfPresent([ProviderModelRow].self, forKey: .byModel) ?? []
        self.byProject = try container.decodeIfPresent([ProviderProjectRow].self, forKey: .byProject) ?? []
        self.byTool = try container.decodeIfPresent([ProviderToolRow].self, forKey: .byTool) ?? []
        self.byMcp = try container.decodeIfPresent([ProviderMcpRow].self, forKey: .byMcp) ?? []
        self.hourlyActivity = try container.decodeIfPresent([ProviderHourlyBucket].self, forKey: .hourlyActivity) ?? []
        self.activityHeatmap = try container.decodeIfPresent([ProviderHeatmapCell].self, forKey: .activityHeatmap) ?? []
        self.recentSessions = try container.decodeIfPresent([ProviderSession].self, forKey: .recentSessions) ?? []
        self.subagentBreakdown = try container.decodeIfPresent(ProviderSubagentBreakdown.self, forKey: .subagentBreakdown)
        self.versionBreakdown = try container.decodeIfPresent([ProviderVersionRow].self, forKey: .versionBreakdown) ?? []
        self.dailyByModel = try container.decodeIfPresent([ProviderDailyModelRow].self, forKey: .dailyByModel) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case todayTokens = "today_tokens"
        case todayCostUSD = "today_cost_usd"
        case last30DaysTokens = "last_30_days_tokens"
        case last30DaysCostUSD = "last_30_days_cost_usd"
        case daily
        case todayBreakdown = "today_breakdown"
        case last30DaysBreakdown = "last_30_days_breakdown"
        case cacheHitRateToday = "cache_hit_rate_today"
        case cacheHitRate30d = "cache_hit_rate_30d"
        case cacheSavings30dUSD = "cache_savings_30d_usd"
        case byModel = "by_model"
        case byProject = "by_project"
        case byTool = "by_tool"
        case byMcp = "by_mcp"
        case hourlyActivity = "hourly_activity"
        case activityHeatmap = "activity_heatmap"
        case recentSessions = "recent_sessions"
        case subagentBreakdown = "subagent_breakdown"
        case versionBreakdown = "version_breakdown"
        case dailyByModel = "daily_by_model"
    }
}

public extension ProviderCostSummary {
    func merging(_ other: ProviderCostSummary) -> ProviderCostSummary {
        let mergedDaily = Dictionary(grouping: self.daily + other.daily, by: \.day)
            .map { day, points in
                CostHistoryPoint(
                    day: day,
                    totalTokens: points.reduce(0) { $0 + $1.totalTokens },
                    costUSD: points.reduce(0) { $0 + $1.costUSD },
                    breakdown: TokenBreakdown.sum(points.compactMap(\.breakdown))
                )
            }
            .sorted { $0.day < $1.day }
        var mergedRecentSessions = self.recentSessions
        mergedRecentSessions.append(contentsOf: other.recentSessions)
        mergedRecentSessions.sort { lhs, rhs in
            lhs.startedAt > rhs.startedAt
        }
        let mergedRecentSessionsByID = Array(
            Dictionary(
                mergedRecentSessions.map { ($0.sessionID, $0) },
                uniquingKeysWith: { current, _ in current }
            ).values
        )
        .sorted { lhs, rhs in
            lhs.startedAt > rhs.startedAt
        }

        return ProviderCostSummary(
            todayTokens: self.todayTokens + other.todayTokens,
            todayCostUSD: self.todayCostUSD + other.todayCostUSD,
            last30DaysTokens: self.last30DaysTokens + other.last30DaysTokens,
            last30DaysCostUSD: self.last30DaysCostUSD + other.last30DaysCostUSD,
            daily: mergedDaily,
            todayBreakdown: TokenBreakdown.sum([self.todayBreakdown, other.todayBreakdown].compactMap { $0 }),
            last30DaysBreakdown: TokenBreakdown.sum([self.last30DaysBreakdown, other.last30DaysBreakdown].compactMap { $0 }),
            cacheHitRateToday: ProviderCostSummaryMerge.weightedRate(
                lhsRate: self.cacheHitRateToday,
                lhsWeight: self.todayTokens,
                rhsRate: other.cacheHitRateToday,
                rhsWeight: other.todayTokens
            ),
            cacheHitRate30d: ProviderCostSummaryMerge.weightedRate(
                lhsRate: self.cacheHitRate30d,
                lhsWeight: self.last30DaysTokens,
                rhsRate: other.cacheHitRate30d,
                rhsWeight: other.last30DaysTokens
            ),
            cacheSavings30dUSD: [self.cacheSavings30dUSD, other.cacheSavings30dUSD].compactMap { $0 }.reduce(0, +),
            byModel: ProviderCostSummaryMerge.models(self.byModel, other.byModel),
            byProject: ProviderCostSummaryMerge.projects(self.byProject, other.byProject),
            byTool: ProviderCostSummaryMerge.tools(self.byTool, other.byTool),
            byMcp: ProviderCostSummaryMerge.mcps(self.byMcp, other.byMcp),
            hourlyActivity: ProviderCostSummaryMerge.hourly(self.hourlyActivity, other.hourlyActivity),
            activityHeatmap: ProviderCostSummaryMerge.heatmap(self.activityHeatmap, other.activityHeatmap),
            recentSessions: mergedRecentSessionsByID,
            subagentBreakdown: ProviderCostSummaryMerge.subagents(self.subagentBreakdown, other.subagentBreakdown),
            versionBreakdown: ProviderCostSummaryMerge.versions(self.versionBreakdown, other.versionBreakdown),
            dailyByModel: ProviderCostSummaryMerge.dailyByModel(self.dailyByModel, other.dailyByModel)
        )
    }
}
