import Foundation
import HSEthereumKit
import RxSwift

class EthereumBaseAdapter {
    private let transactionCompletionThreshold = 12

    let coin: Coin

    let ethereumKit: EthereumKit
    let decimal: Int
    private let addressParser: IAddressParser

    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState = .synced

    let balanceUpdatedSignal = Signal()
    let lastBlockHeightUpdatedSignal = Signal()
    let stateUpdatedSignal = Signal()

    init(coin: Coin, ethereumKit: EthereumKit, decimal: Int, addressParser: IAddressParser) {
        self.coin = coin
        self.ethereumKit = ethereumKit
        self.decimal = decimal
        self.addressParser = addressParser
    }

    func balanceDecimal(balanceString: String?, decimal: Int) -> Decimal {
        if let balanceString = balanceString, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        return 0
    }

    func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return Single.just([])
    }

    func sendSingle(to address: String, amount: String, feeRatePriority: FeeRatePriority) -> Single<Void> {
        return Single.just(())
    }

    func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
        let mineAddress = ethereumKit.receiveAddress.lowercased()

        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from.lowercased() == mineAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to.lowercased() == mineAddress
        )

        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.amount) {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.hash,
                blockHeight: transaction.blockNumber,
                amount: amount,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    func createSendError(from error: Error) -> Error {
        if let error = error as? EthereumKitError.ResponseError, case .connectionError(_) = error {
            return SendTransactionError.connection
        } else {
            return SendTransactionError.unknown
        }
    }

    func kitPriority(from priority: FeeRatePriority) -> FeePriority {
        switch priority {
        case .lowest: return .lowest
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .highest: return .highest
        }
    }

}

extension EthereumBaseAdapter {

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
    }

    func clear() {
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        let paymentData = addressParser.parse(paymentAddress: paymentAddress)
        return PaymentRequestAddress(address: paymentData.address, amount: paymentData.amount.map { Decimal($0) })
    }

    var receiveAddress: String {
        return ethereumKit.receiveAddress
    }

    func transactionsSingle(hashFrom: String?, limit: Int) -> Single<[TransactionRecord]> {
        return transactionsObservable(hashFrom: hashFrom, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func sendSingle(to address: String, amount: Decimal, feeRatePriority: FeeRatePriority) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let amountString = String(describing: roundedDecimal)

        return sendSingle(to: address, amount: amountString, feeRatePriority: feeRatePriority)
    }

}

extension EthereumBaseAdapter {

    public func onUpdate(transactions: [EthereumTransaction]) {
        transactionRecordsSubject.onNext(transactions.map { transactionRecord(fromTransaction: $0) })
    }

    public func onUpdateBalance() {
        balanceUpdatedSignal.notify()
    }

    public func onUpdateLastBlockHeight() {
        lastBlockHeightUpdatedSignal.notify()
    }

    public func onUpdateSyncState() {
        switch state {
        case .synced:
            self.state = .synced
            stateUpdatedSignal.notify()
        case .notSynced:
            self.state = .notSynced
            stateUpdatedSignal.notify()
        case .syncing:
            self.state = .synced
            stateUpdatedSignal.notify()
        }
    }

}
