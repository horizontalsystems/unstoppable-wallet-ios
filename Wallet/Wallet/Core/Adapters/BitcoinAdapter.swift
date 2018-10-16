import Foundation
import WalletKit
import RealmSwift
import RxSwift

class BitcoinAdapter {
    private let walletKit: WalletKit
    private let transactionCompletionThreshold = 6
    private let coinRate: Double = pow(10, 8)

    let wordsHash: String
    let coin: Coin
    let balanceSubject = PublishSubject<Double>()
    let lastBlockHeightSubject = PublishSubject<Int>()
    let transactionRecordsSubject = PublishSubject<Void>()
    let progressSubject: BehaviorSubject<Double>

    init(words: [String], networkType: WalletKit.NetworkType) {
        wordsHash = words.joined()

        switch networkType {
        case .bitcoinMainNet: coin = Bitcoin()
        case .bitcoinTestNet: coin = Bitcoin(prefix: "t")
        case .bitcoinRegTest: coin = Bitcoin(prefix: "r")
        case .bitcoinCashMainNet: coin = BitcoinCash()
        case .bitcoinCashTestNet: coin = BitcoinCash(prefix: "t")
        }

        walletKit = WalletKit(withWords: words, networkType: networkType)

        progressSubject = BehaviorSubject(value: walletKit.progress)

        walletKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let status: TransactionStatus

        if let blockHeight = transaction.blockHeight, let lastBlockInfo = walletKit.lastBlockInfo {
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

    var id: String {
        return "\(wordsHash)-\(coin.code)"
    }

    var balance: Double {
        return Double(walletKit.balance) / coinRate
    }

    var lastBlockHeight: Int {
        return walletKit.lastBlockInfo?.height ?? 0
    }

    var transactionRecords: [TransactionRecord] {
        return walletKit.transactions.map { transactionRecord(fromTransaction: $0) }
    }

    func showInfo() {
        walletKit.showRealmInfo()
    }

    func start() {
        try? walletKit.start()
    }

    func refresh() {
        // stub!
    }

    func clear() {
        try? walletKit.clear()
    }

    func send(to address: String, value: Double, completion: ((Error?) -> ())?) {
        do {
            let amount = Int(value * coinRate)
            try walletKit.send(to: address, value: amount)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }

    func fee(for value: Double, senderPay: Bool) throws -> Double {
        let amount = Int(value * coinRate)
        let fee = try walletKit.fee(for: amount, senderPay: senderPay)
        return Double(fee) / coinRate
    }

    func validate(address: String) throws {
        try walletKit.validate(address: address)
    }

    var receiveAddress: String {
        return walletKit.receiveAddress
    }

}

extension BitcoinAdapter: BitcoinKitDelegate {

    public func transactionsUpdated(walletKit: WalletKit, inserted: [TransactionInfo], updated: [TransactionInfo], deleted: [Int]) {
        transactionRecordsSubject.onNext(())
    }

    public func balanceUpdated(walletKit: WalletKit, balance: Int) {
        balanceSubject.onNext(Double(balance) / coinRate)
    }

    public func lastBlockInfoUpdated(walletKit: WalletKit, lastBlockInfo: BlockInfo) {
        lastBlockHeightSubject.onNext(lastBlockInfo.height)
    }

    public func progressUpdated(walletKit: WalletKit, progress: Double) {
        progressSubject.onNext(progress)
    }

}
