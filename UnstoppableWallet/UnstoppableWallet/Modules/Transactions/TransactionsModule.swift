import CurrencyKit
import UIKit
import RxSwift
import MarketKit

struct TransactionsModule {

    static let pageLimit = 10

    static func instance() -> UIViewController {
        let service = TransactionsService(
                walletManager: App.shared.walletManagerNew,
                adapterManager: App.shared.transactionAdapterManager
        )
        let viewModel = TransactionsViewModel(service: service, factory: TransactionsViewItemFactory())
        let viewController = TransactionsViewController(viewModel: viewModel)

        return viewController
    }

    struct ViewStatus {
        let showProgress: Bool
        let showMessage: Bool
    }

}

enum TransactionTypeFilter: String, CaseIterable {
    case all, incoming, outgoing, swap, approve
}

struct TransactionItem {
    let record: TransactionRecord
    var lastBlockInfo: LastBlockInfo?
    var currencyValue: CurrencyValue?
}

struct TransactionViewItem {
    let uid: String
    let date: Date
    let typeImage: ColoredImage
    let progress: Float?
    let title: String
    let subTitle: String
    let primaryValue: ColoredValue?
    let secondaryValue: ColoredValue?
    let sentToSelf: Bool
    let locked: Bool?
}

struct ColoredValue {
    let value: String
    let color: UIColor
}

struct ColoredImage {
    let imageName: String
    let color: UIColor
}

struct TransactionWallet: Hashable {
    let coin: PlatformCoin?
    let source: TransactionSource

    func hash(into hasher: inout Hasher) {
        coin?.hash(into: &hasher)
        source.hash(into: &hasher)
    }

    static func ==(lhs: TransactionWallet, rhs: TransactionWallet) -> Bool {
        lhs.coin == rhs.coin && lhs.source == rhs.source
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
        case ethereum
        case zcash
        case binanceSmartChain
        case bep2(symbol: String)

        public var title: String {
            switch self {
            case .bitcoin: return "Bitcoin"
            case .litecoin: return "Litecoin"
            case .bitcoinCash: return "Bitcoin Cash"
            case .dash: return "Dash"
            case .ethereum: return "Ethereum"
            case .zcash: return "ZCash"
            case .binanceSmartChain: return "BSC"
            case .bep2: return "Binance Chain"
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .bitcoin: hasher.combine(0)
            case .litecoin: hasher.combine(1)
            case .bitcoinCash: hasher.combine(2)
            case .dash: hasher.combine(3)
            case .ethereum: hasher.combine(4)
            case .zcash: hasher.combine(5)
            case .binanceSmartChain: hasher.combine(6)
            case .bep2(let symbol): hasher.combine(symbol)
            }
        }

        static func ==(lhs: Blockchain, rhs: Blockchain) -> Bool {
            switch (lhs, rhs) {
            case (.bitcoin, .bitcoin): return true
            case (.litecoin, .litecoin): return true
            case (.bitcoinCash, .bitcoinCash): return true
            case (.dash, .dash): return true
            case (.ethereum, .ethereum): return true
            case (.zcash, .zcash): return true
            case (.binanceSmartChain, .binanceSmartChain): return true
            case (.bep2(let symbol1), .bep2(let symbol2)): return symbol1 == symbol2
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
