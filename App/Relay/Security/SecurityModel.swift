import Foundation
import Observation
import RelaySecurity

/// Observable view model for the security settings: Touch ID detection and the privileged helper.
@MainActor
@Observable
final class SecurityModel {

    private let detector = SudoDetector()
    private let helper: any PrivilegedHelperClient = ServiceManagementHelperClient()

    var touchIDHardware = false
    var sudoStatus: TouchIDSudoStatus = .unknown
    var helperStatus: HelperStatus = .notRegistered
    var message: String?

    var enableGuidanceCommand: String { SudoDetector.enableGuidanceCommand }

    func refresh() {
        touchIDHardware = detector.hasTouchIDHardware()
        sudoStatus = detector.touchIDStatus()
        helperStatus = helper.status
    }

    func performOperation(_ operation: PrivilegedOperation) {
        guard let command = operation.elevatedShellCommand else {
            message = "\(operation.summary) requires parameters — add it as a command with 'Requires Elevation' enabled."
            return
        }
        message = nil
        Task {
            let (ok, output) = await Self.runElevated(command)
            message = ok ? "✓ \(operation.summary) completed." : "Failed: \(output)"
        }
    }

    private static func runElevated(_ command: String) async -> (Bool, String) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let escaped = command
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let script = "do shell script \"\(escaped)\" with administrator privileges"
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                let pipe = Pipe()
                process.standardError = pipe
                do {
                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 {
                        continuation.resume(returning: (true, ""))
                    } else {
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let out = String(data: data, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(returning: (false, out.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                } catch {
                    continuation.resume(returning: (false, error.localizedDescription))
                }
            }
        }
    }

    func installHelper() {
        do {
            try helper.install()
            message = "Helper registration requested. Approve it in System Settings ▸ Login Items if prompted."
        } catch let error as PrivilegedHelperError {
            message = describe(error)
        } catch {
            message = error.localizedDescription
        }
        refresh()
    }

    private func describe(_ error: PrivilegedHelperError) -> String {
        switch error {
        case .notInstalled:
            return "The helper is not installed."
        case let .registrationFailed(reason):
            if reason.localizedCaseInsensitiveContains("unable to read plist") {
                return "The helper launch daemon plist is missing from the app bundle. Rebuild the app from Xcode to include it."
            }
            if reason.localizedCaseInsensitiveContains("not found") || reason.localizedCaseInsensitiveContains("notFound") {
                return "The helper executable is not bundled in this build. The privileged helper ships in a signed release build."
            }
            return "Registration failed: \(reason)"
        case let .operationFailed(reason):
            return "Operation failed: \(reason)"
        case .unavailable:
            return "The helper executable ships in a signed release build."
        }
    }
}
