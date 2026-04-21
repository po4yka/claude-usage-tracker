import Foundation
import HeimdallDomain

public final class AuthCoordinator: Sendable {
    private let runner: any AuthCommandRunning

    public init(runner: any AuthCommandRunning) {
        self.runner = runner
    }

    public func recoveryActions(
        for provider: ProviderID,
        projection: ProviderMenuProjection
    ) -> [AuthRecoveryAction] {
        if !projection.authRecoveryActions.isEmpty {
            return projection.authRecoveryActions
        }
        return self.defaultAuthRecoveryActions(for: provider)
    }

    public func primaryAction(
        for provider: ProviderID,
        projection: ProviderMenuProjection
    ) -> AuthRecoveryAction? {
        self.recoveryActions(for: provider, projection: projection).first
    }

    public func run(
        _ action: AuthRecoveryAction,
        provider: ProviderID
    ) throws {
        guard let launch = self.recoveryLaunch(for: action.actionID, provider: provider) else {
            throw AuthCoordinatorError.unsupportedRecoveryAction(provider, action.actionID)
        }
        try self.runner.runAuthCommand(provider: provider, title: launch.title, command: launch.command)
    }

    public func defaultCommand(
        for action: AuthRecoveryAction,
        provider: ProviderID
    ) -> String {
        if let launch = self.recoveryLaunch(for: action.actionID, provider: provider) {
            return launch.command
        }
        switch (provider, action.actionID) {
        case (.claude, _):
            return "claude"
        case (.codex, "codex-login-device"):
            return "codex login --device-auth"
        case (.codex, _):
            return "codex login"
        }
    }

    private func defaultAuthRecoveryActions(for provider: ProviderID) -> [AuthRecoveryAction] {
        switch provider {
        case .claude:
            return [
                AuthRecoveryAction(
                    label: "Run Claude Login",
                    actionID: "claude-login",
                    command: "claude",
                    detail: "Open Claude Code and type /login at the prompt to restore the subscription OAuth."
                ),
                AuthRecoveryAction(
                    label: "Run Claude Doctor",
                    actionID: "claude-doctor",
                    command: "claude",
                    detail: "Open Claude Code and type /doctor at the prompt to diagnose credential, keychain, and environment problems."
                ),
            ]
        case .codex:
            return [
                AuthRecoveryAction(
                    label: "Run Codex Login",
                    actionID: "codex-login",
                    command: "codex login",
                    detail: "Run Codex login to restore ChatGPT-backed auth."
                ),
                AuthRecoveryAction(
                    label: "Run Device Login",
                    actionID: "codex-login-device",
                    command: "codex login --device-auth",
                    detail: "Use device auth when localhost callback login is blocked or headless."
                ),
            ]
        }
    }

    private struct RecoveryLaunch {
        var title: String
        var command: String
    }

    private func recoveryLaunch(
        for actionID: String,
        provider: ProviderID
    ) -> RecoveryLaunch? {
        switch (provider, actionID) {
        case (.claude, "claude-run"):
            return RecoveryLaunch(title: "Run Claude", command: "claude")
        case (.claude, "claude-login"):
            return RecoveryLaunch(
                title: "Claude Login — type /login at the prompt",
                command: "claude"
            )
        case (.claude, "claude-doctor"):
            return RecoveryLaunch(
                title: "Claude Doctor — type /doctor at the prompt",
                command: "claude"
            )
        case (.codex, "codex-login"):
            return RecoveryLaunch(title: "Run Codex Login", command: "codex login")
        case (.codex, "codex-login-device"):
            return RecoveryLaunch(title: "Run Device Login", command: "codex login --device-auth")
        default:
            return nil
        }
    }
}

public enum AuthCoordinatorError: Error, LocalizedError {
    case unsupportedRecoveryAction(ProviderID, String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedRecoveryAction(let provider, _):
            return "Unsupported \(provider.title) auth recovery action."
        }
    }
}
