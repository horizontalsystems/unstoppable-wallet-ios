import UIKit
import ThemeKit
import MarketKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(platformCoin: PlatformCoin)
}

struct CoinSelectModule {

    static func viewController(dex: SwapModule.Dex, delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
                dex: dex,
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.adapterManager,
                rateManager: App.shared.rateManagerNew,
                currencyKit: App.shared.currencyKit
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }

}
