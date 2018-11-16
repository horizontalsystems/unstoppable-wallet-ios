import Foundation
import HSEthereumKit
import RealmSwift
import RxSwift

class EthereumAdapter {
    private let ethereumKit: EthereumKit
    private let transactionCompletionThreshold = 12
    private let coinRate: Double = pow(10, 18)

    let wordsHash: String
    let balanceSubject = PublishSubject<Double>()
    let progressSubject: BehaviorSubject<Double>
    let stateSubject = PublishSubject<AdapterState>()
    let lastBlockHeightSubject = PublishSubject<Int>()
    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    let state: AdapterState = .synced

    init(words: [String], coin: EthereumKit.Coin) {
        wordsHash = words.joined()
        progressSubject = BehaviorSubject(value: 1)
        ethereumKit = EthereumKit(withWords: words, coin: coin, debugPrints: false)
        ethereumKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
        let amountEther = convertToValue(amount: transaction.value) ?? 0
        let mineAddress = ethereumKit.receiveAddress.lowercased()

        let from = TransactionAddress()
        from.address = transaction.from
        from.mine = transaction.from.lowercased() == mineAddress

        let to = TransactionAddress()
        to.address = transaction.to
        to.mine = transaction.to.lowercased() == mineAddress

        let record = TransactionRecord()

        record.transactionHash = transaction.txHash
        record.blockHeight = transaction.blockNumber
        record.amount = amountEther * (from.mine ? -1 : 1)
        record.timestamp = transaction.timestamp

        record.from.append(from)
        record.to.append(to)

        return record
    }

    private func convertToValue(amount: String) -> Double? {
        if let result = Decimal(string: amount) {
            return Double(truncating: (result / pow(10, 18)) as NSNumber)
        }
        return nil
    }

}

extension EthereumAdapter: IAdapter {

    var balance: Double {
        return Double(ethereumKit.balance) / coinRate
    }

    var confirmationsThreshold: Int {
        return 12
    }

    var lastBlockHeight: Int? {
        return ethereumKit.lastBlockHeight
    }

    var debugInfo: String {
        return ethereumKit.debugInfo
    }

    func start() {
        ethereumKit.start()
    }

    func refresh() {
        ethereumKit.refresh()
    }

    func clear() {
        try? ethereumKit.clear()
    }

    func send(to address: String, value: Double, completion: ((Error?) -> ())?) {
        ethereumKit.send(to: address, value: value, completion: completion)
    }

    func fee(for value: Double, address: String?, senderPay: Bool) throws -> Double {
        return Double(ethereumKit.fee) / coinRate
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    var receiveAddress: String {
        return ethereumKit.receiveAddress
    }

}

extension EthereumAdapter: EthereumKitDelegate {

    public func transactionsUpdated(ethereumKit: EthereumKit, inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

    public func balanceUpdated(ethereumKit: EthereumKit, balance: BInt) {
        balanceSubject.onNext(Double(balance) / coinRate)
    }

}
