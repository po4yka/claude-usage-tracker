import Foundation

public struct MobileProviderHistorySeries: Codable, Sendable, Identifiable {
    public var provider: String
    public var daily: [CostHistoryPoint]
    public var totalTokens: Int
    public var totalCostUSD: Double

    public var id: String { self.provider }
    public var providerID: ProviderID? { ProviderID(rawValue: self.provider) }

    public init(
        provider: String,
        daily: [CostHistoryPoint],
        totalTokens: Int,
        totalCostUSD: Double
    ) {
        self.provider = provider
        self.daily = daily
        self.totalTokens = totalTokens
        self.totalCostUSD = totalCostUSD
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case daily
        case totalTokens = "total_tokens"
        case totalCostUSD = "total_cost_usd"
    }
}

public struct MobileSnapshotTotals: Codable, Sendable {
    public var todayTokens: Int
    public var todayCostUSD: Double
    public var last90DaysTokens: Int
    public var last90DaysCostUSD: Double
    public var todayBreakdown: TokenBreakdown?
    public var last90DaysBreakdown: TokenBreakdown?

    public init(
        todayTokens: Int,
        todayCostUSD: Double,
        last90DaysTokens: Int,
        last90DaysCostUSD: Double,
        todayBreakdown: TokenBreakdown? = nil,
        last90DaysBreakdown: TokenBreakdown? = nil
    ) {
        self.todayTokens = todayTokens
        self.todayCostUSD = todayCostUSD
        self.last90DaysTokens = last90DaysTokens
        self.last90DaysCostUSD = last90DaysCostUSD
        self.todayBreakdown = todayBreakdown
        self.last90DaysBreakdown = last90DaysBreakdown
    }

    enum CodingKeys: String, CodingKey {
        case todayTokens = "today_tokens"
        case todayCostUSD = "today_cost_usd"
        case last90DaysTokens = "last_90_days_tokens"
        case last90DaysCostUSD = "last_90_days_cost_usd"
        case todayBreakdown = "today_breakdown"
        case last90DaysBreakdown = "last_90_days_breakdown"
    }
}

public extension MobileSnapshotTotals {
    func merging(_ other: MobileSnapshotTotals) -> MobileSnapshotTotals {
        MobileSnapshotTotals(
            todayTokens: self.todayTokens + other.todayTokens,
            todayCostUSD: self.todayCostUSD + other.todayCostUSD,
            last90DaysTokens: self.last90DaysTokens + other.last90DaysTokens,
            last90DaysCostUSD: self.last90DaysCostUSD + other.last90DaysCostUSD,
            todayBreakdown: TokenBreakdown.sum([self.todayBreakdown, other.todayBreakdown].compactMap { $0 }),
            last90DaysBreakdown: TokenBreakdown.sum([self.last90DaysBreakdown, other.last90DaysBreakdown].compactMap { $0 })
        )
    }
}

public struct MobileSnapshotFreshness: Codable, Sendable {
    public var newestProviderRefresh: String?
    public var oldestProviderRefresh: String?
    public var staleProviders: [String]
    public var hasStaleProviders: Bool

    public init(
        newestProviderRefresh: String?,
        oldestProviderRefresh: String?,
        staleProviders: [String],
        hasStaleProviders: Bool
    ) {
        self.newestProviderRefresh = newestProviderRefresh
        self.oldestProviderRefresh = oldestProviderRefresh
        self.staleProviders = staleProviders
        self.hasStaleProviders = hasStaleProviders
    }

    enum CodingKeys: String, CodingKey {
        case newestProviderRefresh = "newest_provider_refresh"
        case oldestProviderRefresh = "oldest_provider_refresh"
        case staleProviders = "stale_providers"
        case hasStaleProviders = "has_stale_providers"
    }
}

public struct MobileSnapshotEnvelope: Codable, Sendable {
    public var contractVersion: Int
    public var generatedAt: String
    public var sourceDevice: String
    public var providers: [ProviderSnapshot]
    public var history90d: [MobileProviderHistorySeries]
    public var totals: MobileSnapshotTotals
    public var freshness: MobileSnapshotFreshness

    public init(
        contractVersion: Int = MobileSnapshotContract.version,
        generatedAt: String,
        sourceDevice: String,
        providers: [ProviderSnapshot],
        history90d: [MobileProviderHistorySeries],
        totals: MobileSnapshotTotals,
        freshness: MobileSnapshotFreshness
    ) {
        self.contractVersion = contractVersion
        self.generatedAt = generatedAt
        self.sourceDevice = sourceDevice
        self.providers = providers
        self.history90d = history90d
        self.totals = totals
        self.freshness = freshness
    }

    public var providerEnvelope: ProviderSnapshotEnvelope {
        ProviderSnapshotEnvelope(
            contractVersion: LiveProviderContract.version,
            providers: self.providers,
            fetchedAt: self.generatedAt,
            requestedProvider: nil,
            responseScope: "all",
            cacheHit: false,
            refreshedProviders: self.providers.map(\.provider)
        )
    }

    enum CodingKeys: String, CodingKey {
        case contractVersion = "contract_version"
        case generatedAt = "generated_at"
        case sourceDevice = "source_device"
        case providers
        case history90d = "history_90d"
        case totals
        case freshness
    }
}

public struct SyncedInstallationSnapshot: Codable, Sendable, Identifiable {
    public var installationID: String
    public var sourceDevice: String
    public var publishedAt: String
    public var providers: [ProviderSnapshot]
    public var history90d: [MobileProviderHistorySeries]
    public var totals: MobileSnapshotTotals
    public var freshness: MobileSnapshotFreshness

    public var id: String { self.installationID }

    public init(
        installationID: String,
        sourceDevice: String,
        publishedAt: String,
        providers: [ProviderSnapshot],
        history90d: [MobileProviderHistorySeries],
        totals: MobileSnapshotTotals,
        freshness: MobileSnapshotFreshness
    ) {
        self.installationID = installationID
        self.sourceDevice = sourceDevice
        self.publishedAt = publishedAt
        self.providers = providers
        self.history90d = history90d
        self.totals = totals
        self.freshness = freshness
    }

    public var isStale: Bool {
        self.freshness.hasStaleProviders || self.providers.contains(where: \.stale)
    }

    public var accountLabels: [String] {
        Array(Set(self.providers.compactMap { snapshot in
            if let email = snapshot.identity?.accountEmail, !email.isEmpty {
                return email
            }
            if let organization = snapshot.identity?.accountOrganization, !organization.isEmpty {
                return organization
            }
            return nil
        })).sorted()
    }

    public var asMobileSnapshotEnvelope: MobileSnapshotEnvelope {
        MobileSnapshotEnvelope(
            generatedAt: self.publishedAt,
            sourceDevice: self.sourceDevice,
            providers: self.providers,
            history90d: self.history90d,
            totals: self.totals,
            freshness: self.freshness
        )
    }

    public static func from(
        mobileSnapshot: MobileSnapshotEnvelope,
        installationID: String
    ) -> SyncedInstallationSnapshot {
        SyncedInstallationSnapshot(
            installationID: installationID,
            sourceDevice: mobileSnapshot.sourceDevice,
            publishedAt: mobileSnapshot.generatedAt,
            providers: mobileSnapshot.providers,
            history90d: mobileSnapshot.history90d,
            totals: mobileSnapshot.totals,
            freshness: mobileSnapshot.freshness
        )
    }

    enum CodingKeys: String, CodingKey {
        case installationID = "installation_id"
        case sourceDevice = "source_device"
        case publishedAt = "published_at"
        case providers
        case history90d = "history_90d"
        case totals
        case freshness
    }
}

public struct SyncedAggregateProviderView: Codable, Sendable, Identifiable {
    public var providerSnapshot: ProviderSnapshot
    public var installationIDs: [String]
    public var accountLabels: [String]
    public var staleInstallationIDs: [String]
    public var currentLimitInstallationIDs: [String]

    public var id: String { self.providerSnapshot.provider }
    public var provider: String { self.providerSnapshot.provider }
    public var providerID: ProviderID? { self.providerSnapshot.providerID }

    public init(
        providerSnapshot: ProviderSnapshot,
        installationIDs: [String],
        accountLabels: [String],
        staleInstallationIDs: [String],
        currentLimitInstallationIDs: [String]
    ) {
        self.providerSnapshot = providerSnapshot
        self.installationIDs = installationIDs
        self.accountLabels = accountLabels
        self.staleInstallationIDs = staleInstallationIDs
        self.currentLimitInstallationIDs = currentLimitInstallationIDs
    }

    enum CodingKeys: String, CodingKey {
        case providerSnapshot = "provider_snapshot"
        case installationIDs = "installation_ids"
        case accountLabels = "account_labels"
        case staleInstallationIDs = "stale_installation_ids"
        case currentLimitInstallationIDs = "current_limit_installation_ids"
    }
}

public struct SyncedAggregateEnvelope: Codable, Sendable {
    public var contractVersion: Int
    public var generatedAt: String
    public var installations: [SyncedInstallationSnapshot]
    public var aggregateTotals: MobileSnapshotTotals
    public var aggregateProviderViews: [SyncedAggregateProviderView]
    public var staleInstallations: [String]

    public init(
        contractVersion: Int = SyncedAggregateContract.version,
        generatedAt: String,
        installations: [SyncedInstallationSnapshot],
        aggregateTotals: MobileSnapshotTotals,
        aggregateProviderViews: [SyncedAggregateProviderView],
        staleInstallations: [String]
    ) {
        self.contractVersion = contractVersion
        self.generatedAt = generatedAt
        self.installations = installations
        self.aggregateTotals = aggregateTotals
        self.aggregateProviderViews = aggregateProviderViews
        self.staleInstallations = staleInstallations
    }

    public var mobileSnapshotCompatibility: MobileSnapshotEnvelope {
        MobileSnapshotEnvelope(
            generatedAt: self.generatedAt,
            sourceDevice: self.installations.first?.sourceDevice ?? "multi-mac",
            providers: self.aggregateProviderViews.map(\.providerSnapshot),
            history90d: self.aggregateHistory90d(),
            totals: self.aggregateTotals,
            freshness: MobileSnapshotFreshness(
                newestProviderRefresh: self.installations.compactMap(\.freshness.newestProviderRefresh).max(),
                oldestProviderRefresh: self.installations.compactMap(\.freshness.oldestProviderRefresh).min(),
                staleProviders: Array(Set(self.installations.flatMap(\.freshness.staleProviders))).sorted(),
                hasStaleProviders: !self.staleInstallations.isEmpty
            )
        )
    }

    public func aggregateHistorySeries(for provider: ProviderID) -> MobileProviderHistorySeries? {
        self.aggregateHistory90d().first(where: { $0.providerID == provider })
    }

    public func aggregateHistory90d() -> [MobileProviderHistorySeries] {
        let rows: [(String, MobileProviderHistorySeries)] = self.installations.flatMap { installation in
            installation.history90d.map { (installation.installationID, $0) }
        }
        let grouped: [String: [(String, MobileProviderHistorySeries)]] = Dictionary(
            grouping: rows,
            by: { $0.1.provider }
        )

        return grouped.keys.sorted().map { provider in
            let providerRows = grouped[provider] ?? []
            let totals = providerRows.map(\.1)
            let allPoints = providerRows.flatMap { (_, series) in series.daily }
            let dailyGroups: [String: [CostHistoryPoint]] = Dictionary(grouping: allPoints, by: \.day)
            let daily = dailyGroups.map { day, points in
                CostHistoryPoint(
                    day: day,
                    totalTokens: points.reduce(0) { partial, point in partial + point.totalTokens },
                    costUSD: points.reduce(0) { partial, point in partial + point.costUSD },
                    breakdown: TokenBreakdown.sum(points.compactMap(\.breakdown))
                )
            }
            .sorted(by: { lhs, rhs in lhs.day < rhs.day })

            return MobileProviderHistorySeries(
                provider: provider,
                daily: daily,
                totalTokens: totals.reduce(0) { partial, series in partial + series.totalTokens },
                totalCostUSD: totals.reduce(0) { partial, series in partial + series.totalCostUSD }
            )
        }
    }

    public static func aggregate(
        installations: [SyncedInstallationSnapshot],
        generatedAt: String
    ) -> SyncedAggregateEnvelope {
        let sortedInstallations = installations.sorted { lhs, rhs in
            if lhs.publishedAt == rhs.publishedAt {
                return lhs.installationID < rhs.installationID
            }
            return lhs.publishedAt > rhs.publishedAt
        }
        let aggregateTotals = sortedInstallations
            .map(\.totals)
            .reduce(MobileSnapshotTotals(todayTokens: 0, todayCostUSD: 0, last90DaysTokens: 0, last90DaysCostUSD: 0)) {
                $0.merging($1)
            }
        let groupedProviders = Dictionary(grouping: sortedInstallations.flatMap { installation in
            installation.providers.map { (installation, $0) }
        }, by: { $0.1.provider })

        let sortedProviders = groupedProviders.keys.sorted()
        let aggregateProviderViews: [SyncedAggregateProviderView] = sortedProviders.compactMap { provider in
            let rows = groupedProviders[provider] ?? []
            let snapshots = rows.map(\.1)
            guard let representative = snapshots
                .filter({ $0.available && !$0.stale })
                .max(by: { $0.lastRefresh < $1.lastRefresh }) ?? snapshots.max(by: { $0.lastRefresh < $1.lastRefresh }) else {
                return nil
            }

            let mergedSnapshot = ProviderSnapshot(
                provider: representative.provider,
                available: snapshots.contains(where: { $0.available && !$0.stale }),
                sourceUsed: representative.sourceUsed,
                lastAttemptedSource: representative.lastAttemptedSource,
                resolvedViaFallback: snapshots.contains(where: \.resolvedViaFallback),
                refreshDurationMs: representative.refreshDurationMs,
                sourceAttempts: representative.sourceAttempts,
                identity: representative.identity,
                primary: representative.available && !representative.stale ? representative.primary : nil,
                secondary: representative.available && !representative.stale ? representative.secondary : nil,
                tertiary: representative.available && !representative.stale ? representative.tertiary : nil,
                credits: snapshots.compactMap(\.credits).reduce(0, +),
                status: representative.status,
                auth: representative.auth,
                costSummary: snapshots.map(\.costSummary).reduce(
                    ProviderCostSummary(todayTokens: 0, todayCostUSD: 0, last30DaysTokens: 0, last30DaysCostUSD: 0, daily: [])
                ) { $0.merging($1) },
                claudeUsage: representative.claudeUsage,
                claudeAdmin: representative.claudeAdmin,
                quotaSuggestions: representative.available && !representative.stale ? representative.quotaSuggestions : nil,
                depletionForecast: representative.available && !representative.stale ? representative.depletionForecast : nil,
                predictiveInsights: representative.available && !representative.stale ? representative.predictiveInsights : nil,
                lastRefresh: representative.lastRefresh,
                stale: !snapshots.contains(where: { $0.available && !$0.stale }),
                error: representative.error
            )

            return SyncedAggregateProviderView(
                providerSnapshot: mergedSnapshot,
                installationIDs: rows.map(\.0.installationID).sorted(),
                accountLabels: Array(Set(rows.compactMap { installation, snapshot in
                    if let email = snapshot.identity?.accountEmail, !email.isEmpty {
                        return email
                    }
                    if let organization = snapshot.identity?.accountOrganization, !organization.isEmpty {
                        return organization
                    }
                    return installation.sourceDevice
                })).sorted(),
                staleInstallationIDs: Array(Set(rows.compactMap { installation, snapshot in
                    snapshot.stale ? installation.installationID : nil
                })).sorted(),
                currentLimitInstallationIDs: Array(Set(rows.compactMap { installation, snapshot in
                    snapshot.available && !snapshot.stale ? installation.installationID : nil
                })).sorted()
            )
        }

        return SyncedAggregateEnvelope(
            generatedAt: generatedAt,
            installations: sortedInstallations,
            aggregateTotals: aggregateTotals,
            aggregateProviderViews: aggregateProviderViews,
            staleInstallations: sortedInstallations.filter(\.isStale).map(\.installationID)
        )
    }

    public static func singleInstallation(
        mobileSnapshot: MobileSnapshotEnvelope,
        installationID: String
    ) -> SyncedAggregateEnvelope {
        let installation = SyncedInstallationSnapshot.from(
            mobileSnapshot: mobileSnapshot,
            installationID: installationID
        )
        return self.aggregate(
            installations: [installation],
            generatedAt: mobileSnapshot.generatedAt
        )
    }

    enum CodingKeys: String, CodingKey {
        case contractVersion = "contract_version"
        case generatedAt = "generated_at"
        case installations
        case aggregateTotals = "aggregate_totals"
        case aggregateProviderViews = "aggregate_provider_views"
        case staleInstallations = "stale_installations"
    }
}
