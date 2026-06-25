import Foundation
import UserNotifications

/// The categories of notification Relay posts.
public enum RelayNotification: Sendable, Equatable {
    case completed(title: String, body: String)
    case failed(title: String, body: String)
    case cancelled(title: String, body: String)
    case warning(title: String, body: String)

    var title: String {
        switch self {
        case let .completed(t, _), let .failed(t, _), let .cancelled(t, _), let .warning(t, _): return t
        }
    }

    var body: String {
        switch self {
        case let .completed(_, b), let .failed(_, b), let .cancelled(_, b), let .warning(_, b): return b
        }
    }
}

/// Posts native notifications for command/task outcomes.
public protocol NotificationPosting: Sendable {
    func requestAuthorization() async
    func post(_ notification: RelayNotification) async
}

/// Default notification service backed by `UNUserNotificationCenter`.
///
/// All calls are best-effort and fail silently: notifications are a convenience, never a
/// correctness requirement, and the center is unavailable in non-bundled contexts (e.g. tests).
public struct NotificationService: NotificationPosting {

    public init() {}

    private var center: UNUserNotificationCenter? {
        // `current()` traps when there is no main bundle id (unit tests, CLI). Guard for it.
        Bundle.main.bundleIdentifier == nil ? nil : .current()
    }

    public func requestAuthorization() async {
        guard let center else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    public func post(_ notification: RelayNotification) async {
        guard let center else { return }

        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = notification.isFailure ? .defaultCritical : .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}

private extension RelayNotification {
    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}
