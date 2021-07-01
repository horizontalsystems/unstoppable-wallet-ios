import RxSwift
import RxCocoa
import CoinKit
import CurrencyKit

class TransactionInfoViewModel {
    private let disposeBag = DisposeBag()

    private let service: TransactionInfoService
    private let factory: TransactionInfoViewItemFactory

    private let transaction: TransactionRecord
    private let wallet: Wallet

    private var rates = [Coin: CurrencyValue]()
    private var viewItemsRelay = PublishRelay<[[TransactionInfoModule.ViewItem]]>()
    private var explorerViewItem: TransactionInfoModule.ViewItem

    init(service: TransactionInfoService, factory: TransactionInfoViewItemFactory, transaction: TransactionRecord, wallet: Wallet) {
        self.service = service
        self.factory = factory
        self.transaction = transaction
        self.wallet = wallet

        let transactionHash = transaction.transactionHash
        let coin = wallet.coin
        let account = wallet.account
        let testMode = service.testMode

        var title: String
        var url: String?
        switch coin.type {
        case .bitcoin:
            title = "btc.com"
            url = testMode ? nil : "https://btc.com/" + transactionHash
        case .bitcoinCash:
            title = "btc.com"
            url = testMode ? nil : "https://bch.btc.com/" + transactionHash
        case .litecoin:
            title = "blockchair.com"
            url = testMode ? nil : "https://blockchair.com/litecoin/transaction/" + transactionHash
        case .dash:
            title = "dash.org"
            url = testMode ? nil : "https://insight.dash.org/insight/tx/" + transactionHash
        case .ethereum, .erc20:
            let domain: String

            switch service.ethereumNetworkType(account: account) {
            case .ropsten: domain = "ropsten.etherscan.io"
            case .rinkeby: domain = "rinkeby.etherscan.io"
            case .kovan: domain = "kovan.etherscan.io"
            case .goerli: domain = "goerli.etherscan.io"
            default: domain = "etherscan.io"
            }

            title = "etherscan.io"
            url = "https://\(domain)/tx/" + transactionHash
        case .binanceSmartChain, .bep20:
            let domain: String

            switch service.binanceSmartChainNetworkType(account: account) {
            default: domain = "bscscan.com"
            }

            title = "bscscan.com"
            url = testMode ? nil : "https://\(domain)/tx/" + transactionHash
        case .bep2:
            title = "binance.org"
            url = testMode ? "https://testnet-explorer.binance.org/tx/" + transactionHash : "https://explorer.binance.org/tx/" + transactionHash
        case .zcash:
            title = "blockchair.com"
            url = testMode ? nil : "https://blockchair.com/zcash/transaction/" + transactionHash
        case .unsupported:
            title = ""
            url = nil
        }

        explorerViewItem = .explorer(title: "tx_info.view_on".localized(title), url: url)

        subscribe(disposeBag, service.ratesSignal) { [weak self] in self?.updateRates(rates: $0) }
        service.fetchRates(coins: coinsForRates, timestamp: transaction.date.timeIntervalSince1970)
    }

    private var coinsForRates: [Coin] {
        switch transaction {
        case let tx as EvmIncomingTransactionRecord: return [tx.value.coin]
        case let tx as EvmOutgoingTransactionRecord: return [tx.fee.coin, tx.value.coin]
        case let tx as SwapTransactionRecord: return [tx.fee, tx.valueIn, tx.valueOut].compactMap { $0?.coin }
        case let tx as ApproveTransactionRecord: return [tx.fee.coin, tx.value.coin]
        case let tx as ContractCallTransactionRecord:
            let internalEth: [Coin] = tx.incomingInternalETHs.map({ $0.value.coin })
            let incomingTokens: [Coin] = tx.incomingEip20Events.map({ $0.value.coin })
            let outgoingTokens: [Coin] = tx.outgoingEip20Events.map({ $0.value.coin })

            return Array(Set(internalEth + incomingTokens + outgoingTokens))

        case let tx as BitcoinIncomingTransactionRecord: return [tx.value.coin]
        case let tx as BitcoinOutgoingTransactionRecord: return [tx.fee, tx.value].compactMap { $0?.coin }

        default: return []
        }
    }

    private func updateRates(rates: [Coin: CurrencyValue]) {
        self.rates = rates
        viewItemsRelay.accept(viewItems)
    }

}

extension TransactionInfoViewModel {

    var viewItems: [[TransactionInfoModule.ViewItem]] {
        factory.items(transaction: transaction, rates: rates, lastBlockInfo: service.lastBlockInfo) + [[explorerViewItem]]
    }

    var viewItemsDriver: Signal<[[TransactionInfoModule.ViewItem]]> {
        viewItemsRelay.asSignal()
    }

    func onTapTransactionId() {
        service.copy(value: transaction.transactionHash)
    }

}
