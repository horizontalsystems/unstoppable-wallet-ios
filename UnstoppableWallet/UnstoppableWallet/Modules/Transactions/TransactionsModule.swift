import Foundation
import DeepDiff
import CurrencyKit
import CoinKit

protocol ITransactionsView: AnyObject {
    func set(status: TransactionViewStatus)
    func show(filters: [FilterHeaderView.ViewItem])
    func show(transactions: [TransactionViewItem], animated: Bool)
    func showNoTransactions()
    func reloadTransactions()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onFilterSelect(index: Int)

    func onBottomReached()

    func onTransactionClick(item: TransactionViewItem)
    func willShow(item: TransactionViewItem)
}

protocol ITransactionsInteractor {
    func initialFetch()
    func fetchLastBlockHeights(wallets: [TransactionWallet])

    func fetchRecords(fetchDataList: [FetchData], initial: Bool)
    func fetchRate(coin: Coin, date: Date)
    func observe(wallets: [TransactionWallet])
}

protocol ITransactionsInteractorDelegate: AnyObject {
    func onUpdate(wallets: [Wallet])
    func onUpdate(lastBlockInfos: [(TransactionWallet, LastBlockInfo?)])
    func onUpdate(states: [TransactionWallet: AdapterState])

    func onUpdateBaseCurrency()
    func onConnectionRestore()

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: TransactionWallet)
    func didUpdate(records: [TransactionRecord], wallet: TransactionWallet)
    func didUpdate(state: AdapterState, wallet: TransactionWallet)

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date)
    func didFetch(recordsData: [TransactionWallet: [TransactionRecord]], initial: Bool)
}

protocol ITransactionsRouter {
    func openTransactionInfo(viewItem: TransactionViewItem)
}

protocol ITransactionViewItemFactory {
    func filterItems(wallets: [Wallet]) -> [FilterHeaderView.ViewItem]
    func viewItem(fromRecord record: TransactionRecord, wallet: TransactionWallet, lastBlockInfo: LastBlockInfo?, mainAmountCurrencyValue: CurrencyValue?) -> TransactionViewItem
    func currencyString(from: CurrencyValue) -> String
    func viewStatus(adapterStates: [AdapterState], transactionsCount: Int) -> TransactionViewStatus
}

protocol IDiffer {
    func changes<T: DiffAware>(old: [T], new: [T], section: Int) -> ChangeWithIndexPath
}

struct FetchData {
    let wallet: TransactionWallet
    let from: TransactionRecord?
    let limit: Int
}

struct TransactionWallet: Hashable {
    let coin: Coin?
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
