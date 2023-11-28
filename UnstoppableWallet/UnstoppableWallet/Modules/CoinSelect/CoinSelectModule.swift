import MarketKit
import ThemeKit
import UIKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(token: Token)
}

enum CoinSelectModule {
    static func viewController(dex: SwapModule.Dex, delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
            dex: dex,
            marketKit: App.shared.marketKit,
            walletManager: App.shared.walletManager,
            adapterManager: App.shared.adapterManager,
            currencyManager: App.shared.currencyManager
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }
}
