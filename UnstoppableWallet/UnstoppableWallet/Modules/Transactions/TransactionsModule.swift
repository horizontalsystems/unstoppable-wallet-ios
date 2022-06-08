import CurrencyKit
import UIKit
import RxSwift
import MarketKit

struct TransactionsModule {

    static let pageLimit = 20

    static func instance() -> UIViewController {
        let service = TransactionsService(
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.transactionAdapterManager
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

    enum Blockchain: Hashable {
        case bitcoin
        case litecoin
        case bitcoinCash
        case dash
        case zcash
        case bep2
        case evm(blockchainType: BlockchainType)

        public var title: String {
            switch self {
            case .bitcoin: return "Bitcoin"
            case .litecoin: return "Litecoin"
            case .bitcoinCash: return "Bitcoin Cash"
            case .dash: return "Dash"
            case .zcash: return "ZCash"
            case .bep2: return "Binance Chain"
            case .evm(let blockchainType): return blockchainType.uid // todo
            }
        }

        var image: String? {
            switch self {
            case .bep2: return "binance_chain_trx_24"
            case .evm(let blockchainType): return ""
            default: return nil
            }
        }

        var coinPlaceholderImage: String {
            switch self {
            case .bep2: return "Coin Icon Placeholder - BEP2"
            case .evm(let blockchainType): return "Coin Icon Placeholder - " // todo
            default: return "icon_placeholder_24"
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .bitcoin: hasher.combine(0)
            case .litecoin: hasher.combine(1)
            case .bitcoinCash: hasher.combine(2)
            case .dash: hasher.combine(3)
            case .zcash: hasher.combine(4)
            case .bep2: hasher.combine(5)
            case .evm(let blockchainType): hasher.combine(blockchainType.uid)
            }
        }

        static func ==(lhs: Blockchain, rhs: Blockchain) -> Bool {
            switch (lhs, rhs) {
            case (.bitcoin, .bitcoin): return true
            case (.litecoin, .litecoin): return true
            case (.bitcoinCash, .bitcoinCash): return true
            case (.dash, .dash): return true
            case (.zcash, .zcash): return true
            case (.bep2, .bep2): return true
            case (.evm(let lhsBlockchainType), .evm(let rhsBlockchainType)): return lhsBlockchainType == rhsBlockchainType
            default: return false
            }
        }
    }

    func hash(into hasher: inout Hasher) {
        blockchain.hash(into: &hasher)
        account.hash(into: &hasher)
        coinSettings.hash(into: &hasher)
    }

    static func ==(lhs: TransactionSource, rhs: TransactionSource) -> Bool {
        lhs.blockchain == rhs.blockchain && lhs.account == rhs.account && lhs.coinSettings == rhs.coinSettings
    }

}
