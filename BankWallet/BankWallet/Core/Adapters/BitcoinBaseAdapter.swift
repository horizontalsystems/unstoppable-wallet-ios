import BitcoinCore
import Hodler
import RxSwift

class BitcoinBaseAdapter {
    static let defaultConfirmationsThreshold = 3

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
        var myInputsTotalValue: Int = 0
        var myOutputsTotalValue: Int = 0
        var allInputsMine = true
        var lockInfo: TransactionLockInfo?
        let inputs = transaction.inputs
        let outputs = transaction.outputs.filter({ $0.address != nil })

        for input in inputs {
            if input.mine, let value = input.value {
                myInputsTotalValue += value
            } else {
                allInputsMine = false
            }
        }

        for output in outputs {
            if output.mine {
                myOutputsTotalValue += output.value
            }

            if let pluginId = output.pluginId, pluginId == HodlerPlugin.id,
               let hodlerOutputData = output.pluginData as? HodlerOutputData,
               let approximateUnlockTime = hodlerOutputData.approximateUnlockTime {

                lockInfo = TransactionLockInfo(
                        lockedUntil: Date(timeIntervalSince1970: Double(approximateUnlockTime)),
                        originalAddress: hodlerOutputData.addressString
                )
            }
        }

        var amount = myOutputsTotalValue - myInputsTotalValue

        var resolvedFee: Int? = nil
        if allInputsMine {
            let fee = myInputsTotalValue - outputs.reduce(0) { totalOutput, output in totalOutput + output.value }
            amount += fee
            resolvedFee = fee
        }

        let incoming = amount > 0
        let sentToSelf = allInputsMine && !outputs.contains(where: { !$0.mine })

        if sentToSelf {
            amount = -1 * outputs.filter({ !$0.changeOutput }).reduce(0) { totalOutput, output in totalOutput + output.value }
        }

        let from = incoming ? inputs.filter({ !$0.mine }).compactMap({ $0.address }).first : nil
        let to = allInputsMine ? outputs.filter({ !$0.mine }).compactMap({ $0.address }).first : nil

        return TransactionRecord(
                uid: transaction.uid,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                interTransactionIndex: 0,
                blockHeight: transaction.blockHeight,
                amount: Decimal(amount) / coinRate,
                fee: resolvedFee.map { Decimal($0) / coinRate },
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                failed: transaction.status == .invalid,
                from: from,
                to: to,
                sentToSelf: sentToSelf,
                lockInfo: lockInfo
        )
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
        abstractKit.debugInfo
    }

    func start() {
        abstractKit.start()
    }

    func stop() {
        abstractKit.stop()
    }

    func refresh() {
        abstractKit.start()
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

    func balanceUpdated(balance: BalanceInfo) {
        balanceUpdatedSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockHeightUpdatedSignal.notify()
    }

    func kitStateUpdated(state: BitcoinCore.KitState) {
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
        stateUpdatedSignal.asObservable()
    }

    var balanceUpdatedObservable: Observable<Void> {
        balanceUpdatedSignal.asObservable()
    }

    var balance: Decimal {
        Decimal(abstractKit.balance.spendable) / coinRate
    }

    var balanceLocked: Decimal? {
        let value = Decimal(abstractKit.balance.unspendable) / coinRate
        return value > 0 ? value : nil
    }

}

extension BitcoinBaseAdapter {

    func availableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData] = [:]) -> Decimal {
        let amount = (try? abstractKit.maxSpendableValue(toAddress: address, feeRate: feeRate, pluginData: pluginData)) ?? 0
        return Decimal(amount) / coinRate
    }

    func maximumSendAmount(pluginData: [UInt8: IBitcoinPluginData] = [:]) -> Decimal? {
        try? abstractKit.maxSpendLimit(pluginData: pluginData).flatMap { Decimal($0) / coinRate }
    }

    func minimumSendAmount(address: String?) -> Decimal {
        Decimal(abstractKit.minSpendableValue(toAddress: address)) / coinRate
    }

    func validate(address: String, pluginData: [UInt8: IBitcoinPluginData] = [:]) throws {
        try abstractKit.validate(address: address, pluginData: pluginData)
    }

    func fee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData] = [:]) -> Decimal {
        do {
            let amount = convertToSatoshi(value: amount)
            let fee = try abstractKit.fee(for: amount, toAddress: address, feeRate: feeRate, pluginData: pluginData)
            return Decimal(fee) / coinRate
        } catch {
            return 0
        }
    }

    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData] = [:]) -> Single<Void> {
        let satoshiAmount = convertToSatoshi(value: amount)

        return Single.create { [weak self] observer in
            do {
                if let adapter = self {
                    _ = try adapter.abstractKit.send(to: address, value: satoshiAmount, feeRate: feeRate, pluginData: pluginData)
                }
                observer(.success(()))
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    var statusInfo: [(String, Any)] {
        abstractKit.statusInfo
    }

}

extension BitcoinBaseAdapter: ITransactionsAdapter {

    var confirmationsThreshold: Int {
        BitcoinBaseAdapter.defaultConfirmationsThreshold
    }

    var lastBlockHeight: Int? {
        abstractKit.lastBlockInfo?.height
    }

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        lastBlockHeightUpdatedSignal.asObservable()
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        abstractKit.transactions(fromUid: from?.uid, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}

extension BitcoinBaseAdapter: IDepositAdapter {

    var receiveAddress: String {
        abstractKit.receiveAddress()
    }

}
