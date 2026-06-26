import SwiftUI
import RelaySecurity

/// The app's settings window: General, Variables, Security, and Data panes.
struct SettingsView: View {
    let environment: AppEnvironment

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            CustomVariablesView()
                .tabItem { Label("Variables", systemImage: "dollarsign.circle") }
            SecuritySettingsView()
                .tabItem { Label("Security", systemImage: "lock.shield") }
            DataSettingsView(environment: environment)
                .tabItem { Label("Data", systemImage: "externaldrive") }
        }
        .frame(width: 520, height: 460)
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

// MARK: - Custom Variables

/// Editor for user-defined Relay variables ($NAS, $CurrentProject, etc.).
/// Values are persisted in UserDefaults and injected into VariableResolver at launch.
private struct CustomVariablesView: View {

    static let userDefaultsKey = "relay.customVariables"

    @State private var entries: [VarEntry] = CustomVariablesView.load()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    ForEach(Array(entries.enumerated()), id: \.offset) { index, _ in
                        HStack(spacing: 6) {
                            Text("$").foregroundStyle(.secondary).font(.system(.body, design: .monospaced))
                            TextField("NAME", text: $entries[index].key)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: 130)
                            Text("=").foregroundStyle(.secondary)
                            TextField("value or path", text: $entries[index].value)
                            Button(role: .destructive) {
                                entries.remove(at: index)
                                save()
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        entries.append(VarEntry(key: "", value: ""))
                    } label: {
                        Label("Add Variable", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Custom Variables")
                } footer: {
                    Text("Use **$NAME** in any command, working directory, or environment value. Built-ins like $Desktop and $Clipboard are always available and cannot be overridden here.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .onChange(of: entries) { _, _ in save() }

            Divider()
            HStack {
                Spacer()
                Text("Changes apply to new executions immediately.")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
        }
    }

    // MARK: Persistence

    private static func load() -> [VarEntry] {
        guard let dict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] else {
            return [
                VarEntry(key: "NAS", value: "/Volumes/NAS"),
                VarEntry(key: "CurrentProject", value: "~/Developer"),
            ]
        }
        return dict.sorted { $0.key < $1.key }.map { VarEntry(key: $0.key, value: $0.value) }
    }

    private func save() {
        var dict: [String: String] = [:]
        for entry in entries where !entry.key.trimmingCharacters(in: .whitespaces).isEmpty {
            dict[entry.key.trimmingCharacters(in: .whitespaces)] = entry.value
        }
        UserDefaults.standard.set(dict, forKey: Self.userDefaultsKey)
        // Notify AppEnvironment so the running VariableResolver picks up the change.
        NotificationCenter.default.post(name: .customVariablesDidChange, object: dict)
    }
}

private struct VarEntry: Equatable {
    var key: String
    var value: String
}

extension Notification.Name {
    static let customVariablesDidChange = Notification.Name("relay.customVariablesDidChange")
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
                Text("Relay uses a signed helper that exposes only these curated operations — never arbitrary commands.")
                    .font(.caption).foregroundStyle(.secondary)

                PrivilegedOperationsGrid()

                switch model.helperStatus {
                case .notRegistered:
                    Button("Install Helper…") { model.installHelper() }
                case .requiresApproval:
                    VStack(alignment: .leading, spacing: 4) {
                        Button("Install Helper…") { model.installHelper() }
                        Text("Approve the helper in System Settings ▸ General ▸ Login Items.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                case .enabled:
                    EmptyView()
                case .notFound:
                    Text("The helper executable is not bundled in this build. It ships in the signed release version of Relay.")
                        .font(.caption).foregroundStyle(.secondary)
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
        case .enabled:          return "Enabled"
        case .requiresApproval: return "Requires approval"
        case .notRegistered:    return "Not installed"
        case .notFound:         return "Not available in this build"
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

/// Grid showing every curated privileged operation the helper can perform.
private struct PrivilegedOperationsGrid: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(PrivilegedOperation.allCases, id: \.self) { op in
                VStack(spacing: 6) {
                    Image(systemName: op.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                    Text(op.summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }
}
