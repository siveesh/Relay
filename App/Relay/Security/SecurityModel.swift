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
        case .notInstalled: return "The helper is not installed."
        case let .registrationFailed(reason): return "Registration failed: \(reason)"
        case let .operationFailed(reason): return "Operation failed: \(reason)"
        case .unavailable: return "The helper executable ships in a later build."
        }
    }
}
