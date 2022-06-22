import CurrencyKit
import UIKit
import RxSwift
import MarketKit

struct TransactionsModule {

    static let pageLimit = 20

    static func instance() -> UIViewController {
        let service = TransactionsService(
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.transactionAdapterManager,
                evmBlockchainManager: App.shared.evmBlockchainManager
        )
        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: App.shared.evmLabelManager)
        let viewModel = TransactionsViewModel(service: service, factory: viewItemFactory)
        let viewController = TransactionsViewController(viewModel: viewModel)

        return viewController
    }

    struct ViewStatus {
        let showProgress: Bool
        let messageType: MessageType?
    }

    enum MessageType {
        case syncing
        case empty
    }

}

enum TransactionTypeFilter: String, CaseIterable {
    case all, incoming, outgoing, swap, approve
}

struct TransactionWallet: Hashable {
    let token: Token?
    let source: TransactionSource
    let badge: String?

    func hash(into hasher: inout Hasher) {
        token?.hash(into: &hasher)
        source.hash(into: &hasher)
        badge.hash(into: &hasher)
    }

    static func ==(lhs: TransactionWallet, rhs: TransactionWallet) -> Bool {
        lhs.token == rhs.token && lhs.source == rhs.source && lhs.badge == rhs.badge
    }
}

struct TransactionSource: Hashable {
    let blockchain: Blockchain
    let account: Account
    let coinSettings: CoinSettings
    let symbol: String

    func hash(into hasher: inout Hasher) {
        blockchain.hash(into: &hasher)
        account.hash(into: &hasher)
        coinSettings.hash(into: &hasher)
        symbol.hash(into: &hasher)
    }

    static func ==(lhs: TransactionSource, rhs: TransactionSource) -> Bool {
        lhs.blockchain == rhs.blockchain && lhs.account == rhs.account && lhs.coinSettings == rhs.coinSettings && lhs.symbol == rhs.symbol
    }

}
