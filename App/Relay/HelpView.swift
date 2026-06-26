import SwiftUI

/// Renders Help.md from the app bundle in a scrollable, searchable window.
struct HelpView: View {

    @State private var searchText = ""
    @State private var sections: [HelpSection] = []

    var body: some View {
        NavigationSplitView {
            // Sidebar — table of contents
            List(filteredSections, id: \.heading, selection: $selectedHeading) { section in
                Text(section.heading)
                    .font(.callout)
                    .tag(section.heading)
            }
            .listStyle(.sidebar)
            .navigationTitle("Contents")
            .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
        } detail: {
            // Detail — full rendered Markdown
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredSections, id: \.heading) { section in
                            SectionBlock(section: section)
                                .id(section.heading)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                            Divider().padding(.horizontal, 32)
                        }
                    }
                    .padding(.vertical, 24)
                }
                .onChange(of: selectedHeading) { _, heading in
                    guard let heading else { return }
                    withAnimation { proxy.scrollTo(heading, anchor: .top) }
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search help…")
        .navigationTitle("Relay Help")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    revealInFinder()
                } label: {
                    Label("Open in Finder", systemImage: "doc.text.magnifyingglass")
                }
                .help("Open Help.md in your default Markdown viewer")
            }
        }
        .task { sections = HelpParser.parse() }
    }

    // MARK: - State

    @State private var selectedHeading: String?

    private var filteredSections: [HelpSection] {
        guard !searchText.isEmpty else { return sections }
        let lower = searchText.lowercased()
        return sections.filter {
            $0.heading.lowercased().contains(lower) ||
            $0.body.lowercased().contains(lower)
        }
    }

    // MARK: - Actions

    private func revealInFinder() {
        guard let url = Bundle.main.url(forResource: "Help", withExtension: "md") else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Section block renderer

private struct SectionBlock: View {
    let section: HelpSection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Heading
            Text(section.heading)
                .font(section.level == 2 ? .title2.bold() : .title3.bold())
                .foregroundStyle(section.level == 2 ? .primary : .secondary)

            // Body — render Markdown
            if let attr = try? AttributedString(
                markdown: section.body,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attr)
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(section.body)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Data model & parser

struct HelpSection: Identifiable {
    let id = UUID()
    let heading: String
    let level: Int   // 2 = ##, 3 = ###
    let body: String
}

enum HelpParser {
    /// Splits Help.md into sections on ## and ### headings.
    static func parse() -> [HelpSection] {
        guard let url = Bundle.main.url(forResource: "Help", withExtension: "md"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return [HelpSection(heading: "Help unavailable", level: 2,
                                body: "Help.md was not found in the app bundle.")]
        }

        var sections: [HelpSection] = []
        var currentHeading = "Relay Help"
        var currentLevel = 2
        var currentLines: [String] = []

        func flush() {
            let body = currentLines
                .drop(while: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty || !sections.isEmpty {
                sections.append(HelpSection(heading: currentHeading, level: currentLevel, body: body))
            }
        }

        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("## ") {
                flush()
                currentLines = []
                currentHeading = String(line.dropFirst(3))
                currentLevel = 2
            } else if line.hasPrefix("### ") {
                flush()
                currentLines = []
                currentHeading = String(line.dropFirst(4))
                currentLevel = 3
            } else if line.hasPrefix("# ") {
                // Top-level title — skip
                continue
            } else {
                currentLines.append(line)
            }
        }
        flush()
        return sections
    }
}
