import SwiftUI
import RelayCore
import RelayUI

/// The execution-history window: a list of past runs with a detail pane and filtering.
struct HistoryView: View {

    @Bindable var history: HistoryModel

    @State private var selection: ExecutionRecord.ID?
    @State private var filter: Filter = .all
    @State private var search = ""

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", succeeded = "Succeeded", failed = "Failed"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationSplitView {
            list
        } detail: {
            detail
        }
        .navigationTitle("Execution History")
        .toolbar {
            ToolbarItemGroup {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()

                Button(role: .destructive) { history.clear() } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(history.records.isEmpty)
            }
        }
    }

    private var filtered: [ExecutionRecord] {
        history.newestFirst.filter { record in
            switch filter {
            case .all: return true
            case .succeeded: return record.succeeded
            case .failed: return !record.succeeded
            }
        }
        .filter { search.isEmpty || $0.commandName.localizedCaseInsensitiveContains(search) }
    }

    private var list: some View {
        List(filtered, selection: $selection) { record in
            HStack(spacing: 10) {
                Image(systemName: record.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(record.succeeded ? Color.green : Color.red)
                VStack(alignment: .leading, spacing: 1) {
                    Text(record.commandName)
                    Text(record.startedAt.formatted(date: .abbreviated, time: .standard))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.2fs", record.duration))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            .tag(record.id)
        }
        .searchable(text: $search, placement: .sidebar)
        .frame(minWidth: 300)
    }

    @ViewBuilder private var detail: some View {
        if let record = history.records.first(where: { $0.id == selection }) {
            ScrollView { ExecutionResultView(record: record).frame(maxWidth: .infinity) }
        } else {
            ContentUnavailableView("No Run Selected", systemImage: "clock.arrow.circlepath",
                                   description: Text("Select a run to inspect its output."))
        }
    }
}
