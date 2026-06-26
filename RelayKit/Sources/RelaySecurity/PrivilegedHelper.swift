import Foundation
import ServiceManagement

/// The **fixed, curated** set of privileged operations Relay's helper may perform.
///
/// This is the cornerstone of Relay's privileged-helper security model: the helper exposes
/// *only* these predefined operations over XPC. It must **never** accept an arbitrary command
/// string or shell — that would turn the helper into a root-level remote shell. Adding a new
/// capability means adding a case here and implementing it explicitly inside the helper.
public enum PrivilegedOperation: String, Codable, Sendable, CaseIterable {
    case flushDNSCache
    case renewDHCPLease
    case repairPermissions
    case restartService
    case mountProtectedPath
    case editProtectedFile

    /// Human-readable description shown in the UI before the user authorizes the action.
    public var summary: String {
        switch self {
        case .flushDNSCache:      return "Flush the system DNS cache"
        case .renewDHCPLease:     return "Renew the primary network DHCP lease"
        case .repairPermissions:  return "Repair file permissions on system directories"
        case .restartService:     return "Restart a launchd system service"
        case .mountProtectedPath: return "Mount a volume at a protected path"
        case .editProtectedFile:  return "Write to a protected system configuration file"
        }
    }

    /// SF Symbol for display in the privileged-operations grid.
    public var icon: String {
        switch self {
        case .flushDNSCache:      return "globe.badge.chevron.backward"
        case .renewDHCPLease:     return "arrow.triangle.2.circlepath"
        case .repairPermissions:  return "lock.rotation"
        case .restartService:     return "arrow.clockwise.circle"
        case .mountProtectedPath: return "externaldrive.badge.plus"
        case .editProtectedFile:  return "pencil.and.list.clipboard"
        }
    }
}

/// Errors surfaced by the helper client.
public enum PrivilegedHelperError: Error, Sendable, Equatable {
    case notInstalled
    case registrationFailed(String)
    case operationFailed(String)
    /// The XPC connection to the helper is not available in this build.
    case unavailable
}

/// Installation/registration state of the privileged helper.
public enum HelperStatus: Sendable, Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

/// Client for Relay's privileged helper.
///
/// Implementations talk to a signed `SMAppService` daemon over XPC. The helper validates the
/// connecting client's code-signing requirement and only ever runs the curated operations above.
public protocol PrivilegedHelperClient: Sendable {
    var status: HelperStatus { get }
    func install() throws
    func perform(_ operation: PrivilegedOperation) async throws
}

/// `ServiceManagement`-based client.
///
/// > Milestone note: M6 establishes the architecture and the registration/status surface using
/// > `SMAppService`. The companion helper executable and its XPC service are a packaging step
/// > (separate signed target + `Contents/Library/LaunchDaemons` plist) that cannot be exercised
/// > in an unsigned local build, so `perform` reports `.unavailable` until the helper ships.
public struct ServiceManagementHelperClient: PrivilegedHelperClient {

    /// Mach service name the helper would vend (must match the helper's `Info.plist`).
    public static let machServiceName = "com.relay.app.helper"
    /// LaunchDaemon plist name bundled at `Contents/Library/LaunchDaemons/<name>`.
    public static let daemonPlistName = "com.relay.app.helper.plist"

    public init() {}

    private var service: SMAppService {
        SMAppService.daemon(plistName: Self.daemonPlistName)
    }

    public var status: HelperStatus {
        switch service.status {
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notRegistered: return .notRegistered
        case .notFound: return .notFound
        @unknown default: return .notFound
        }
    }

    public func install() throws {
        do {
            try service.register()
        } catch {
            throw PrivilegedHelperError.registrationFailed(error.localizedDescription)
        }
    }

    public func perform(_ operation: PrivilegedOperation) async throws {
        // Real implementation: open an NSXPCConnection to `machServiceName`, set the remote
        // interface to the helper protocol, validate the listener's code-signing requirement,
        // and invoke the matching curated method. The helper performs the operation itself —
        // no shell string ever crosses the boundary.
        guard status == .enabled else { throw PrivilegedHelperError.notInstalled }
        throw PrivilegedHelperError.unavailable
    }
}
