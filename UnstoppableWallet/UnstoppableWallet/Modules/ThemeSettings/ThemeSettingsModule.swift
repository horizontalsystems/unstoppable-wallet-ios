import UIKit
import ThemeKit

struct ThemeSettingsModule {

    static func viewController() -> UIViewController {
        let service = ThemeSettingsService(themeManager: ThemeManager.shared)

        let viewModel = ThemeSettingsViewModel(service: service)

        return ThemeSettingsViewController(viewModel: viewModel)
    }

}

extension ThemeMode: CustomStringConvertible {

    public var description: String {
        switch self {
        case .system: return "settings_theme.system".localized
        case .dark: return "settings_theme.dark".localized
        case .light: return "settings_theme.light".localized
        }
    }

    public var iconName: String {
        switch self {
        case .system: return "settings_20"
        case .dark: return "dark_20"
        case .light: return "light_20"
        }
    }

}
