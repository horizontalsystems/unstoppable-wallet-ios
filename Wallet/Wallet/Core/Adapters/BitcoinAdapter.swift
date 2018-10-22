import Foundation
import HSBitcoinKit
import RealmSwift
import RxSwift

class BitcoinAdapter {
    private let bitcoinKit: BitcoinKit
    private let transactionCompletionThreshold = 6
    private let coinRate: Double = pow(10, 8)

    let wordsHash: String
    let balanceSubject = PublishSubject<Double>()
    let lastBlockHeightSubject = PublishSubject<Int>()
    let transactionRecordsSubject = PublishSubject<Void>()
    let progressSubject: BehaviorSubject<Double>

    init(words: [String], coin: BitcoinKit.Coin) {
        wordsHash = words.joined()
        bitcoinKit = BitcoinKit(withWords: words, coin: coin)
        progressSubject = BehaviorSubject(value: bitcoinKit.progress)
        bitcoinKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let status: TransactionStatus

        if let blockHeight = transaction.blockHeight, let lastBlockInfo = bitcoinKit.lastBlockInfo {
            let confirmations = lastBlockInfo.height - blockHeight + 1
            if confirmations >= transactionCompletionThreshold {
                status = .completed
            } else {
                status = .verifying(progress: Double(confirmations) / Double(transactionCompletionThreshold))
            }
        } else {
            status = .processing
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash,
                from: transaction.from.map { TransactionAddress(address: $0.address, mine: $0.mine) },
                to: transaction.to.map { TransactionAddress(address: $0.address, mine: $0.mine) },
                amount: Double(transaction.amount) / coinRate,
                status: status,
                timestamp: transaction.timestamp
        )
    }

}

extension BitcoinAdapter: IAdapter {

    var balance: Double {
        return Double(bitcoinKit.balance) / coinRate
    }

    var lastBlockHeight: Int {
        return bitcoinKit.lastBlockInfo?.height ?? 0
    }

    var transactionRecords: [TransactionRecord] {
        return bitcoinKit.transactions.map { transactionRecord(fromTransaction: $0) }
    }

    var debugInfo: String {
        return bitcoinKit.debugInfo
    }

    func start() {
        try? bitcoinKit.start()
    }

    func refresh() {
        // stub!
    }

    func clear() {
        try? bitcoinKit.clear()
    }

    func send(to address: String, value: Double, completion: ((Error?) -> ())?) {
        do {
            let amount = Int(value * coinRate)
            try bitcoinKit.send(to: address, value: amount)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }

    func fee(for value: Double, senderPay: Bool) throws -> Double {
        let amount = Int(value * coinRate)
        let fee = try bitcoinKit.fee(for: amount, senderPay: senderPay)
        return Double(fee) / coinRate
    }

    func validate(address: String) throws {
        try bitcoinKit.validate(address: address)
    }

    var receiveAddress: String {
        return bitcoinKit.receiveAddress
    }

}

extension BitcoinAdapter: BitcoinKitDelegate {

    public func transactionsUpdated(bitcoinKit: BitcoinKit, inserted: [TransactionInfo], updated: [TransactionInfo], deleted: [Int]) {
        transactionRecordsSubject.onNext(())
    }

    public func balanceUpdated(bitcoinKit: BitcoinKit, balance: Int) {
        balanceSubject.onNext(Double(balance) / coinRate)
    }

    public func lastBlockInfoUpdated(bitcoinKit: BitcoinKit, lastBlockInfo: BlockInfo) {
        lastBlockHeightSubject.onNext(lastBlockInfo.height)
    }

    public func progressUpdated(bitcoinKit: BitcoinKit, progress: Double) {
        progressSubject.onNext(progress)
    }

}
