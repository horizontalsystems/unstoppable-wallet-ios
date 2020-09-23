import UIKit
import ThemeKit

protocol ICoinSelectDelegate {
    func didSelect(coin: SwapModule.CoinBalanceItem)
}

struct CoinBalanceViewItem {
    let coin: Coin
    let balance: String?
    let blockchainType: String?
}

struct CoinSelectModule {

    static func instance(coins: [SwapModule.CoinBalanceItem], delegate: ICoinSelectDelegate) -> UIViewController {
        let viewModel = CoinSelectViewModel(coins: coins)

        return ThemeNavigationController(rootViewController: CoinSelectViewController(viewModel: viewModel, delegate: delegate))
    }

}
