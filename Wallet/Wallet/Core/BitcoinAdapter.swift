import Foundation
import WalletKit
import RealmSwift

class BitcoinAdapter {
    private let walletKit: WalletKit
    private var unspentOutputsNotificationToken: NotificationToken?
    private var transactionsNotificationToken: NotificationToken?

    weak var listener: IAdapterListener?

    let coin: Coin

    var balance: Int {
        var balance = 0

        for output in walletKit.unspentOutputsRealmResults {
            balance += output.value
        }

        return balance
    }

    init(words: [String], networkType: WalletKit.NetworkType = .mainNet) {
        switch networkType {
        case .mainNet: coin = Bitcoin()
        case .testNet: coin = BitcoinTestNet()
        case .regTest: coin = BitcoinRegTest()
        }

        let realmFileName = "\(coin.name).realm"

        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let configuration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

        walletKit = WalletKit(withWords: words, realmConfiguration: configuration, networkType: networkType)

        unspentOutputsNotificationToken = walletKit.unspentOutputsRealmResults.observe { [weak self] changes in
            self?.listener?.updateBalance()
        }

        transactionsNotificationToken = walletKit.transactionsRealmResults.observe { [weak self] changes in
            self?.onTransactionsChanged(changes: changes)
        }
    }

    deinit {
        unspentOutputsNotificationToken?.invalidate()
        transactionsNotificationToken?.invalidate()
    }

    private func onTransactionsChanged(changes: RealmCollectionChange<Results<Transaction>>) {
        if case let .update(transactions, _, insertions, modifications) = changes {
            if !insertions.isEmpty {
                handle(transactions: insertions.map { transactions[$0] })
            }
            if !modifications.isEmpty {
                handle(transactions: modifications.map { transactions[$0] })
            }
        }
    }

    private func handle(transactions: [Transaction]) {
        let records = transactions.map { tx -> TransactionRecord in
            var totalInput: Int = 0
            var totalOutput: Int = 0
            var fromAddresses = [String]()
            var toAddresses = [String]()

            for input in tx.inputs {
                if let previousOutput = input.previousOutput, previousOutput.publicKey != nil {
                    totalInput += previousOutput.value
                }

                if input.previousOutput?.publicKey == nil {
                    if let address = input.address {
                        fromAddresses.append(address)
                    } else {
                        fromAddresses.append("stub from address")
                    }
                }
            }

            for output in tx.outputs {
                if output.publicKey != nil {
                    totalOutput += output.value
                } else if let address = output.address {
                    toAddresses.append(address)
                }
            }

            let record = TransactionRecord()
            record.transactionHash = tx.reversedHashHex
            record.coinCode = coin.code
            record.from = fromAddresses.first ?? "no from address"
            record.to = toAddresses.first ?? "no to address"
            record.amount = Int(totalOutput - totalInput)
            record.fee = 0
            record.incoming = record.amount > 0
            record.blockHeight = tx.block?.height ?? 0
            record.confirmed = tx.block != nil
            record.timestamp = tx.block?.header?.timestamp ?? 0

            print(record)

            return record
        }

        listener?.handle(transactionRecords: records)
    }

}

extension BitcoinAdapter: IAdapter {

    func showInfo() {
        walletKit.showRealmInfo()
    }

    func start() throws {
        try walletKit.start()
    }

    func send(to address: String, value: Int) throws {
        try walletKit.send(to: address, value: value)
    }

    func validate(address: String) -> Bool {
        return true
    }

}
