import UIKit
import ThemeKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(coin: Coin)
}

struct CoinSelectModule {

    static func viewController(delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.adapterManager
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }

}
