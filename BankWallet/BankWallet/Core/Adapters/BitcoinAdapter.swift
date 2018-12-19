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
    let stateSubject = PublishSubject<AdapterState>()
    let progressSubject: BehaviorSubject<Double>

    var state: AdapterState {
        didSet {
            stateSubject.onNext(state)
        }
    }

    init(words: [String], coin: BitcoinKit.Coin) {
        wordsHash = words.joined()
        bitcoinKit = BitcoinKit(withWords: words, coin: coin, minLogLevel: .error)
        progressSubject = BehaviorSubject(value: 0)

        state = .syncing(progressSubject: progressSubject)

        bitcoinKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let record = TransactionRecord()

        record.transactionHash = transaction.transactionHash
        record.blockHeight = transaction.blockHeight ?? 0
        record.amount = Double(transaction.amount) / coinRate
        record.timestamp = transaction.timestamp.map { Double($0) } ?? Date().timeIntervalSince1970

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

    var confirmationsThreshold: Int {
        return 6
    }

    var lastBlockHeight: Int? {
        return bitcoinKit.lastBlockInfo?.height
    }

    var debugInfo: String {
        return bitcoinKit.debugInfo
    }

    var refreshable: Bool {
        return false
    }

    func start() {
        try? bitcoinKit.start()
    }

    func refresh() {
        // not called
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

    func fee(for value: Double, address: String?, senderPay: Bool) throws -> Double {
        let amount = Int(value * coinRate)
        let fee = try bitcoinKit.fee(for: amount, toAddress: address, senderPay: senderPay)
        return Double(fee) / coinRate
    }

    func validate(address: String) throws {
        try bitcoinKit.validate(address: address)
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        let paymentData = bitcoinKit.parse(paymentAddress: paymentAddress)
        return PaymentRequestAddress(address: paymentData.address, amount: paymentData.amount)
    }

    var receiveAddress: String {
        return bitcoinKit.receiveAddress
    }

}

extension BitcoinAdapter: BitcoinKitDelegate {

    func transactionsUpdated(bitcoinKit: BitcoinKit, inserted: [TransactionInfo], updated: [TransactionInfo], deleted: [Int]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

    func balanceUpdated(bitcoinKit: BitcoinKit, balance: Int) {
        balanceSubject.onNext(Double(balance) / coinRate)
    }

    func lastBlockInfoUpdated(bitcoinKit: BitcoinKit, lastBlockInfo: BlockInfo) {
        lastBlockHeightSubject.onNext(lastBlockInfo.height)
    }

    public func kitStateUpdated(state: BitcoinKit.KitState) {
        switch state {
        case .synced:
            self.state = .synced
        case .notSynced:
            self.state = .notSynced
        case .syncing(let progress):
            progressSubject.onNext(progress)

            if case .syncing = self.state {
                // do nothing
            } else {
                self.state = .syncing(progressSubject: progressSubject)
            }
        }
    }

}

extension BitcoinAdapter {

    static func bitcoinAdapter(words: [String], testMode: Bool) -> BitcoinAdapter {
        let network: BitcoinKit.Network = testMode ? .testNet : .mainNet
        return BitcoinAdapter(words: words, coin: .bitcoin(network: network))
    }

    static func bitcoinCashAdapter(words: [String], testMode: Bool) -> BitcoinAdapter {
        let network: BitcoinKit.Network = testMode ? .testNet : .mainNet
        return BitcoinAdapter(words: words, coin: .bitcoinCash(network: network))
    }

}
