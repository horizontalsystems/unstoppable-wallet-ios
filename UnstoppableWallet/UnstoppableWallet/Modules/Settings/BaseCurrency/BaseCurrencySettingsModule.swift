import SwiftUI

struct BaseCurrencySettingsModule {
    static func view() -> some View {
        let viewModel = BaseCurrencySettingsViewModel(currencyManager: App.shared.currencyManager)
        return BaseCurrencySettingsView(viewModel: viewModel)
    }
}
