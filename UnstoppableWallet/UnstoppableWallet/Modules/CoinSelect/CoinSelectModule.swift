import UIKit
import ThemeKit
import CoinKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(coin: Coin)
}

struct CoinSelectModule {

    static func viewController(dex: SwapModuleNew.DexNew, delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
                dex: dex,
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                rateManager: App.shared.rateManager,
                currencyKit: App.shared.currencyKit
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }

}
