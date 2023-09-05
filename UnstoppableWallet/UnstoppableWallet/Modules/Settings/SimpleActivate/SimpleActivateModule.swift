import SwiftUI

struct SimpleActivateModule {

    static func bitcoinHodlingView() -> some View {
        let viewModel = SimpleActivateViewModel(localStorage: App.shared.localStorage)

        return SimpleActivateView(
                viewModel: viewModel,
                title: "settings.bitcoin_hodling.title".localized,
                toggleText: "settings.bitcoin_hodling.lock_time".localized,
                description: "settings.bitcoin_hodling.description".localized(AppConfig.appName, AppConfig.appName)
        )
    }

}
