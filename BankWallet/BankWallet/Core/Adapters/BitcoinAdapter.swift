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
    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()
    let progressSubject: BehaviorSubject<Double>

    init(words: [String], coin: BitcoinKit.Coin) {
        wordsHash = words.joined()
        bitcoinKit = BitcoinKit(withWords: words, coin: coin)
        progressSubject = BehaviorSubject(value: 0)
        bitcoinKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let record = TransactionRecord()

        record.transactionHash = transaction.transactionHash
        record.amount = Double(transaction.amount) / coinRate
        record.timestamp = transaction.timestamp ?? 0

        if let blockHeight = transaction.blockHeight, let lastBlockInfo = bitcoinKit.lastBlockInfo {
            let confirmations = lastBlockInfo.height - blockHeight + 1
            if confirmations >= transactionCompletionThreshold {
                record.status = .completed
            } else {
                record.status = .verifying
                record.verifyProgress = Double(confirmations) / Double(transactionCompletionThreshold)
            }
        } else {
            record.status = .processing
        }

        transaction.from.forEach {
            let address = TransactionAddress()
            address.address = $0.address
            address.mine = $0.mine
            record.from.append(address)
        }
        transaction.to.forEach {
            let address = TransactionAddress()
            address.address = $0.address
            address.mine = $0.mine
            record.to.append(address)
        }

        return record
    }

}

extension BitcoinAdapter: IAdapter {

    var balance: Double {
        return Double(bitcoinKit.balance) / coinRate
    }

    var lastBlockHeight: Int {
        return bitcoinKit.lastBlockInfo?.height ?? 0
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
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
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
