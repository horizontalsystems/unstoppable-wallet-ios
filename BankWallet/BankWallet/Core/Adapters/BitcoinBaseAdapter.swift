import BitcoinCore
import RxSwift

class BitcoinBaseAdapter {
    static let defaultConfirmationsThreshold = 3

    var receiveAddressScriptType: ScriptType { return .p2pkh }
    var changeAddressScriptType: ScriptType { return .p2pkh }

    private let abstractKit: AbstractKit
    private let coinRate: Decimal = pow(10, 8)

    private let lastBlockHeightUpdatedSignal = Signal()
    private let stateUpdatedSignal = Signal()
    private let balanceUpdatedSignal = Signal()
    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState

    init(abstractKit: AbstractKit) {
        self.abstractKit = abstractKit

        state = .syncing(progress: 0, lastBlockDate: nil)
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let fromAddresses = transaction.from.map {
            TransactionAddress(address: $0.address, mine: $0.mine)
        }

        let toAddresses = transaction.to.map {
            TransactionAddress(address: $0.address, mine: $0.mine)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                interTransactionIndex: 0,
                blockHeight: transaction.blockHeight,
                amount: Decimal(transaction.amount) / coinRate,
                fee: transaction.fee.map { Decimal($0) / coinRate },
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                from: fromAddresses,
                to: toAddresses
        )
    }

    func createSendError(from: Error) -> Error {
        return SendTransactionError.connection
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: Int16(truncatingIfNeeded: 0), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }

    class func kitMode(from syncMode: SyncMode) -> BitcoinCore.SyncMode {
        switch syncMode {
        case .fast: return .api
        case .slow: return .full
        case .new: return .newWallet
        }
    }

}

extension BitcoinBaseAdapter: IAdapter {

    var debugInfo: String {
        return abstractKit.debugInfo
    }

    func start() {
        abstractKit.start()
    }

    func stop() {
        abstractKit.stop()
    }

    func refresh() {
        // not called
    }

}

extension BitcoinBaseAdapter: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
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

    func balanceUpdated(balance: Int) {
        balanceUpdatedSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockHeightUpdatedSignal.notify()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
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
            let newDate = abstractKit.lastBlockInfo?.timestamp.map { Date(timeIntervalSince1970: Double($0)) }

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

extension BitcoinBaseAdapter: IBalanceAdapter {

    var stateUpdatedObservable: Observable<Void> {
        return stateUpdatedSignal.asObservable()
    }

    var balanceUpdatedObservable: Observable<Void> {
        return balanceUpdatedSignal.asObservable()
    }

    var balance: Decimal {
        return Decimal(abstractKit.balance) / coinRate
    }

}

extension BitcoinBaseAdapter {

    func availableBalance(feeRate: Int, address: String?) -> Decimal {
        return max(0, balance - fee(amount: balance, feeRate: feeRate, address: address))
    }

    func validate(address: String) throws {
        try abstractKit.validate(address: address)
    }

    func fee(amount: Decimal, feeRate: Int, address: String?) -> Decimal {
        do {
            let amount = convertToSatoshi(value: amount)
            let fee = try abstractKit.fee(for: amount, toAddress: address, senderPay: true, feeRate: feeRate, changeScriptType: changeAddressScriptType)
            return Decimal(fee) / coinRate
        } catch BitcoinCoreErrors.UnspentOutputSelection.notEnough(let maxFee) {
            return Decimal(maxFee) / coinRate
        } catch {
            return 0
        }
    }

    func sendSingle(amount: Decimal, address: String, feeRate: Int) -> Single<Void> {
        let satoshiAmount = convertToSatoshi(value: amount)

        return Single.create { [weak self] observer in
            do {
                if let adapter = self {
                    _ = try adapter.abstractKit.send(to: address, value: satoshiAmount, feeRate: feeRate, changeScriptType: adapter.changeAddressScriptType)
                }
                observer(.success(()))
            } catch {
                observer(.error(self?.createSendError(from: error) ?? error))
            }

            return Disposables.create()
        }
    }

}

extension BitcoinBaseAdapter: ITransactionsAdapter {

    var confirmationsThreshold: Int {
        return BitcoinBaseAdapter.defaultConfirmationsThreshold
    }

    var lastBlockHeight: Int? {
        return abstractKit.lastBlockInfo?.height
    }

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        return lastBlockHeightUpdatedSignal.asObservable()
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return transactionRecordsSubject.asObservable()
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        return abstractKit.transactions(fromHash: from?.hash, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}

extension BitcoinBaseAdapter: IDepositAdapter {

    var receiveAddress: String {
        return abstractKit.receiveAddress(for: receiveAddressScriptType)
    }

}
