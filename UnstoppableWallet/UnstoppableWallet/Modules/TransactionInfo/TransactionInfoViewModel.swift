import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class TransactionInfoViewModel {
    private let disposeBag = DisposeBag()

    private let service: TransactionInfoService
    private let factory: TransactionInfoViewItemFactory

    private var rates = [Coin: CurrencyValue]()
    private var viewItemsRelay = PublishRelay<[[TransactionInfoModule.ViewItem]]>()
    private var resendActionRelay = PublishRelay<(TransactionInfoModule.Option, String)>()
    private var explorerViewItem: TransactionInfoModule.ViewItem

    init(service: TransactionInfoService, factory: TransactionInfoViewItemFactory) {
        self.service = service
        self.factory = factory

        explorerViewItem = factory.explorerViewItem(record: service.transactionItem.record, testMode: service.testMode)

        subscribe(disposeBag, service.ratesSignal) { [weak self] in self?.updateRates(rates: $0) }
        subscribe(disposeBag, service.transactionItemUpdatedObservable) { [weak self] in self?.updateTransactionItem() }

        service.fetchRates(coins: coinsForRates, timestamp: service.transactionItem.record.date.timeIntervalSince1970)
    }

    private var coinsForRates: [Coin] {
        var coins = [Coin?]()

        switch service.transactionItem.record {
        case let tx as EvmIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as EvmOutgoingTransactionRecord: coins.append(tx.value.coin)
        case let tx as SwapTransactionRecord:
            coins.append(tx.valueIn.coin)
            tx.valueOut.flatMap { coins.append($0.coin) }

        case let tx as ApproveTransactionRecord: coins.append(tx.value.coin)
        case let tx as ContractCallTransactionRecord:
            if !tx.value.zeroValue {
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

        if let evmTransaction = service.transactionItem.record as? EvmTransactionRecord, !evmTransaction.foreignTransaction {
            coins.append(evmTransaction.fee.coin)
        }

        return Array(Set(coins.compactMap({ $0 })))
    }

    private func updateTransactionItem() {
        viewItemsRelay.accept(viewItems)
    }

    private func updateRates(rates: [Coin: CurrencyValue]) {
        self.rates = rates

        viewItemsRelay.accept(viewItems)
    }

}

extension TransactionInfoViewModel {

    var viewItems: [[TransactionInfoModule.ViewItem]] {
        factory.items(transaction: service.transactionItem.record, rates: rates, lastBlockInfo: service.lastBlockInfo) + [[explorerViewItem]]
    }

    var viewItemsDriver: Signal<[[TransactionInfoModule.ViewItem]]> {
        viewItemsRelay.asSignal()
    }

    var resendActionDriver: Signal<(TransactionInfoModule.Option, String)> {
        resendActionRelay.asSignal()
    }

    var rawTransaction: String? {
        service.rawTransaction(hash: service.transactionItem.record.transactionHash)
    }

    func didTapOption(action: TransactionInfoModule.Option) {
        resendActionRelay.accept((action, service.transactionItem.record.transactionHash))
    }

}
