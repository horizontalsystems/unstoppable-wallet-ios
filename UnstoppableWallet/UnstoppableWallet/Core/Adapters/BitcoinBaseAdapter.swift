import BitcoinCore
import Hodler
import RxSwift
import HsToolKit
import MarketKit

class BitcoinBaseAdapter {
    static let confirmationsThreshold = 3

    private let abstractKit: AbstractKit
    private let coinRate: Decimal = pow(10, 8)

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    let transactionRecordsSubject = PublishSubject<[BitcoinTransactionRecord]>()

    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
            transactionState = balanceState
        }
    }
    private(set) var transactionState: AdapterState

    private let coin: PlatformCoin
    private let transactionSource: TransactionSource

    init(abstractKit: AbstractKit, wallet: WalletNew) {
        self.abstractKit = abstractKit
        coin = wallet.platformCoin
        transactionSource = wallet.transactionSource

        balanceState = .notSynced(error: AppError.unknownError)
        transactionState = balanceState
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> BitcoinTransactionRecord {
        var lockInfo: TransactionLockInfo?
        var anyNotMineFromAddress: String?
        var anyNotMineToAddress: String?

        for input in transaction.inputs {
            if anyNotMineFromAddress == nil, let address = input.address {
                anyNotMineFromAddress = address
            }
        }

        for output in transaction.outputs {
            guard output.value > 0 else {
                continue
            }

            if let pluginId = output.pluginId, pluginId == HodlerPlugin.id,
               let hodlerOutputData = output.pluginData as? HodlerOutputData,
               let approximateUnlockTime = hodlerOutputData.approximateUnlockTime {

                lockInfo = TransactionLockInfo(
                        lockedUntil: Date(timeIntervalSince1970: Double(approximateUnlockTime)),
                        originalAddress: hodlerOutputData.addressString
                )
            }
            if anyNotMineToAddress == nil, let address = output.address, !output.mine {
                anyNotMineToAddress = address
            }
        }

        switch transaction.type {
        case .incoming:
            return BitcoinIncomingTransactionRecord(
                    coin: coin,
                    source: transactionSource,
                    uid: transaction.uid,
                    transactionHash: transaction.transactionHash,
                    transactionIndex: transaction.transactionIndex,
                    blockHeight: transaction.blockHeight,
                    confirmationsThreshold: Self.confirmationsThreshold,
                    date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                    fee: transaction.fee.map { Decimal($0) / coinRate },
                    failed: transaction.status == .invalid,
                    lockInfo: lockInfo,
                    conflictingHash: transaction.conflictingHash,
                    showRawTransaction: transaction.status == .new || transaction.status == .invalid,
                    amount: Decimal(transaction.amount) / coinRate,
                    from: anyNotMineFromAddress
            )
        case .outgoing:
            return BitcoinOutgoingTransactionRecord(
                    coin: coin,
                    source: transactionSource,
                    uid: transaction.uid,
                    transactionHash: transaction.transactionHash,
                    transactionIndex: transaction.transactionIndex,
                    blockHeight: transaction.blockHeight,
                    confirmationsThreshold: Self.confirmationsThreshold,
                    date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                    fee: transaction.fee.map { Decimal($0) / coinRate },
                    failed: transaction.status == .invalid,
                    lockInfo: lockInfo,
                    conflictingHash: transaction.conflictingHash,
                    showRawTransaction: transaction.status == .new || transaction.status == .invalid,
                    amount: Decimal(transaction.amount) / coinRate,
                    to: anyNotMineToAddress,
                    sentToSelf: false
            )
        case .sentToSelf:
            return BitcoinOutgoingTransactionRecord(
                    coin: coin,
                    source: transactionSource,
                    uid: transaction.uid,
                    transactionHash: transaction.transactionHash,
                    transactionIndex: transaction.transactionIndex,
                    blockHeight: transaction.blockHeight,
                    confirmationsThreshold: Self.confirmationsThreshold,
                    date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                    fee: transaction.fee.map { Decimal($0) / coinRate },
                    failed: transaction.status == .invalid,
                    lockInfo: lockInfo,
                    conflictingHash: transaction.conflictingHash,
                    showRawTransaction: transaction.status == .new || transaction.status == .invalid,
                    amount: Decimal(transaction.amount) / coinRate,
                    to: anyNotMineToAddress,
                    sentToSelf: true
            )
        }
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: Int16(truncatingIfNeeded: 0), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }

    private func convertToKitSortMode(sort: TransactionDataSortMode) -> TransactionDataSortType {
        switch sort {
        case .shuffle: return .shuffle
        case .bip69: return .bip69
        }
    }

    class func kitMode(from syncMode: SyncMode) -> BitcoinCore.SyncMode {
        switch syncMode {
        case .fast: return .api
        case .slow: return .full
        case .new: return .newWallet
        }
    }

    class func bip(from derivation: MnemonicDerivation) -> Bip {
        switch derivation {
        case .bip44: return Bip.bip44
        case .bip49: return Bip.bip49
        case .bip84: return Bip.bip84
        }
    }

    private func balanceData(balanceInfo: BalanceInfo) -> BalanceData {
        BalanceData(
                balance: Decimal(balanceInfo.spendable) / coinRate,
                balanceLocked: Decimal(balanceInfo.unspendable) / coinRate
        )
    }

}

extension BitcoinBaseAdapter: IAdapter {

    var isMainNet: Bool {
        true
    }

    var debugInfo: String {
        abstractKit.debugInfo
    }

    func start() {
        balanceState = .syncing(progress: 0, lastBlockDate: nil)
        abstractKit.start()
    }

    func stop() {
        abstractKit.stop()
    }

    func refresh() {
        abstractKit.start()
    }

    var statusInfo: [(String, Any)] {
        abstractKit.statusInfo
    }

}

extension BitcoinBaseAdapter: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        var records = [BitcoinTransactionRecord]()

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
        balanceSubject.onNext(balanceData(balanceInfo: balance))
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockUpdatedSubject.onNext(())
    }

    func kitStateUpdated(state: BitcoinCore.KitState) {
        switch state {
        case .synced:
            if case .synced = balanceState {
                return
            }

            balanceState = .synced
        case .notSynced(let error):
            let converted = error.convertedError

            if case .notSynced(let appError) = balanceState, "\(converted)" == "\(appError)" {
                return
            }

            balanceState = .notSynced(error: converted)
        case .syncing(let progress):
            let newProgress = Int(progress * 100)
            let newDate = abstractKit.lastBlockInfo?.timestamp.map { Date(timeIntervalSince1970: Double($0)) }

            if case let .syncing(currentProgress, currentDate) = balanceState, newProgress == currentProgress {
                if let currentDate = currentDate, let newDate = newDate, currentDate.isSameDay(as: newDate) {
                    return
                }
            }

            balanceState = .syncing(progress: newProgress, lastBlockDate: newDate)
        case .apiSyncing(let newCount):
            if case .searchingTxs(let count) = balanceState, newCount == count {
                return
            }

            balanceState = .searchingTxs(count: newCount)
        }
    }

}

extension BitcoinBaseAdapter: IBalanceAdapter {

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceData: BalanceData {
        balanceData(balanceInfo: abstractKit.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceSubject.asObservable()
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

    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData] = [:], sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void> {
        let satoshiAmount = convertToSatoshi(value: amount)
        let sortType = convertToKitSortMode(sort: sortMode)

        return Single.create { [weak self] observer in
            do {
                if let adapter = self {
                    logger.debug("Sending to \(String(reflecting: adapter.abstractKit))", save: true)
                    _ = try adapter.abstractKit.send(to: address, value: satoshiAmount, feeRate: feeRate, sortType: sortType, pluginData: pluginData)
                }
                observer(.success(()))
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

}

extension BitcoinBaseAdapter: ITransactionsAdapter {

    var lastBlockInfo: LastBlockInfo? {
        abstractKit.lastBlockInfo.map { LastBlockInfo(height: $0.height, timestamp: $0.timestamp) }
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        balanceStateSubject.map { _ in () }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        lastBlockUpdatedSubject.asObservable()
    }

    func transactionsObservable(coin: PlatformCoin?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
                .map { transactions in
                    transactions.compactMap { transaction -> TransactionRecord? in
                        switch (transaction, filter) {
                        case (_, .all): return transaction
                        case (is BitcoinIncomingTransactionRecord, .incoming): return transaction
                        case (is BitcoinOutgoingTransactionRecord, .outgoing): return transaction
                        case (let tx as BitcoinOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                        default: return nil
                        }
                    }
                }
                .filter { !$0.isEmpty }
    }

    func transactionsSingle(from: TransactionRecord?, coin: PlatformCoin?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        let bitcoinFilter: TransactionFilterType?
        switch filter {
        case .all: bitcoinFilter = nil
        case .incoming: bitcoinFilter = .incoming
        case .outgoing: bitcoinFilter = .outgoing
        default: return Single.just([])
        }

        return abstractKit.transactions(fromUid: from?.uid, type: bitcoinFilter, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func rawTransaction(hash: String) -> String? {
        abstractKit.rawTransaction(transactionHash: hash)
    }

}

extension BitcoinBaseAdapter: IDepositAdapter {

    var receiveAddress: String {
        abstractKit.receiveAddress()
    }

}
