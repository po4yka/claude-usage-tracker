import HeimdallDomain
import SwiftUI

extension UsageSourcePreference {
    var title: String {
        switch self {
        case .auto: return "Automatic"
        case .oauth: return "OAuth"
        case .web: return "Web"
        case .cli: return "CLI"
        }
    }

    var settingsCaption: String {
        switch self {
        case .auto: return "Pick the best signal Heimdall can read."
        case .oauth: return "Use signed-in OAuth credentials."
        case .web: return "Use cookies imported from a browser session."
        case .cli: return "Use the provider's local CLI for usage."
        }
    }
}

extension ResetDisplayMode {
    var title: String {
        switch self {
        case .countdown: return "Countdown"
        case .absolute: return "Absolute time"
        }
    }
}

struct SettingsView: View {
    @Bindable var model: SettingsFeatureModel
    let providerModel: (ProviderID) -> ProviderFeatureModel

    var body: some View {
        TabView {
            SettingsGeneralTab(model: self.model)
                .tabItem { Label("General", systemImage: "gearshape") }

            SettingsProvidersTab(
                model: self.model,
                providerModel: self.providerModel
            )
                .tabItem {
                    Label("Providers", systemImage: "point.3.connected.trianglepath.dotted")
                }

            SettingsCloudSyncTab(model: self.model)
                .tabItem { Label("Cloud Sync", systemImage: "icloud") }

            SettingsAdvancedTab(model: self.model)
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
        .onAppear { self.model.resetDraftFromLiveConfig() }
        .task {
            await self.model.refreshBrowserImports()
            await self.model.refreshCloudSyncState()
        }
    }
}

// MARK: - General

private struct SettingsGeneralTab: View {
    @Bindable var model: SettingsFeatureModel

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Merge menu-bar icons", isOn: self.$model.draftConfig.mergeIcons)
                Toggle("Show used values", isOn: self.$model.draftConfig.showUsedValues)
                Picker("Reset display", selection: self.$model.draftConfig.resetDisplayMode) {
                    ForEach(ResetDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                LabeledContent("Refresh interval") {
                    Stepper(
                        value: self.$model.draftConfig.refreshIntervalSeconds,
                        in: 60...1800,
                        step: 60
                    ) {
                        Text("\(self.model.draftConfig.refreshIntervalSeconds)s")
                            .font(.body.monospacedDigit())
                    }
                    .labelsHidden()
                }
            }

            Section("Notifications") {
                Toggle("Enable local notifications", isOn: self.$model.draftConfig.localNotificationsEnabled)
                Toggle("Check provider status", isOn: self.$model.draftConfig.checkProviderStatus)
            }

            SettingsSaveActionSection(model: self.model)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Providers

private struct SettingsProvidersTab: View {
    @Bindable var model: SettingsFeatureModel
    let providerModel: (ProviderID) -> ProviderFeatureModel
    @State private var selection: ProviderID = .claude

    var body: some View {
        NavigationSplitView {
            List(ProviderID.allCases, selection: self.$selection) { provider in
                Label(provider.title, systemImage: self.symbol(for: provider))
                    .tag(provider)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 220)
        } detail: {
            ProviderDetailPane(
                settingsModel: self.model,
                providerModel: self.providerModel(self.selection)
            )
        }
    }

    private func symbol(for provider: ProviderID) -> String {
        switch provider {
        case .claude: return "bubble.left.and.bubble.right"
        case .codex: return "curlybraces"
        }
    }
}

private struct ProviderDetailPane: View {
    @Bindable var settingsModel: SettingsFeatureModel
    @Bindable var providerModel: ProviderFeatureModel

    private var configBinding: Binding<ProviderConfig> {
        switch self.providerModel.provider {
        case .claude: return self.$settingsModel.draftConfig.claude
        case .codex: return self.$settingsModel.draftConfig.codex
        }
    }

    var body: some View {
        Form {
            Section {
                ProviderEnableHeaderRow(
                    title: self.providerModel.provider.title,
                    subtitle: self.subtitle,
                    isOn: self.configBinding.enabled
                )
            }

            ProviderConnectionSection(config: self.configBinding)
                .disabled(!self.configBinding.wrappedValue.enabled)

            ProviderAuthenticationSection(model: self.providerModel)

            ProviderWebSessionSection(model: self.providerModel)
                .disabled(!self.configBinding.wrappedValue.enabled)

            SettingsSaveActionSection(model: self.settingsModel)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(self.providerModel.provider.title)
    }

    private var subtitle: String {
        switch self.providerModel.provider {
        case .claude: return "Anthropic usage and authentication"
        case .codex: return "OpenAI usage and authentication"
        }
    }
}

private struct ProviderEnableHeaderRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.title3.weight(.semibold))
                Text(self.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Toggle("Enabled", isOn: self.$isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .accessibilityLabel("Enabled")
        }
        .padding(.vertical, 4)
    }
}

private struct ProviderConnectionSection: View {
    @Binding var config: ProviderConfig

    var body: some View {
        Section("Connection") {
            Picker("Source", selection: self.$config.source) {
                ForEach(UsageSourcePreference.allCases, id: \.self) { source in
                    Text(source.title).tag(source)
                }
            }
            .help(self.config.source.settingsCaption)

            Picker("Cookie source", selection: self.$config.cookieSource) {
                ForEach(UsageSourcePreference.allCases, id: \.self) { source in
                    Text(source.title).tag(source)
                }
            }
            .help(self.config.cookieSource.settingsCaption)

            Toggle("Web extras", isOn: self.$config.dashboardExtrasEnabled)
            Text("Refresh dashboard adjuncts via a hidden local WKWebView with imported cookies. Costs battery.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProviderAuthenticationSection: View {
    @Bindable var model: ProviderFeatureModel
    @State private var diagnosticsExpanded = false
    @State private var actionInFlightID: String?

    var body: some View {
        Section("Authentication") {
            if let presentation = self.bannerPresentation {
                WindowIssueBanner(
                    issue: presentation,
                    onRetry: self.primaryAction.map { action in
                        { self.run(action) }
                    },
                    isRetrying: self.actionInFlightID != nil
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            } else {
                Text("Auth status not yet reported.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            let secondaryActions = self.secondaryActions
            if !secondaryActions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(secondaryActions) { action in
                        Button(self.displayLabel(for: action)) {
                            self.run(action)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(self.actionInFlightID != nil)
                    }
                    Spacer()
                }
            }

            DisclosureGroup("Diagnostics", isExpanded: self.$diagnosticsExpanded) {
                if let auth = self.model.authHealth {
                    if let loginMethod = auth.loginMethod {
                        LabeledContent("Login method", value: loginMethod)
                    }
                    if let backend = auth.credentialBackend {
                        LabeledContent(
                            "Credential store",
                            value: backend.replacingOccurrences(of: "-", with: " ")
                        )
                    }
                    if let authMode = auth.authMode,
                       authMode.lowercased() != (auth.loginMethod ?? "").lowercased() {
                        LabeledContent("Auth mode", value: authMode)
                    }
                    if let diagnostic = auth.diagnosticCode {
                        LabeledContent("Diagnostic", value: diagnostic)
                    }
                    LabeledContent("Status", value: self.statusValue(for: auth))
                        .help(self.statusTooltip(for: auth))
                    if let detail = self.model.projection.authDetail {
                        Text(detail)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .truncationMode(.middle)
                            .lineLimit(3)
                    }
                } else {
                    Text("No diagnostic data yet — try Refresh data on the Advanced tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var bannerPresentation: WindowHeaderIssuePresentation? {
        let projection = self.model.projection
        let auth = self.model.authHealth
        let providerTitle = self.model.provider.title

        if auth?.isAuthenticated == true,
           auth?.requiresRelogin != true,
           auth?.isSourceCompatible != false {
            return WindowHeaderIssuePresentation(
                tone: .pending,
                symbolName: "checkmark.seal.fill",
                badge: "Authentication",
                title: "\(providerTitle) is signed in",
                detail: auth?.loginMethod.map { "Login method: \($0)" },
                actionTitle: "Refresh",
                progressTitle: "Refreshing…"
            )
        }

        if let headline = projection.authHeadline {
            return WindowHeaderIssuePresentation(
                tone: auth?.isAuthenticated == true ? .warning : .warning,
                symbolName: "person.crop.circle.badge.exclamationmark",
                badge: "Authentication",
                title: headline,
                detail: self.model.missingCredentialDetail ?? projection.authDetail,
                actionTitle: self.primaryAction.map { self.displayLabel(for: $0) } ?? "Retry",
                progressTitle: "Working…"
            )
        }

        if auth == nil {
            return WindowHeaderIssuePresentation(
                tone: .pending,
                symbolName: "clock.fill",
                badge: "Authentication",
                title: "Waiting for helper",
                detail: "Auth status appears once the local helper completes its first check.",
                actionTitle: "Refresh",
                progressTitle: "Refreshing…"
            )
        }

        return nil
    }

    private var primaryAction: AuthRecoveryAction? {
        self.model.authRecoveryActions.first
    }

    private var secondaryActions: [AuthRecoveryAction] {
        Array(self.model.authRecoveryActions.dropFirst())
    }

    private func run(_ action: AuthRecoveryAction) {
        guard self.actionInFlightID == nil else { return }
        self.actionInFlightID = action.id
        Task {
            await self.model.runAuthRecoveryAction(action)
            self.actionInFlightID = nil
        }
    }

    private func displayLabel(for action: AuthRecoveryAction) -> String {
        switch action.actionID {
        case "claude-run": return "Open Claude Code"
        case "claude-login": return "Open Claude Code (then /login)"
        case "claude-doctor": return "Open Claude Code (then /doctor)"
        case "codex-login": return "Run Codex login"
        case "codex-login-device": return "Run Codex device login"
        default: return action.label
        }
    }

    private func statusValue(for auth: ProviderAuthHealth) -> String {
        if auth.isAuthenticated != true { return "Not authenticated" }
        if auth.requiresRelogin == true { return "Needs re-login" }
        if auth.isSourceCompatible != true { return "Source not compatible" }
        return "Healthy"
    }

    private func statusTooltip(for auth: ProviderAuthHealth) -> String {
        let yes = "Yes", no = "No"
        return "Authenticated: \(auth.isAuthenticated == true ? yes : no) · " +
            "Source compatible: \(auth.isSourceCompatible == true ? yes : no) · " +
            "Requires re-login: \(auth.requiresRelogin == true ? yes : no)"
    }
}

struct ProviderWebSessionSection: View {
    @Bindable var model: ProviderFeatureModel

    var body: some View {
        Section("Web session") {
            if let session = self.model.importedSession {
                LabeledContent("Status", value: self.statusLine(for: session))
                LabeledContent("Source", value: "\(session.browserSource.title) · \(session.profileName)")
                LabeledContent("Cookies", value: "\(session.cookies.count)")
                LabeledContent("Imported", value: session.importedAt)
                if !session.cookies.isEmpty {
                    LabeledContent("Domains", value: self.previewDomains(session))
                }
                Button("Reset \(self.model.provider.title) session") {
                    Task { await self.model.resetBrowserSession() }
                }
                .disabled(self.model.isImportingSession)
            } else {
                Text("No imported browser session stored.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if self.model.importCandidates.isEmpty {
                Text("No Safari, Chrome, Arc, or Brave cookie stores were discovered.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(self.model.importCandidates) { candidate in
                    Button("Import from \(candidate.title)") {
                        Task { await self.model.importBrowserSession(candidate: candidate) }
                    }
                    .disabled(self.model.isImportingSession)
                }
            }
        }
    }

    private func statusLine(for session: ImportedBrowserSession) -> String {
        if session.expired { return "Expired" }
        if session.loginRequired { return "Missing auth cookie" }
        return "Ready"
    }

    private func previewDomains(_ session: ImportedBrowserSession) -> String {
        let domains = Array(Set(session.cookies.map(\.domain))).sorted()
        return domains.prefix(3).joined(separator: ", ")
    }
}

// MARK: - Cloud Sync

private struct SettingsCloudSyncTab: View {
    @Bindable var model: SettingsFeatureModel

    var body: some View {
        Form {
            Section("Cloud Sync") {
                Text(self.model.cloudSyncStatusLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                LabeledContent("Installation ID") {
                    Text(self.model.sessionStore.installationID)
                        .font(.caption.monospaced())
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
                if let shareURL = self.model.cloudSyncState.shareURL {
                    LabeledContent("Share link") {
                        Text(shareURL)
                            .font(.caption.monospaced())
                            .truncationMode(.middle)
                            .lineLimit(1)
                            .textSelection(.enabled)
                    }
                }
                if let aggregate = self.model.cloudSyncAggregate {
                    LabeledContent("Synced installations", value: "\(aggregate.installations.count)")
                    LabeledContent(
                        "Aggregate 90-day tokens",
                        value: "\(aggregate.aggregateTotals.last90DaysTokens)"
                    )
                }

                HStack(spacing: 8) {
                    Button("Refresh Cloud Sync") {
                        Task { await self.model.refreshCloudSyncState() }
                    }
                    if self.model.cloudSyncState.role != .participant {
                        Button("Create / copy share link") {
                            Task { await self.model.prepareCloudShare() }
                        }
                    }
                    Spacer()
                }
            }

            #if DEBUG
            CloudSyncDiagnosticsSection(diagnostics: self.model.cloudSyncDiagnostics)
            #endif

            SettingsSaveActionSection(model: self.model)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Advanced

private struct SettingsAdvancedTab: View {
    @Bindable var model: SettingsFeatureModel

    var body: some View {
        Form {
            Section("Web Extras Policy") {
                Text("OpenAI web extras use a hidden local WKWebView with imported browser cookies. Refreshes are cached and rate-limited, but they still cost battery and expose your local browser session to this app on this machine only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Maintenance") {
                Button("Refresh data") {
                    Task { await self.model.refreshAll() }
                }
                Button("Refresh browser discovery") {
                    Task { await self.model.refreshBrowserImports() }
                }
            }

            SettingsSaveActionSection(model: self.model)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Save row (shared across tabs)

private struct SettingsSaveActionSection: View {
    @Bindable var model: SettingsFeatureModel

    var body: some View {
        Section {
            HStack(spacing: 10) {
                Button("Save settings") {
                    Task { await self.model.save() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(self.model.saveStatus == .saving)

                if let label = self.statusLabel {
                    Text(label)
                        .font(.caption.monospaced())
                        .foregroundStyle(self.statusColor)
                        .transition(.opacity)
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.15), value: self.model.saveStatus)
        }
    }

    private var statusLabel: String? {
        switch self.model.saveStatus {
        case .idle: return nil
        case .saving: return "[SAVING…]"
        case .saved: return "[SAVED]"
        case .error(let message): return "[ERROR: \(message)]"
        }
    }

    private var statusColor: Color {
        switch self.model.saveStatus {
        case .idle, .saving: return .secondary
        case .saved: return .accentInteractive
        case .error: return .accentError
        }
    }
}
