import UIKit
import ThemeKit

protocol ICoinSelectDelegate {
    func didSelect(coin: CoinBalanceItem)
}

struct CoinBalanceViewItem {
    let coin: Coin
    let balance: String?
}

struct CoinSelectModule {

    static func instance(coins: [CoinBalanceItem], delegate: ICoinSelectDelegate) -> UIViewController {
        let viewModel = CoinSelectViewModel(coins: coins)

        return ThemeNavigationController(rootViewController: CoinSelectViewController(viewModel: viewModel, delegate: delegate))
    }

}
