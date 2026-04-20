import Foundation

public actor HeimdallHelperController {
    private var process: Process?

    public init() {}

    public func ensureServerRunning(port: Int) async {
        if let process, process.isRunning {
            return
        }

        guard let executable = self.resolveExecutable() else {
            return
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = [
            "dashboard",
            "--host", "127.0.0.1",
            "--port", "\(port)",
            "--watch",
            "--no-open",
            "--background-poll",
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            self.process = process
        } catch {
            return
        }
    }

    private func resolveExecutable() -> URL? {
        let bundle = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("claude-usage-tracker", isDirectory: false)
        if FileManager.default.isExecutableFile(atPath: bundle.path) {
            return bundle
        }

        let env = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for path in env.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(path)).appendingPathComponent("claude-usage-tracker")
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
