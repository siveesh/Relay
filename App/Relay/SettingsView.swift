import SwiftUI
import RelaySecurity

/// The app's settings window: General and Security panes.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            SecuritySettingsView()
                .tabItem { Label("Security", systemImage: "lock.shield") }
        }
        .frame(width: 480, height: 360)
    }
}

private struct GeneralSettingsView: View {
    @AppStorage(AppDelegate.showDockIconKey) private var showDockIcon = false
    @State private var hotKeyPref = HotKeyPreference.load()

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show icon in Dock", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { _, newValue in
                        NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                    }
                LabeledContent("Global Shortcut") {
                    HotKeyRecorderView(preference: $hotKeyPref)
                }
            }
            Section("About") {
                LabeledContent("Version", value: bundleString("CFBundleShortVersionString"))
                LabeledContent("Build", value: bundleString("CFBundleVersion"))
            }
        }
        .formStyle(.grouped)
    }

    private func bundleString(_ key: String) -> String {
        Bundle.main.infoDictionary?[key] as? String ?? "—"
    }
}

private struct SecuritySettingsView: View {
    @State private var model = SecurityModel()

    var body: some View {
        Form {
            Section("Touch ID for sudo") {
                LabeledContent("Touch ID hardware") {
                    StatusPill(ok: model.touchIDHardware,
                               text: model.touchIDHardware ? "Available" : "Not available")
                }
                LabeledContent("sudo configuration") {
                    sudoStatusPill
                }

                if model.touchIDHardware, model.sudoStatus != .enabled {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Relay never changes your sudo configuration. To enable Touch ID for sudo, run this once in Terminal:")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text(model.enableGuidanceCommand)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(2)
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(model.enableGuidanceCommand, forType: .string)
                            } label: { Image(systemName: "doc.on.doc") }
                            .buttonStyle(.plain)
                            .help("Copy")
                        }
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            Section("Privileged Helper") {
                LabeledContent("Status") {
                    StatusPill(ok: model.helperStatus == .enabled, text: helperStatusText)
                }
                Text("For built-in privileged actions Relay uses a signed helper that exposes only a fixed set of curated operations — never arbitrary commands.")
                    .font(.caption).foregroundStyle(.secondary)
                if model.helperStatus == .notFound {
                    Text("The helper executable is not included in this build. It ships in the signed release version of Relay.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Button("Install Helper…") { model.installHelper() }
                }
                if let message = model.message {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { model.refresh() }
    }

    private var sudoStatusPill: some View {
        switch model.sudoStatus {
        case .enabled: return StatusPill(ok: true, text: "Enabled")
        case .notConfigured: return StatusPill(ok: false, text: "Not configured")
        case .unknown: return StatusPill(ok: false, text: "Unknown")
        }
    }

    private var helperStatusText: String {
        switch model.helperStatus {
        case .enabled: return "Enabled"
        case .requiresApproval: return "Requires approval"
        case .notRegistered: return "Not installed"
        case .notFound: return "Not installed"
        }
    }
}

private struct StatusPill: View {
    let ok: Bool
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ok ? Color.green : Color.orange)
            Text(text)
        }
        .font(.callout)
    }
}
