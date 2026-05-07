import MarketKit

import UIKit

protocol ICoinSelectDelegate: AnyObject {
    func didSelect(token: Token)
}

enum CoinSelectModule {
    static func viewController(dex: SwapModule.Dex, delegate: ICoinSelectDelegate) -> UIViewController {
        let service = CoinSelectService(
            dex: dex,
            marketKit: Core.shared.marketKit,
            walletManager: Core.shared.walletManager,
            adapterManager: Core.shared.adapterManager,
            currencyManager: Core.shared.currencyManager
        )
        let viewModel = CoinSelectViewModel(service: service)

        return CoinSelectViewController(viewModel: viewModel, delegate: delegate)
    }
}
