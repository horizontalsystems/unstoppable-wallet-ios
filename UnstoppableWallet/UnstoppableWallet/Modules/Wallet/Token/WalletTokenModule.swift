import MarketKit
import ThemeKit
import UIKit

enum WalletTokenModule {
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
            if let cautionDataSource = cautionDataSource(wallet: wallet) {
                dataSourceChain.append(source: cautionDataSource)
            }

            let transactionsDataSource = TransactionsModule.dataSource(token: wallet.token, statPage: .tokenPage)
            transactionsDataSource.viewController = viewController
            dataSourceChain.append(source: transactionsDataSource)
        }

        return viewController
    }

    static func cautionDataSource(wallet: Wallet) -> ISectionDataSource? {
        let viewModel: ICautionDataSourceViewModel

        if wallet.token.blockchainType == .tron, let adapter = App.shared.adapterManager.adapter(for: wallet) as? BaseTronAdapter {
            viewModel = TronAccountInactiveViewModel(adapter: adapter)
            // } else if wallet.token.blockchainType == .stellar, let adapter = App.shared.adapterManager.adapter(for: wallet) as? StellarAdapter {
            // viewModel = StellarAccountCautionViewModel(adapter: adapter)
        } else {
            return nil
        }

        return CautionDataSource(viewModel: viewModel)
    }
}
