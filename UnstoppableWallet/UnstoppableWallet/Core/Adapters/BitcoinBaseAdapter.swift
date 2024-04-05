import BitcoinCore
import Foundation
import HdWalletKit
import Hodler
import HsToolKit
import MarketKit
import RxSwift

class BitcoinBaseAdapter {
    static let confirmationsThreshold = 3
    private let abstractKit: AbstractKit

    var coinRate: Decimal { 100_000_000 } // pow(10, 8)

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    private let syncMode: BitcoinCore.SyncMode
    let transactionRecordsSubject = PublishSubject<[BitcoinTransactionRecord]>()

    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
            syncing = balanceState.syncing
        }
    }

    private(set) var syncing: Bool = true

    let token: Token
    private let transactionSource: TransactionSource

    init(abstractKit: AbstractKit, wallet: Wallet, syncMode: BitcoinCore.SyncMode) {
        self.abstractKit = abstractKit
        token = wallet.token
        transactionSource = wallet.transactionSource
        self.syncMode = syncMode

        balanceState = .notSynced(error: AppError.unknownError)
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

        var memo: String? = nil
        for output in transaction.outputs {
            // get last memo (we use last output for memo op_return)
            if output.memo != nil {
                memo = output.memo
            }

            guard output.value > 0 else {
                continue
            }

            if let pluginId = output.pluginId, pluginId == HodlerPlugin.id,
               let hodlerOutputData = output.pluginData as? HodlerOutputData,
               let approximateUnlockTime = hodlerOutputData.approximateUnlockTime
            {
                lockInfo = TransactionLockInfo(
                    lockedUntil: Date(timeIntervalSince1970: Double(approximateUnlockTime)),
                    originalAddress: hodlerOutputData.addressString,
                    lockTimeInterval: hodlerOutputData.lockTimeInterval
                )
            }

            if anyNotMineToAddress == nil, let address = output.address, !output.mine {
                anyNotMineToAddress = address
            }
        }

        switch transaction.type {
        case .incoming:
            return BitcoinIncomingTransactionRecord(
                token: token,
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
                from: anyNotMineFromAddress,
                memo: memo
            )
        case .outgoing:
            return BitcoinOutgoingTransactionRecord(
                token: token,
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
                sentToSelf: false,
                memo: memo,
                replaceable: transaction.replaceable && transaction.status != .invalid
            )
        case .sentToSelf:
            return BitcoinOutgoingTransactionRecord(
                token: token,
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
                to: transaction.outputs.first(where: { !$0.changeOutput })?.address ?? transaction.outputs.first?.address,
                sentToSelf: true,
                memo: memo,
                replaceable: transaction.replaceable && transaction.status != .invalid
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

    private func balanceData(balanceInfo: BalanceInfo) -> BalanceData {
        LockedBalanceData(
            available: Decimal(balanceInfo.spendable) / coinRate,
            locked: Decimal(balanceInfo.unspendableTimeLocked) / coinRate,
            notRelayed: Decimal(balanceInfo.unspendableNotRelayed) / coinRate
        )
    }

    open var explorerTitle: String {
        fatalError("Must be overridden by subclass")
    }

    open func explorerUrl(transactionHash _: String) -> String? {
        fatalError("Must be overridden by subclass")
    }

    open func explorerUrl(address _: String) -> String? {
        fatalError("Must be overridden by subclass")
    }

    private var showSyncedUntil: Bool {
        if case .blockchair = syncMode {
            return false
        } else {
            return true
        }
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

    func transactionsDeleted(hashes _: [String]) {}

    func balanceUpdated(balance: BalanceInfo) {
        balanceSubject.onNext(balanceData(balanceInfo: balance))
    }

    func lastBlockInfoUpdated(lastBlockInfo _: BlockInfo) {
        lastBlockUpdatedSubject.onNext(())
    }

    func kitStateUpdated(state: BitcoinCore.KitState) {
        switch state {
        case .synced:
            if case .synced = balanceState {
                return
            }

            balanceState = .synced
        case let .notSynced(error):
            let converted = error.convertedError

            if case let .notSynced(appError) = balanceState, "\(converted)" == "\(appError)" {
                return
            }

            balanceState = .notSynced(error: converted)
        case let .syncing(progress):
            let newProgress = Int(progress * 100)
            let newDate = showSyncedUntil
                ? abstractKit.lastBlockInfo?.timestamp.map { Date(timeIntervalSince1970: Double($0)) }
                : nil

            if case let .syncing(currentProgress, currentDate) = balanceState, newProgress == currentProgress {
                if let currentDate, let newDate, currentDate.isSameDay(as: newDate) {
                    return
                }
            }

            balanceState = .syncing(progress: newProgress, lastBlockDate: newDate)
        case let .apiSyncing(newCount):
            let newCountDescription = "balance.searching.count".localized("\(newCount)")
            if case let .customSyncing(_, secondary, _) = balanceState, newCountDescription == secondary {
                return
            }

            balanceState = .customSyncing(main: "balance.searching".localized(), secondary: newCountDescription, progress: nil)
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
    func availableBalance(feeRate: Int, address: String?, memo: String?, unspentOutputs: [UnspentOutputInfo]?, pluginData: [UInt8: IBitcoinPluginData] = [:]) -> Decimal {
        let amount = (try? abstractKit.maxSpendableValue(toAddress: address, memo: memo, feeRate: feeRate, unspentOutputs: unspentOutputs, pluginData: pluginData)) ?? 0
        return Decimal(amount) / coinRate
    }

    func maximumSendAmount(pluginData: [UInt8: IBitcoinPluginData] = [:]) -> Decimal? {
        try? abstractKit.maxSpendLimit(pluginData: pluginData).flatMap { Decimal($0) / coinRate }
    }

    func minimumSendAmount(address: String?) -> Decimal {
        do {
            return try Decimal(abstractKit.minSpendableValue(toAddress: address)) / coinRate
        } catch {
            return 0
        }
    }

    func validate(address: String, pluginData: [UInt8: IBitcoinPluginData]) throws {
        try abstractKit.validate(address: address, pluginData: pluginData)
    }

    func validate(address: String) throws {
        try validate(address: address, pluginData: [:])
    }

    func sendInfo(amount: Decimal, feeRate: Int, address: String?, memo: String?, unspentOutputs: [UnspentOutputInfo]?, pluginData: [UInt8: IBitcoinPluginData] = [:]) throws -> SendInfo {
        let amount = convertToSatoshi(value: amount)

        let info = try abstractKit.sendInfo(for: amount, toAddress: address, memo: memo, feeRate: feeRate, unspentOutputs: unspentOutputs, pluginData: pluginData)
        return SendInfo(
            unspentOutputs: info.unspentOutputs.map(\.info),
            fee: Decimal(info.fee) / coinRate,
            changeValue: info.changeValue.map { Decimal($0) / coinRate },
            changeAddress: info.changeAddress?.stringValue
        )
    }

    var unspentOutputs: [UnspentOutputInfo] {
        abstractKit.unspentOutputs
    }

    func sendSingle(amount: Decimal, address: String, memo: String?, feeRate: Int, unspentOutputs: [UnspentOutputInfo]?, pluginData: [UInt8: IBitcoinPluginData] = [:], sortMode: TransactionDataSortMode, rbfEnabled: Bool, logger: Logger) -> Single<Void> {
        let satoshiAmount = convertToSatoshi(value: amount)
        let sortType = convertToKitSortMode(sort: sortMode)

        return Single.create { [weak self] observer in
            do {
                if let adapter = self {
                    logger.debug("Sending to \(String(reflecting: adapter.abstractKit))", save: true)
                    _ = try adapter.abstractKit.send(to: address, memo: memo, value: satoshiAmount, feeRate: feeRate, sortType: sortType, rbfEnabled: rbfEnabled, unspentOutputs: unspentOutputs, pluginData: pluginData)
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

    var syncingObservable: Observable<Void> {
        balanceStateSubject.map { _ in () }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        lastBlockUpdatedSubject.asObservable()
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func transactionsObservable(token _: Token?, filter: TransactionTypeFilter, address _: String?) -> Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
            .map { transactions in
                transactions.compactMap { transaction -> TransactionRecord? in
                    switch (transaction, filter) {
                    case (_, .all): return transaction
                    case (is BitcoinIncomingTransactionRecord, .incoming): return transaction
                    case (is BitcoinOutgoingTransactionRecord, .outgoing): return transaction
                    case let (tx as BitcoinOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(from: TransactionRecord?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        let bitcoinFilter: TransactionFilterType?
        switch filter {
        case .all: bitcoinFilter = nil
        case .incoming: bitcoinFilter = .incoming
        case .outgoing: bitcoinFilter = .outgoing
        default: return Single.just([])
        }

        let transactions = abstractKit.transactions(fromUid: from?.uid, type: bitcoinFilter, limit: limit)
            .map {
                transactionRecord(fromTransaction: $0)
            }

        return Single.just(transactions)
    }

    func rawTransaction(hash: String) -> String? {
        abstractKit.rawTransaction(transactionHash: hash)
    }

    func speedUpTransactionInfo(transactionHash: String) -> (originalTransactionSize: Int, feeRange: Range<Int>)? {
        abstractKit.speedUpTransactionInfo(transactionHash: transactionHash)
    }

    func cancelTransactionInfo(transactionHash: String) -> (originalTransactionSize: Int, feeRange: Range<Int>)? {
        abstractKit.cancelTransactionInfo(transactionHash: transactionHash)
    }

    func speedUpTransaction(transactionHash: String, minFee: Int) throws -> (replacment: ReplacementTransaction, record: BitcoinTransactionRecord) {
        let replacment = try abstractKit.speedUpTransaction(transactionHash: transactionHash, minFee: minFee)
        return (replacment: replacment, record: transactionRecord(fromTransaction: replacment.info))
    }

    func cancelTransaction(transactionHash: String, minFee: Int) throws -> (replacment: ReplacementTransaction, record: BitcoinTransactionRecord) {
        let replacment = try abstractKit.cancelTransaction(transactionHash: transactionHash, minFee: minFee)
        return (replacment: replacment, record: transactionRecord(fromTransaction: replacment.info))
    }

    func send(replacementTransaction: ReplacementTransaction) throws -> FullTransaction {
        try abstractKit.send(replacementTransaction: replacementTransaction)
    }
}

extension BitcoinBaseAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(abstractKit.receiveAddress())
    }

    func usedAddresses(change: Bool) -> [UsedAddress] {
        abstractKit.usedAddresses(change: change).map {
            let url = explorerUrl(address: $0.address).flatMap { URL(string: $0) }
            return UsedAddress(index: $0.index, address: $0.address, explorerUrl: url)
        }.sorted { $0.index < $1.index }
    }
}

class DepositAddress {
    let address: String

    init(_ receiveAddress: String) {
        address = receiveAddress
    }
}

public struct UsedAddress: Hashable {
    let index: Int
    let address: String
    let explorerUrl: URL?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(address)
        hasher.combine(explorerUrl?.absoluteString)
    }
}

struct SendInfo {
    static let empty: Self = .init(unspentOutputs: [], fee: 0, changeValue: nil, changeAddress: nil)

    public let unspentOutputs: [UnspentOutputInfo]
    public let fee: Decimal
    public let changeValue: Decimal?
    public let changeAddress: String?
}
