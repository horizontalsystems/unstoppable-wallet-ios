import Foundation
import HSBitcoinKit
import RxSwift

class BitcoinBaseAdapter {
    let decimal = 8

    let coin: Coin

    private let bitcoinKit: BitcoinKit
    private let coinRate: Decimal
    private let addressParser: IAddressParser

    let lastBlockHeightUpdatedSignal = Signal()
    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState

    let balanceUpdatedSignal = Signal()
    let stateUpdatedSignal = Signal()

    init?(coin: Coin, kitCoin: BitcoinKit.Coin, authData: AuthData, newWallet: Bool, addressParser: IAddressParser) {
        self.coin = coin
        self.addressParser = addressParser

        coinRate = pow(10, decimal)

        bitcoinKit = BitcoinKit(withWords: authData.words, coin: kitCoin, walletId: authData.walletId, newWallet: newWallet, minLogLevel: .error)

        state = .syncing(progress: 0, lastBlockDate: nil)

        bitcoinKit.delegate = self
    }

    func feeRate(priority: FeeRatePriority) -> Int {
        fatalError("Method should be overridden in child class")
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let fromAddresses = transaction.from.map {
            TransactionAddress(address: $0.address, mine: $0.mine)
        }

        let toAddresses = transaction.to.map {
            TransactionAddress(address: $0.address, mine: $0.mine)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash,
                blockHeight: transaction.blockHeight,
                amount: Decimal(transaction.amount) / coinRate,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                from: fromAddresses,
                to: toAddresses
        )
    }

    func createSendError(from: Error) -> Error {
        return SendTransactionError.connection
    }

}

extension BitcoinBaseAdapter: IAdapter {

    var balance: Decimal {
        return Decimal(bitcoinKit.balance) / coinRate
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

    func stop() {
    }

    func refresh() {
        // not called
    }

    func clear() {
        try? bitcoinKit.clear()
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate
        return NSDecimalNumber(decimal: ValueFormatter.instance.round(value: coinValue, scale: 0, roundingMode: .plain)).intValue
    }

    func validate(address: String) throws {
        try bitcoinKit.validate(address: address)
    }

    func validate(amount: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address, feeRatePriority: feeRatePriority) {
            errors.append(.insufficientAmount)
        }
        return errors
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        let paymentData = addressParser.parse(paymentAddress: paymentAddress)
        return PaymentRequestAddress(address: paymentData.address, amount: paymentData.amount.map { Decimal($0) })
    }

    var receiveAddress: String {
        return bitcoinKit.receiveAddress
    }

    func sendSingle(to address: String, amount: Decimal, feeRatePriority: FeeRatePriority) -> Single<Void> {
        let satoshiAmount = convertToSatoshi(value: amount)
        let rate = feeRate(priority: feeRatePriority)

        return Single.create { [weak self] observer in
            do {
                try self?.bitcoinKit.send(to: address, value: satoshiAmount, feeRate: rate)
                observer(.success(()))
            } catch {
                observer(.error(self?.createSendError(from: error) ?? error))
            }

            return Disposables.create()
        }
    }

    func availableBalance(for address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return max(0, balance - fee(for: balance, address: address, feeRatePriority: feeRatePriority))
    }

    func fee(for value: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        do {
            let amount = convertToSatoshi(value: value)
            let fee = try bitcoinKit.fee(for: amount, toAddress: address, senderPay: true, feeRate: feeRate(priority: feeRatePriority))
            return Decimal(fee) / coinRate
        } catch SelectorError.notEnough(let maxFee) {
            return Decimal(maxFee) / coinRate
        } catch {
            return 0
        }
    }

    func transactionsSingle(hashFrom: String?, limit: Int) -> Single<[TransactionRecord]> {
        return bitcoinKit.transactions(fromHash: hashFrom, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}

extension BitcoinBaseAdapter: BitcoinKitDelegate {

    func transactionsUpdated(bitcoinKit: BitcoinKit, inserted: [TransactionInfo], updated: [TransactionInfo]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

    func transactionsDeleted(hashes: [String]) {
    }

    func balanceUpdated(bitcoinKit: BitcoinKit, balance: Int) {
        balanceUpdatedSignal.notify()
    }

    func lastBlockInfoUpdated(bitcoinKit: BitcoinKit, lastBlockInfo: BlockInfo) {
        lastBlockHeightUpdatedSignal.notify()
    }

    public func kitStateUpdated(state: BitcoinKit.KitState) {
        switch state {
        case .synced:
            if case .synced = self.state {
                return
            }

            self.state = .synced
            stateUpdatedSignal.notify()
        case .notSynced:
            if case .notSynced = self.state {
                return
            }

            self.state = .notSynced
            stateUpdatedSignal.notify()
        case .syncing(let progress):
            let newProgress = Int(progress * 100)
            let newDate = bitcoinKit.lastBlockInfo?.timestamp.map { Date(timeIntervalSince1970: Double($0)) }

            if case let .syncing(currentProgress, currentDate) = self.state, newProgress == currentProgress {
                if let currentDate = currentDate, let newDate = newDate, currentDate.isSameDay(as: newDate) {
                    return
                }
            }

            self.state = .syncing(progress: newProgress, lastBlockDate: newDate)
            stateUpdatedSignal.notify()
        }
    }

}
