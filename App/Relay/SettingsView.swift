import SwiftUI

/// The app's settings window. Minimal for Milestone 1 — grows alongside features.
struct SettingsView: View {

    @AppStorage(AppDelegate.showDockIconKey) private var showDockIcon = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show icon in Dock", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { _, newValue in
                        NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                    }
                LabeledContent("Global Shortcut", value: "⌥ Space")
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: buildNumber)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 260)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
