import Foundation

extension RelayTask {
    /// Sample workflows seeded on first run, mirroring the spec sheet examples.
    public static let samples: [RelayTask] = [
        aiEnvironmentReady,
        morningSetup,
        dockerDeploy,
    ]

    // MARK: - AI Environment Ready (spec sheet example)

    /// The canonical example from the Relay spec — boots the full AI dev stack.
    static let aiEnvironmentReady = RelayTask(
        name: "AI Environment Ready",
        details: "Start Tailscale, mount NAS, launch LM Studio, wait for the API, open editors, and notify.",
        icon: "brain.circuit",
        steps: [
            TaskStep(kind: .shell(command: "tailscale up", shell: "zsh")),
            TaskStep(kind: .shell(command: "mkdir -p $NAS && mount -t smbfs //guest@nas.local/shared $NAS", shell: "zsh"),
                     continueOnError: true),
            TaskStep(kind: .shell(command: "open -a 'LM Studio'", shell: "zsh")),
            TaskStep(kind: .httpHealthCheck(url: "http://localhost:1234/v1/models", expectedStatus: 200)),
            TaskStep(kind: .launchApp(bundleIdentifier: "com.todesktop.230313mzl4w4u92")),   // Cursor / Codex
            TaskStep(kind: .launchApp(bundleIdentifier: "com.microsoft.VSCode")),
            TaskStep(kind: .notify(title: "Relay", body: "AI Environment Ready ✓")),
        ],
        stopOnFailure: false,
        favorite: true
    )

    // MARK: - Morning Setup

    static let morningSetup = RelayTask(
        name: "Morning Setup",
        details: "Connect to the network, pull latest code, and open the daily workspace.",
        icon: "sunrise",
        steps: [
            TaskStep(kind: .notify(title: "Relay", body: "Starting morning setup…")),
            TaskStep(kind: .shell(command: "tailscale up", shell: "zsh"), continueOnError: true),
            TaskStep(kind: .shell(command: "cd $CurrentProject && git pull --rebase origin HEAD", shell: "zsh"),
                     continueOnError: true),
            TaskStep(kind: .shell(command: "brew update && brew upgrade --quiet", shell: "zsh"),
                     continueOnError: true),
            TaskStep(kind: .launchApp(bundleIdentifier: "com.microsoft.VSCode")),
            TaskStep(kind: .notify(title: "Relay", body: "Morning setup complete.")),
        ],
        stopOnFailure: false
    )

    // MARK: - Docker Deploy

    static let dockerDeploy = RelayTask(
        name: "Docker Deploy",
        details: "Pull latest images, restart compose services, and verify containers are healthy.",
        icon: "shippingbox.fill",
        steps: [
            TaskStep(kind: .notify(title: "Relay", body: "Starting deployment…")),
            TaskStep(kind: .shell(command: "cd $CurrentProject && git pull --rebase origin HEAD", shell: "zsh")),
            TaskStep(kind: .shell(command: "cd $CurrentProject && docker compose pull", shell: "zsh")),
            TaskStep(kind: .shell(command: "cd $CurrentProject && docker compose up -d --remove-orphans", shell: "zsh")),
            TaskStep(kind: .delay(seconds: 3)),
            TaskStep(kind: .shell(command: "docker ps --filter status=running --format '{{.Names}}: {{.Status}}'", shell: "zsh")),
            TaskStep(kind: .notify(title: "Relay", body: "Deployment complete ✓")),
        ],
        stopOnFailure: true
    )
}
