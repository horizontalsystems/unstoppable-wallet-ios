import UIKit
import ThemeKit
import MarketKit

struct WalletTokenModule {

    static func viewController(element: WalletModule.Element) -> UIViewController? {
        let service = WalletTokenService(element: element)
        let viewModel = WalletTokenViewModel(service: service)

        let dataSourceChain = DataSourceChain()

        let viewController = WalletTokenViewController(
                viewModel: viewModel,
                dataSource: dataSourceChain
        )

        guard let tokenBalanceDataSource = WalletTokenBalanceModule.dataSource(element: element) else {
            return nil
        }
        tokenBalanceDataSource.parentViewController = viewController
        dataSourceChain.append(source: tokenBalanceDataSource)

        if let wallet = element.wallet {
            let transactionsDataSource = TransactionsModule.dataSource(token: wallet.token)
            transactionsDataSource.viewController = viewController
            dataSourceChain.append(source: transactionsDataSource)
        }

        return viewController
    }

}
