import Foundation
import LocalAuthentication

/// Whether Touch ID is wired into `sudo` via PAM.
public enum TouchIDSudoStatus: Sendable, Equatable {
    /// `pam_tid.so` is configured (in `sudo_local` or `sudo`).
    case enabled
    /// PAM is present but Touch ID is not configured.
    case notConfigured
    /// Could not determine (files unreadable, etc.).
    case unknown
}

/// Read-only detection of the host's Touch ID hardware and `sudo` configuration.
///
/// Relay only *detects and guides* — it never edits PAM configuration. (Guidance UI lives in
/// the app; this detector is the underlying, side-effect-free primitive.)
public struct SudoDetector: Sendable {

    public init() {}

    /// The shell snippet a user can run to enable Touch ID for `sudo` (macOS 14+).
    /// Relay shows this as guidance; it never runs it automatically.
    public static let enableGuidanceCommand =
        "echo 'auth       sufficient     pam_tid.so' | sudo tee /etc/pam.d/sudo_local"

    /// Detects whether `sudo` is configured to accept Touch ID.
    public func touchIDStatus() -> TouchIDSudoStatus {
        let candidates = ["/etc/pam.d/sudo_local", "/etc/pam.d/sudo"]
        var sawAnyFile = false

        for path in candidates {
            guard FileManager.default.fileExists(atPath: path),
                  let contents = try? String(contentsOfFile: path, encoding: .utf8)
            else { continue }
            sawAnyFile = true

            for line in contents.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("#") else { continue }
                if trimmed.contains("pam_tid.so") { return .enabled }
            }
        }

        return sawAnyFile ? .notConfigured : .unknown
    }

    /// Whether a Touch ID sensor is present and enrolled, via `LAContext`.
    public func hasTouchIDHardware() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canUseBiometrics && context.biometryType == .touchID
    }
}
