import Foundation

/// The categories of notification Relay posts.
public enum RelayNotification: Sendable, Equatable {
    case completed(title: String, body: String)
    case failed(title: String, body: String)
    case cancelled(title: String, body: String)
    case warning(title: String, body: String)
}

/// Posts native notifications for command/task outcomes.
public protocol NotificationPosting: Sendable {
    func requestAuthorization() async
    func post(_ notification: RelayNotification) async
}

/// Default notification service.
///
/// > Milestone note: the concrete `UserNotifications` (`UNUserNotificationCenter`) integration
/// > requires a real app bundle and lands in Milestone 3. This M1 type establishes the
/// > protocol the app depends on.
public struct NotificationService: NotificationPosting {
    public init() {}
    public func requestAuthorization() async {}
    public func post(_ notification: RelayNotification) async { _ = notification }
}
