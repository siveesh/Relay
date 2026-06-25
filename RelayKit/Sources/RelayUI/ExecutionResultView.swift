import SwiftUI
import RelayCore

/// Displays the outcome of a command execution: status, timing, and captured output.
public struct ExecutionResultView: View {

    private let record: ExecutionRecord
    private let onClose: (() -> Void)?

    public init(record: ExecutionRecord, onClose: (() -> Void)? = nil) {
        self.record = record
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let failure = record.failureMessage {
                outputBlock(title: "Error", text: failure, monospaced: false)
            }
            if !record.stdout.isEmpty {
                outputBlock(title: "Output", text: record.stdout)
            }
            if !record.stderr.isEmpty {
                outputBlock(title: "Standard Error", text: record.stderr)
            }
            if record.stdout.isEmpty && record.stderr.isEmpty && record.failureMessage == nil {
                Text("No output.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(width: 560)
        .frame(maxHeight: 520)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: record.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.title2)
                .foregroundStyle(record.succeeded ? Color.green : Color.red)
            VStack(alignment: .leading, spacing: 1) {
                Text(record.commandName).font(.headline)
                Text(statusLine).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let onClose {
                Button { onClose() } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusLine: String {
        let duration = String(format: "%.2fs", record.duration)
        if let failure = record.failureMessage {
            return "Failed · \(duration) · \(failure)"
        }
        return "Exit code \(record.exitCode) · \(duration)"
    }

    private func outputBlock(title: String, text: String, monospaced: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            ScrollView {
                Text(text)
                    .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
