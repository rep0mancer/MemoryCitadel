import UIKit

/// Defines application colour palettes used by the procedural
/// generation and UI elements. Colours are provided for light and
/// dark appearances.
public extension UIColor {
    struct Citadel {
        static let primary = UIColor(named: "Primary", in: Bundle.main, compatibleWith: nil) ?? UIColor.systemIndigo
        static let secondary = UIColor(named: "Secondary", in: Bundle.main, compatibleWith: nil) ?? UIColor.systemTeal
        static let accent = UIColor(named: "Accent", in: Bundle.main, compatibleWith: nil) ?? UIColor.systemOrange
    }
}