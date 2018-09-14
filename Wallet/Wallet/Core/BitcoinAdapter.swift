import Foundation
import WalletKit
import RealmSwift
import RxSwift

class BitcoinAdapter {
    private let walletKit: WalletKit
    private let transactionCompletionThreshold = 6

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

        if let blockHeight = transaction.blockHeight {
            let confirmations = walletKit.lastBlockHeight - blockHeight + 1
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
                from: transaction.from,
                to: transaction.to,
                amount: Double(transaction.amount) / 100_000_000,
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
        return Double(walletKit.balance) / 100_000_000
    }

    var lastBlockHeight: Int {
        return walletKit.lastBlockHeight
    }

    var transactionRecords: [TransactionRecord] {
        return walletKit.transactions.map { transactionRecord(fromTransaction: $0) }
    }

    func showInfo() {
        walletKit.showRealmInfo()
    }

    func start() throws {
        try walletKit.start()
    }

    func clear() throws {
        try walletKit.clear()
    }

    func send(to address: String, value: Int) throws {
        try walletKit.send(to: address, value: value)
    }

    func fee(for value: Int, senderPay: Bool) throws -> Int {
        return try walletKit.fee(for: value, senderPay: senderPay)
    }

    func validate(address: String) -> Bool {
        return true
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
        balanceSubject.onNext(Double(balance) / 100_000_000)
    }

    public func lastBlockHeightUpdated(walletKit: WalletKit, lastBlockHeight: Int) {
        lastBlockHeightSubject.onNext(lastBlockHeight)
    }

    public func progressUpdated(walletKit: WalletKit, progress: Double) {
        progressSubject.onNext(progress)
    }

}
