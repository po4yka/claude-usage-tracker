import Darwin
import Foundation
import HeimdallBarShared

enum CLIError: Error {
    case invalidArguments(String)
}

struct HeimdallBarCLI {
    static func main() async {
        do {
            try await self.run(arguments: CommandLine.arguments)
        } catch {
            fputs("\(error)\n", stderr)
            Darwin.exit(1)
        }
    }

    static func run(arguments: [String]) async throws {
        let command = arguments.dropFirst().first ?? "usage"
        switch command {
        case "usage":
            try await self.runUsage(arguments: Array(arguments.dropFirst()))
        case "cost":
            try await self.runCost(arguments: Array(arguments.dropFirst()))
        case "config":
            try self.runConfig(arguments: Array(arguments.dropFirst()))
        default:
            throw CLIError.invalidArguments("unknown command: \(command)")
        }
    }

    private static func runUsage(arguments: [String]) async throws {
        let config = ConfigStore.shared.load()
        let client = HeimdallAPIClient(port: config.helperPort)
        let envelope = try await client.fetchSnapshots()
        let encoder = JSONEncoder()
        encoder.outputFormatting = arguments.contains("--pretty") ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase

        if arguments.contains("--format"), arguments.contains("json") || arguments.contains("--pretty") {
            let data = try encoder.encode(envelope)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
            return
        }

        for snapshot in envelope.providers {
            let title = snapshot.provider.capitalized
            print("== \(title) (\(snapshot.sourceUsed)) ==")
            if let primary = snapshot.primary {
                print("Session: \(Int((100 - primary.usedPercent).rounded()))% left")
            }
            if let secondary = snapshot.secondary {
                print("Weekly: \(Int((100 - secondary.usedPercent).rounded()))% left")
            }
            if let credits = snapshot.credits, !arguments.contains("--no-credits") {
                print("Credits: \(String(format: "%.2f", credits))")
            }
            print("Today: $\(String(format: "%.2f", snapshot.costSummary.todayCostUSD))")
            print("")
        }
    }

    private static func runCost(arguments: [String]) async throws {
        let config = ConfigStore.shared.load()
        let client = HeimdallAPIClient(port: config.helperPort)
        let provider = arguments.contains("--provider") && arguments.contains("codex") ? ProviderID.codex : ProviderID.claude
        let summary = try await client.fetchCostSummary(provider: provider)
        let encoder = JSONEncoder()
        encoder.outputFormatting = arguments.contains("--pretty") ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(summary)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    private static func runConfig(arguments: [String]) throws {
        let store = ConfigStore.shared
        if arguments.dropFirst().first == "validate" {
            try store.validate()
            print("valid")
            return
        }
        if arguments.dropFirst().first == "dump" {
            let config = store.load()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(config)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
            return
        }
        throw CLIError.invalidArguments("config expects validate or dump")
    }
}

do {
    try await HeimdallBarCLI.run(arguments: CommandLine.arguments)
} catch {
    fputs("\(error)\n", stderr)
    Darwin.exit(1)
}
