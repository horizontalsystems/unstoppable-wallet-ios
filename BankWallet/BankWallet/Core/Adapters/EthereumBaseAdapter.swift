import Foundation
import HSEthereumKit
import RxSwift

class EthereumBaseAdapter {
    private let transactionCompletionThreshold = 12

    let coin: Coin

    let ethereumKit: EthereumKit
    let decimal: Int

    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState = .syncing(progressSubject: nil)

    let balanceUpdatedSignal = Signal()
    let lastBlockHeightUpdatedSignal = Signal()
    let stateUpdatedSignal = Signal()

    init(coin: Coin, ethereumKit: EthereumKit, decimal: Int) {
        self.coin = coin
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
        let amountEther = convertToValue(amount: transaction.value) ?? 0
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
                transactionHash: transaction.txHash,
                blockHeight: transaction.blockNumber > 0 ? transaction.blockNumber : nil,
                amount: amountEther * (from.mine ? -1 : 1),
                timestamp: Double(transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    private func convertToValue(amount: String) -> Decimal? {
        if let result = Decimal(string: amount) {
            return result / pow(10, decimal)
        }
        return nil
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

    public func transactionsUpdated(inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

    public func balanceUpdated(balance: Decimal) {
        balanceUpdatedSignal.notify()
    }

    public func lastBlockHeightUpdated(height: Int) {
        lastBlockHeightUpdatedSignal.notify()
    }

    public func kitStateUpdated(state: EthereumKit.KitState) {
        switch state {
        case .synced:
            if case .synced = self.state {
                // do nothing
            } else {
                self.state = .synced
                stateUpdatedSignal.notify()
            }
        case .notSynced:
            if case .notSynced = self.state {
                // do nothing
            } else {
                self.state = .notSynced
                stateUpdatedSignal.notify()
            }
        case .syncing:
            if case .syncing = self.state {
                // do nothing
            } else {
                self.state = .syncing(progressSubject: nil)
                stateUpdatedSignal.notify()
            }
        }
    }

}
