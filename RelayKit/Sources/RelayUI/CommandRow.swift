import SwiftUI
import RelayCore

/// A single result row in the command palette.
struct CommandRow: View {
    let command: RelayCommand
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(RelayTheme.accentGradient))
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(command.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                    if command.favorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : RelayTheme.cyan)
                    }
                }
                if !command.details.isEmpty {
                    Text(command.details)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            CategoryBadge(text: command.category, isSelected: isSelected)

            if command.requiresElevation {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
            }

            if isSelected {
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: RelayTheme.Metrics.rowHeight)
        .background {
            if isSelected {
                RelayTheme.rowShape.fill(RelayTheme.accentGradient.opacity(0.9))
            }
        }
        .contentShape(RelayTheme.rowShape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Runs this command")
    }

    private var accessibilityLabel: String {
        var parts = [command.name, "category \(command.category)"]
        if command.favorite { parts.append("favorite") }
        if command.requiresElevation { parts.append("requires administrator privileges") }
        if !command.details.isEmpty { parts.append(command.details) }
        return parts.joined(separator: ", ")
    }
}

/// Small pill showing a command's category.
private struct CategoryBadge: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.4)
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: RelayTheme.Radius.badge, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(.white.opacity(0.22)) : AnyShapeStyle(.quaternary))
            }
    }
}
