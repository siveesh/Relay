import SwiftUI

/// About window for Relay — mirrors the SK Look DNA reference implementation,
/// styled to match Relay's Liquid Glass design language.
struct AboutView: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Liquid Glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                logos
                appInfo
                developerInfo
            }
            .padding(40)
        }
        .frame(width: 420, height: 380)
    }

    // MARK: Logos

    private var logos: some View {
        HStack(spacing: 36) {
            if let logo1 = NSImage(named: "Logo1") {
                Image(nsImage: logo1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }

            Divider()
                .frame(height: 80)
                .opacity(0.3)

            if let logo2 = NSImage(named: "Logo2") {
                Image(nsImage: logo2)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .colorInvert()   // black-on-white → white-on-dark; reads on glass
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
        }
        .padding(.top, 8)
    }

    // MARK: App info

    private var appInfo: some View {
        VStack(spacing: 6) {
            Text("Relay")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Native macOS Command Palette & Task Runner")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (Build \(build))")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: Developer info

    private var developerInfo: some View {
        VStack(spacing: 8) {
            Text("© 2026 Siveesh Kodapully")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Link("www.siveesh.com", destination: URL(string: "https://www.siveesh.com")!)
                    .font(.system(size: 13, weight: .medium))

                Text("•")
                    .foregroundStyle(.tertiary)

                Link("siveesh@learnwithsk.com", destination: URL(string: "mailto:siveesh@learnwithsk.com")!)
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .padding(.bottom, 8)
    }
}
