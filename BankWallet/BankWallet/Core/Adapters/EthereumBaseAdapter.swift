import Foundation
import HSEthereumKit
import RxSwift

class EthereumBaseAdapter {
    private let transactionCompletionThreshold = 12

    let coin: Coin

    let ethereumKit: EthereumKit
    let decimal: Int

    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState = .synced

    let balanceUpdatedSignal = Signal()
    let lastBlockHeightUpdatedSignal = Signal()
    let stateUpdatedSignal = Signal()

    init(coin: Coin, ethereumKit: EthereumKit, decimal: Int) {
        self.coin = coin
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
        let mineAddress = ethereumKit.receiveAddress.lowercased()

        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from.lowercased() == mineAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to.lowercased() == mineAddress
        )

        return TransactionRecord(
                transactionHash: transaction.hash,
                blockHeight: transaction.blockNumber,
                amount: transaction.amount * (from.mine ? -1 : 1),
                timestamp: Double(transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return Single.just([])
    }

    func transactionsSingle(hashFrom: String?, limit: Int) -> Single<[TransactionRecord]> {
        return transactionsObservable(hashFrom: hashFrom, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}

extension EthereumBaseAdapter {
    var confirmationsThreshold: Int {
        return 12
    }

    var lastBlockHeight: Int? {
        return ethereumKit.lastBlockHeight
    }

    var debugInfo: String {
        return ethereumKit.debugInfo
    }

    var refreshable: Bool {
        return true
    }

    func start() {
    }

    func clear() {
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return PaymentRequestAddress(address: paymentAddress)
    }

    var receiveAddress: String {
        return ethereumKit.receiveAddress
    }

}

extension EthereumBaseAdapter {

    public func onUpdate(transactions: [EthereumTransaction]) {
        transactionRecordsSubject.onNext(transactions.map { transactionRecord(fromTransaction: $0) })
    }

    public func onUpdateBalance() {
        balanceUpdatedSignal.notify()
    }

    public func onUpdateLastBlockHeight() {
        lastBlockHeightUpdatedSignal.notify()
    }

    public func onUpdateSyncState() {
        switch state {
        case .synced:
            self.state = .synced
            stateUpdatedSignal.notify()
        case .notSynced:
            self.state = .notSynced
            stateUpdatedSignal.notify()
        case .syncing:
            self.state = .synced
            stateUpdatedSignal.notify()
        }
    }

}
