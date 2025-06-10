import MarketKit
import SwiftUI
import UIKit

enum WalletTokenModule {
    static func viewController(wallet: Wallet) -> UIViewController? {
        let service = WalletTokenService(wallet: wallet)
        let viewModel = WalletTokenViewModel(service: service)

        let dataSourceChain = DataSourceChain()

        let viewController = WalletTokenViewController(
            viewModel: viewModel,
            dataSource: dataSourceChain
        )

        guard let tokenBalanceDataSource = WalletTokenBalanceModule.dataSource(wallet: wallet) else {
            return nil
        }
        tokenBalanceDataSource.parentViewController = viewController
        dataSourceChain.append(source: tokenBalanceDataSource)

        if let cautionDataSource = cautionDataSource(wallet: wallet) {
            dataSourceChain.append(source: cautionDataSource)
        }

        let transactionsDataSource = TransactionsModule.dataSource(token: wallet.token, statPage: .tokenPage)
        transactionsDataSource.viewController = viewController
        dataSourceChain.append(source: transactionsDataSource)

        return viewController
    }

    static func cautionDataSource(wallet: Wallet) -> ISectionDataSource? {
        let viewModel: ICautionDataSourceViewModel

        if wallet.token.blockchainType == .tron, let adapter = App.shared.adapterManager.adapter(for: wallet) as? BaseTronAdapter {
            viewModel = TronAccountInactiveViewModel(adapter: adapter)
        } else {
            return nil
        }

        return CautionDataSource(viewModel: viewModel)
    }

    @ViewBuilder static func view(wallet: Wallet) -> some View {
        if let adapter = App.shared.adapterManager.adapter(for: wallet) as? StellarAdapter {
            StellarWalletTokenView(wallet: wallet, stellarKit: adapter.stellarKit, asset: adapter.asset)
        } else if let adapter = App.shared.adapterManager.adapter(for: wallet) as? BitcoinBaseAdapter {
            BitcoinWalletTokenView(wallet: wallet, adapter: adapter)
        } else if let adapter = App.shared.adapterManager.adapter(for: wallet) as? ZcashAdapter {
            ZcashWalletTokenView(wallet: wallet, adapter: adapter)
        } else if let adapter = App.shared.adapterManager.adapter(for: wallet) as? BaseTronAdapter {
            TronWalletTokenView(wallet: wallet, adapter: adapter)
        } else {
            WalletTokenView(wallet: wallet)
        }
    }
}
