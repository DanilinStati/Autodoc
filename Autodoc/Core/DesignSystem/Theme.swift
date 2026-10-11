import UIKit

extension UIColor {
    nonisolated static let brand = UIColor(named: "AccentColor") ?? .systemOrange

    nonisolated static let onBrand = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .white
    }

    nonisolated static let feedBackground = UIColor.systemGroupedBackground
    nonisolated static let cardBackground = UIColor.secondarySystemGroupedBackground
    nonisolated static let skeleton = UIColor.tertiarySystemFill
}

nonisolated enum Spacing {
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

nonisolated enum Radius {
    static let card: CGFloat = 16
}

extension UIFont {
    static func preferred(_ style: TextStyle, weight: Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: defaultPointSize(for: style), weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }

    private static func defaultPointSize(for style: TextStyle) -> CGFloat {
        let defaultTraits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFont.preferredFont(forTextStyle: style, compatibleWith: defaultTraits).pointSize
    }
}

