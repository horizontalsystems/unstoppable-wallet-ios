import SwiftUI

struct AppearanceModule {
    static func view() -> some View {
        let viewModel = AppearanceViewModel(
            themeManager: App.shared.themeManager,
            launchScreenManager: App.shared.launchScreenManager,
            appIconManager: App.shared.appIconManager,
            balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
            balanceConversionManager: App.shared.balanceConversionManager,
            balanceHiddenManager: App.shared.balanceHiddenManager
        )
        return AppearanceView(viewModel: viewModel)
    }
}
