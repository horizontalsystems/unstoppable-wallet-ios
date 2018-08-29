import Foundation
import WalletKit
import RealmSwift
import RxSwift

class BitcoinAdapter {
    private let walletKit: WalletKit
    private var unspentOutputsNotificationToken: NotificationToken?
    private var transactionsNotificationToken: NotificationToken?

    let wordsHash: String
    let coin: Coin
    let balanceSubject = PublishSubject<Double>()
    let latestBlockHeightSubject = PublishSubject<Void>()
    let transactionRecordsSubject = PublishSubject<Void>()

    var balance: Double = 0 {
        didSet {
            balanceSubject.onNext(balance)
        }
    }

    init(words: [String], networkType: WalletKit.NetworkType = .mainNet) {
        wordsHash = words.joined()

        switch networkType {
        case .mainNet: coin = Bitcoin()
        case .testNet: coin = Bitcoin(networkSuffix: "T")
        case .regTest: coin = Bitcoin(networkSuffix: "R")
        }

        let realmFileName = "\(wordsHash)-\(coin.code).realm"

        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let configuration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

        walletKit = WalletKit(withWords: words, realmConfiguration: configuration, networkType: networkType)

        unspentOutputsNotificationToken = walletKit.unspentOutputsRealmResults.observe { [weak self] _ in
            self?.updateBalance()
        }

        transactionsNotificationToken = walletKit.transactionsRealmResults.observe { [weak self] _ in
            self?.transactionRecordsSubject.onNext(())
        }
    }

    deinit {
        unspentOutputsNotificationToken?.invalidate()
        transactionsNotificationToken?.invalidate()
    }

    private func updateBalance() {
        var satoshiBalance = 0

        for output in walletKit.unspentOutputsRealmResults {
            satoshiBalance += output.value
        }

        balance = Double(satoshiBalance) / 100000000
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        var totalInput: Int = 0
        var totalOutput: Int = 0
        var totalMineInput: Int = 0
        var totalMineOutput: Int = 0
        var fromAddresses = [String]()
        var toAddresses = [String]()

        for input in transaction.inputs {
            if let previousOutput = input.previousOutput {
                totalInput += previousOutput.value

                if previousOutput.publicKey != nil {
                    totalMineInput += previousOutput.value
                }
            }

            if input.previousOutput?.publicKey == nil {
                if let address = input.address {
                    fromAddresses.append(address)
                } else {
                    fromAddresses.append("stub from address")
                }
            }
        }

        for output in transaction.outputs {
            totalOutput += output.value

            if output.publicKey != nil {
                totalMineOutput += output.value
            } else if let address = output.address {
                toAddresses.append(address)
            }
        }

        let amount = totalMineOutput - totalMineInput
        let fee = totalInput - totalOutput

        return TransactionRecord(
                transactionHash: transaction.reversedHashHex,
                from: fromAddresses,
                to: toAddresses,
                amount: Double(amount) / 100000000,
                fee: Double(fee) / 100000000,
                blockHeight: transaction.block?.height,
                timestamp: transaction.block?.header?.timestamp
        )
    }

}

extension BitcoinAdapter: IAdapter {

    var id: String {
        return "\(wordsHash)-\(coin.code)"
    }

    var latestBlockHeight: Int {
        return walletKit.latestBlockHeight
    }

    var transactionRecords: [TransactionRecord] {
        var records = [TransactionRecord]()

        for transaction in walletKit.transactionsRealmResults {
            records.append(transactionRecord(fromTransaction: transaction))
        }

        return records
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

    var progressSubject: BehaviorSubject<Double> {
        return walletKit.progressSubject
    }

}
