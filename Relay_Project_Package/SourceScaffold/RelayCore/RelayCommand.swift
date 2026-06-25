import Foundation

public struct RelayCommand: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var description: String
    public var category: String
    public var icon: String
    public var tags: [String]
    public var aliases: [String]
    public var shell: String
    public var workingDirectory: String
    public var environment: [String: String]
    public var command: String
    public var timeoutSeconds: Int
    public var requiresConfirmation: Bool
    public var requiresElevation: Bool
    public var runInBackground: Bool
    public var captureOutput: Bool
    public var notifyOnCompletion: Bool
    public var favorite: Bool
}
