import RxSwift
import RxCocoa
import CoinKit
import CurrencyKit

class TransactionInfoViewModel {
    private let disposeBag = DisposeBag()

    private let service: TransactionInfoService
    private let factory: TransactionInfoViewItemFactory

    private let transaction: TransactionRecord

    private var rates = [Coin: CurrencyValue]()
    private var viewItemsRelay = PublishRelay<[[TransactionInfoModule.ViewItem]]>()
    private var explorerViewItem: TransactionInfoModule.ViewItem

    init(service: TransactionInfoService, factory: TransactionInfoViewItemFactory, transaction: TransactionRecord, wallet: TransactionWallet) {
        self.service = service
        self.factory = factory
        self.transaction = transaction

        let transactionHash = transaction.transactionHash
        let blockchain = wallet.source.blockchain
        let account = wallet.source.account
        let testMode = service.testMode

        var title: String
        var url: String?
        switch blockchain {
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
        case .ethereum:
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
        case .binanceSmartChain:
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
        }

        explorerViewItem = .explorer(title: "tx_info.view_on".localized(title), url: url)

        subscribe(disposeBag, service.ratesSignal) { [weak self] in self?.updateRates(rates: $0) }
        service.fetchRates(coins: coinsForRates, timestamp: transaction.date.timeIntervalSince1970)
    }

    private var coinsForRates: [Coin] {
        var coins = [Coin]()

        switch transaction {
        case let tx as EvmIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as EvmOutgoingTransactionRecord: coins.append(tx.value.coin)
        case let tx as SwapTransactionRecord:
            coins.append(tx.valueIn.coin)
            tx.valueOut.flatMap { coins.append($0.coin) }

        case let tx as ApproveTransactionRecord: coins.append(tx.value.coin)
        case let tx as ContractCallTransactionRecord:
            if tx.value.value != 0 {
                coins.append(tx.value.coin)
            }
            coins.append(contentsOf: tx.incomingInternalETHs.map({ $0.value.coin }))
            coins.append(contentsOf: tx.incomingEip20Events.map({ $0.value.coin }))
            coins.append(contentsOf: tx.outgoingEip20Events.map({ $0.value.coin }))

        case let tx as BitcoinIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as BitcoinOutgoingTransactionRecord:
            tx.fee.flatMap { coins.append($0.coin) }
            coins.append(tx.value.coin)

        case let tx as BinanceChainIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as BinanceChainOutgoingTransactionRecord:
            coins.append(tx.fee.coin)
            coins.append(tx.value.coin)

        default: ()
        }

        if let evmTransaction = transaction as? EvmTransactionRecord, !evmTransaction.foreignTransaction {
            coins.append(evmTransaction.fee.coin)
        }

        return Array(Set(coins))
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

    var rawTransaction: String? {
        service.rawTransaction(hash: transaction.transactionHash)
    }

}
