import Foundation

/// Whether Touch ID is wired into `sudo` via PAM.
public enum TouchIDSudoStatus: Sendable, Equatable {
    /// `pam_tid.so` is configured (in `sudo_local` or `sudo`).
    case enabled
    /// PAM is present but Touch ID is not configured.
    case notConfigured
    /// Could not determine (files unreadable, etc.).
    case unknown
}

/// Read-only detection of the host's `sudo` Touch ID configuration.
///
/// Relay only *detects and guides* — it never edits PAM configuration. (Guidance UI lands in
/// Milestone 6; this detector is the underlying, side-effect-free primitive.)
public struct SudoDetector: Sendable {

    public init() {}

    /// Detects whether `sudo` is configured to accept Touch ID.
    ///
    /// macOS 14+ keeps a persistent `sudo_local` for this; older systems edit `sudo` directly.
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
                guard !trimmed.hasPrefix("#") else { continue }     // ignore comments
                if trimmed.contains("pam_tid.so") { return .enabled }
            }
        }

        return sawAnyFile ? .notConfigured : .unknown
    }

    /// Whether a Touch ID-capable sensor is present (best-effort, expanded in Milestone 6).
    public func hasTouchIDHardware() -> Bool {
        // Real LAContext-based probing is added in Milestone 6.
        false
    }
}
