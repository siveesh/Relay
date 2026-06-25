import SwiftUI

struct CommandPaletteView: View {
    @State private var query = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(">")
                    .foregroundStyle(.secondary)
                TextField("Run command", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Top Result")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                CommandRow(title: "Start LM Studio", subtitle: "Launch LM Studio")
                CommandRow(title: "Tailscale Status", subtitle: "Show network status")
                CommandRow(title: "Flush DNS Cache", subtitle: "Requires sudo")
            }
            .padding()
        }
        .frame(width: 620)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 30)
        .padding()
    }
}

struct CommandRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: "chevron.right.circle.fill")
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "return")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
