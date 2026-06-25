import Foundation

extension RelayCommand {
    /// In-memory seed data used until JSON persistence is wired up (Milestone 2).
    /// Mirrors the starter command pack shipped in the project package.
    public static let samples: [RelayCommand] = [
        RelayCommand(
            name: "Start LM Studio",
            details: "Launch LM Studio.",
            category: "AI",
            icon: "brain",
            tags: ["ai", "llm", "lmstudio"],
            aliases: ["lm", "start lm"],
            command: "open -a 'LM Studio'",
            timeoutSeconds: 30,
            runInBackground: true,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Tailscale Status",
            details: "Show Tailscale connection status.",
            category: "Network",
            icon: "network",
            tags: ["tailscale", "vpn", "network"],
            aliases: ["ts status"],
            command: "tailscale status",
            timeoutSeconds: 20,
            favorite: true
        ),
        RelayCommand(
            name: "Flush DNS Cache",
            details: "Flush macOS DNS cache. Requires sudo.",
            category: "System",
            icon: "globe",
            tags: ["dns", "network", "system"],
            aliases: ["dns flush"],
            command: "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder",
            timeoutSeconds: 60,
            requiresConfirmation: true,
            requiresElevation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Show Disk Usage",
            details: "Human-readable disk usage for mounted volumes.",
            category: "System",
            icon: "internaldrive",
            tags: ["disk", "storage", "system"],
            aliases: ["df"],
            command: "df -h",
            timeoutSeconds: 15
        ),
        RelayCommand(
            name: "Git Status",
            details: "Show git status for the current project.",
            category: "Development",
            icon: "arrow.triangle.branch",
            tags: ["git", "dev", "vcs"],
            aliases: ["gs"],
            workingDirectory: "~",
            command: "git status",
            timeoutSeconds: 15
        ),
    ]
}
