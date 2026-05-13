import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appTheme"
    static let `default`: AppTheme = .system

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "theme.system"
        case .light: "theme.light"
        case .dark: "theme.dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
