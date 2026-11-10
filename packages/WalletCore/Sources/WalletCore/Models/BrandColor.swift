import SwiftUI
import UIKit

public enum BrandColor: String, CaseIterable, Sendable {
    case orange
    case jacob

    public static let `default`: BrandColor = .orange

    public var color: Color {
        switch self {
        case .orange: return .themeOrange
        case .jacob: return .themeJacob
        }
    }

    public var uiColor: UIColor {
        switch self {
        case .orange: return .themeOrange
        case .jacob: return .themeJacob
        }
    }
}
