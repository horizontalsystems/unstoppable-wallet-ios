import UIKit
import ThemeKit
import MarketKit

struct WalletTokenModule {

    static func viewController(element: WalletModule.Element) -> UIViewController? {
        let service = WalletTokenService(element: element)
        let viewModel = WalletTokenViewModel(service: service)

        let dataSource = DataSourceChain()

        guard let tokenBalanceView = WalletTokenBalanceModule.view(element: element) else {
            return nil
        }
        dataSource.append(source: tokenBalanceView)

        let viewController = WalletTokenViewController(
                viewModel: viewModel,
                dataSource: dataSource
        )

        tokenBalanceView.parentViewController = viewController

        return viewController
    }

}
