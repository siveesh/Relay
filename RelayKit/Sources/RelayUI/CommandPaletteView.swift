import SwiftUI
import RelayCore

/// The Spotlight-style command palette. A keyboard-first, Liquid Glass surface for searching
/// and launching commands.
///
/// The view is intentionally "dumb": all state lives in `CommandPaletteModel`, and the host
/// app supplies the `onRun` / `onDismiss` behaviours.
public struct CommandPaletteView: View {

    @State private var model: CommandPaletteModel
    private let onRun: (RelayCommand) -> Void
    private let onDismiss: () -> Void

    @FocusState private var searchFocused: Bool

    public init(
        model: CommandPaletteModel,
        onRun: @escaping (RelayCommand) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _model = State(initialValue: model)
        self.onRun = onRun
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 0) {
                searchField
                if !model.results.isEmpty {
                    Divider().opacity(0.4)
                    resultsList
                } else {
                    emptyState
                }
            }
        }
        .frame(width: RelayTheme.Metrics.paletteWidth)
        .glassEffect(.regular.tint(RelayTheme.deepBlue.opacity(0.12)), in: RelayTheme.panelShape)
        .overlay {
            RelayTheme.panelShape
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
        .padding(24)
        .onAppear { searchFocused = true }
    }

    // MARK: Search field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.right.2")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RelayTheme.accentGradient)

            TextField("Run a command…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .regular))
                .focused($searchFocused)
                .onSubmit(runSelected)
                .onKeyPress(.upArrow) { model.selectPrevious(); return .handled }
                .onKeyPress(.downArrow) { model.selectNext(); return .handled }
                .onKeyPress(.escape) { onDismiss(); return .handled }

            if !model.query.isEmpty {
                Button {
                    model.reset()
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
    }

    // MARK: Results

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(model.results) { command in
                        CommandRow(command: command, isSelected: command.id == model.selectedCommand?.id)
                            .id(command.id)
                            .onTapGesture { onRun(command) }
                            .onHover { hovering in
                                if hovering { model.select(command) }
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: RelayTheme.Metrics.paletteMaxHeight)
            .onChange(of: model.selectionIndex) { _, _ in
                if let selected = model.selectedCommand {
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(selected.id, anchor: .center)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text("No matching commands")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func runSelected() {
        guard let command = model.selectedCommand else { return }
        onRun(command)
    }
}
