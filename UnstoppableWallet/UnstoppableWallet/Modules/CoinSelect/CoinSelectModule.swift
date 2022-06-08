import UIKit
import ThemeKit
import MarketKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(token: Token)
}

struct CoinSelectModule {

    static func viewController(dex: SwapModule.Dex, delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
                dex: dex,
                marketKit: App.shared.marketKit,
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.adapterManager,
                currencyKit: App.shared.currencyKit
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }

}
