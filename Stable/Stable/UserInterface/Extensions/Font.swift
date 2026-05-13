import SwiftUI

public extension Font {
    static func manRopeFont(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
        case .regular: return Font.custom("Manrope-Regular", size: size)
        case .medium: return Font.custom("Manrope-Medium", size: size)
        case .semibold: return Font.custom("Manrope-SemiBold", size: size)
        default: return .system(size: size, weight: weight)
        }
    }
}
