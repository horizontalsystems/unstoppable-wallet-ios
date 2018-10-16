import Foundation
import HSEthereumKit
import RealmSwift
import RxSwift

class EthereumAdapter {
    private let walletKit: EthereumKit
    private let transactionCompletionThreshold = 12
    private let coinRate: Double = pow(10, 18)

    let wordsHash: String
    let wordsHash2: String
    let coin: Coin
    let balanceSubject = PublishSubject<Double>()
    let progressSubject: BehaviorSubject<Double>
    let lastBlockHeightSubject = PublishSubject<Int>()
    let transactionRecordsSubject = PublishSubject<Void>()

    init(words: [String], network: Network) {
        wordsHash = words.joined()
        wordsHash2 = words.joined(separator: " ")

        switch network {
        case .mainnet: coin = Ethereum()
        case .kovan: coin = Ethereum(prefix: "k")
        case .ropsten: coin = Ethereum(prefix: "r")
        case .private: coin = Ethereum(prefix: "pr")
        }

        progressSubject = BehaviorSubject(value: 1)

        walletKit = EthereumKit(withWords: words, network: network, debugPrints: true)
        walletKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
        let status: TransactionStatus

        if transaction.confirmations == 0 {
            status = .processing
        } else if transaction.confirmations >= transactionCompletionThreshold {
            status = .completed
        } else {
            status = .verifying(progress: Double(transaction.confirmations) / Double(transactionCompletionThreshold))
        }
        let amountEther = convertToValue(amount: transaction.value) ?? 0

        let mineAddress = walletKit.receiveAddress.lowercased()
        let from = TransactionAddress(address: transaction.from, mine: transaction.from.lowercased() == mineAddress)
        let to = TransactionAddress(address: transaction.to, mine: transaction.to.lowercased() == mineAddress)
        return TransactionRecord(
                transactionHash: transaction.txHash,
                from: [from],
                to: [to],
                amount: amountEther * (from.mine ? -1 : 1),
                status: status,
                timestamp: transaction.timestamp
        )
    }

    private func convertToValue(amount: String) -> Double? {
        if let result = Decimal(string: amount) {
            return Double(truncating: (result / pow(10, 18)) as NSNumber)
        }
        return nil
    }

}

extension EthereumAdapter: IAdapter {

    var id: String {
        return "\(wordsHash)-\(coin.code)"
    }

    var balance: Double {
        return Double(walletKit.balance) / coinRate
    }

    var lastBlockHeight: Int {
        return 0
    }

    var transactionRecords: [TransactionRecord] {
        return walletKit.transactions.map { transactionRecord(fromTransaction: $0) }
    }

    func showInfo() {
        print(wordsHash2)
        walletKit.showRealmInfo()
    }

    func start() {
        walletKit.start()
    }

    func refresh() {
        walletKit.refresh()
    }

    func clear() {
        try? walletKit.clear()
    }

    func send(to address: String, value: Double, completion: ((Error?) -> ())?) {
        walletKit.send(to: address, value: Decimal(value), completion: completion)
    }

    func fee(for value: Double, senderPay: Bool) throws -> Double {
        return Double(walletKit.fee) / coinRate
    }

    func validate(address: String) throws {
        try walletKit.validate(address: address)
    }

    var receiveAddress: String {
        return walletKit.receiveAddress
    }

}

extension EthereumAdapter: EthereumKitDelegate {

    public func transactionsUpdated(walletKit: EthereumKit, inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int]) {
        transactionRecordsSubject.onNext(())
    }

    public func balanceUpdated(walletKit: EthereumKit, balance: BInt) {
        balanceSubject.onNext(Double(balance) / coinRate)
    }

}
