import UIKit
import ThemeKit
import CoinKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(coin: Coin)
}

struct CoinSelectModule {

    static func viewController(dex: SwapModule.Dex, delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
                dex: dex,
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.adapterManager,
                rateManager: App.shared.rateManager,
                currencyKit: App.shared.currencyKit
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }

}
