import UIKit
import ThemeKit
import MarketKit

struct WalletTokenModule {

    static func viewController(element: WalletModule.Element) -> UIViewController? {
        let service = WalletTokenService(element: element)
        let viewModel = WalletTokenViewModel(service: service)

        let dataSourceChain = DataSourceChain()

        guard let tokenBalanceView = WalletTokenBalanceModule.view(element: element) else {
            return nil
        }
        dataSourceChain.append(source: tokenBalanceView)

        if let wallet = element.wallet {
            let transactionsDataSource = TransactionsModule.dataSource(token: wallet.token)
            dataSourceChain.append(source: transactionsDataSource)
        }

        let viewController = WalletTokenViewController(
                viewModel: viewModel,
                dataSource: dataSourceChain
        )

        tokenBalanceView.parentViewController = viewController

        return viewController
    }

}
