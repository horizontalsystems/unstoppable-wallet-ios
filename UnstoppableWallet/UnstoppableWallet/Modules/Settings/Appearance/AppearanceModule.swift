import UIKit
import ThemeKit

struct AppearanceModule {

    static func viewController() -> UIViewController {
        let service = AppearanceService(
                themeManager: App.shared.themeManager,
                launchScreenManager: App.shared.launchScreenManager,
                appIconManager: App.shared.appIconManager,
                balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
                balanceConversionManager: App.shared.balanceConversionManager
        )

        let viewModel = AppearanceViewModel(service: service)
        return AppearanceViewController(viewModel: viewModel)
    }

}

extension ThemeMode: CustomStringConvertible {

    public var title: String {
        switch self {
        case .system: return "appearance.theme.system".localized
        case .dark: return "appearance.theme.dark".localized
        case .light: return "appearance.theme.light".localized
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
