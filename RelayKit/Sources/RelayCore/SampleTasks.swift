import Foundation

extension RelayTask {
    /// In-memory seed workflow shown on first run to illustrate the task runner.
    public static let samples: [RelayTask] = [
        RelayTask(
            name: "Project Kickoff",
            details: "Open the project folder and show git status.",
            icon: "play.rectangle.on.rectangle",
            steps: [
                TaskStep(kind: .notify(title: "Relay", body: "Starting kickoff…")),
                TaskStep(kind: .shell(command: "cd $Home && git --version", shell: "zsh")),
                TaskStep(kind: .delay(seconds: 0.5)),
                TaskStep(kind: .notify(title: "Relay", body: "Kickoff complete.")),
            ],
            stopOnFailure: true
        )
    ]
}
