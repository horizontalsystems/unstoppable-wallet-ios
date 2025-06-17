import SwiftUI

enum BaseCurrencySettingsModule {
    static func view() -> some View {
        let viewModel = BaseCurrencySettingsViewModel(currencyManager: Core.shared.currencyManager)
        return BaseCurrencySettingsView(viewModel: viewModel)
    }
}
