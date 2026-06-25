import SwiftUI

/// Centralized design tokens for Relay's Liquid Glass interface.
///
/// Keeping colors, geometry, and spacing in one place keeps the UI consistent and makes the
/// "deep blue glass / cyan highlight / white chevron" identity easy to evolve.
public enum RelayTheme {

    // MARK: Brand color

    /// Deep blue used for glass tint and accents.
    public static let deepBlue = Color(red: 0.07, green: 0.36, blue: 0.92)
    /// Cyan highlight for selection and the chevron mark.
    public static let cyan = Color(red: 0.18, green: 0.80, blue: 0.98)
    /// Primary accent gradient (deep blue → cyan), used on the brand chevron and selection.
    public static let accentGradient = LinearGradient(
        colors: [deepBlue, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Geometry

    public enum Radius {
        public static let panel: CGFloat = 26
        public static let row: CGFloat = 14
        public static let badge: CGFloat = 7
    }

    public enum Metrics {
        public static let paletteWidth: CGFloat = 680
        public static let paletteMaxHeight: CGFloat = 460
        public static let rowHeight: CGFloat = 52
        public static let contentPadding: CGFloat = 14
    }

    // MARK: Shapes

    /// The continuous rounded rectangle used for the palette panel.
    public static var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
    }

    public static var rowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
    }
}
