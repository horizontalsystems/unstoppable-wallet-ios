import HSEthereumKit
import RxSwift

class EthereumAdapter {
    private let ethereumKit: EthereumKit
    private let transactionCompletionThreshold = 12
    private let coinRate: Decimal = pow(10, 18)
    private let gWeiMultiply: Decimal = pow(10, 9)

    let lastBlockHeightUpdatedSignal = Signal()
    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState = .syncing(progressSubject: nil)

    let balanceUpdatedSignal = Signal()
    let stateUpdatedSignal = Signal()

    init(words: [String], coin: EthereumKit.Coin) {
        let infuraKey = Bundle.main.object(forInfoDictionaryKey: "InfuraApiKey") as? String
        let etherscanKey = Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String

        ethereumKit = EthereumKit(withWords: words, coin: coin, infuraKey: infuraKey ?? "", etherscanKey: etherscanKey ?? "", debugPrints: false)
        ethereumKit.delegate = self
    }

    private func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
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
                blockHeight: transaction.blockNumber,
                amount: amountEther * (from.mine ? -1 : 1),
                timestamp: Double(transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    private func convertToValue(amount: String) -> Decimal? {
        if let result = Decimal(string: amount) {
            return result / pow(10, 18)
        }
        return nil
    }

}

extension EthereumAdapter: IAdapter {

    var balance: Decimal {
        return Decimal(Double(ethereumKit.balance)) / coinRate
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

    var refreshable: Bool {
        return true
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

    func send(to address: String, value: Decimal, completion: ((Error?) -> ())?) {
        ethereumKit.send(to: address, value: NSDecimalNumber(decimal: value).doubleValue, completion: completion)
    }

    func fee(for value: Decimal, address: String?, senderPay: Bool) throws -> Decimal {
        // ethereum fee comes in GWei integer value

        let fee = Decimal(ethereumKit.fee) * gWeiMultiply / coinRate
        let balance = Decimal(Double(ethereumKit.balance)) / coinRate
        if balance > 0, balance - value - (senderPay ? fee : 0) < 0 {
            throw FeeError.insufficientAmount(fee: fee)
        }
        return fee
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

    func transactionsSingle(hashFrom: String?, limit: Int) -> Single<[TransactionRecord]> {
        return ethereumKit.transactions(fromHash: hashFrom, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
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
        balanceUpdatedSignal.notify()
    }

    public func kitStateUpdated(state: EthereumKit.KitState) {
        switch state {
        case .synced:
            if case .synced = self.state {
                // do nothing
            } else {
                self.state = .synced
                stateUpdatedSignal.notify()
                lastBlockHeightUpdatedSignal.notify()
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

extension EthereumAdapter {

    static func ethereumAdapter(words: [String], testMode: Bool) -> EthereumAdapter {
        let network: EthereumKit.NetworkType = testMode ? .testNet : .mainNet
        return EthereumAdapter(words: words, coin: .ethereum(network: network))
    }

}
