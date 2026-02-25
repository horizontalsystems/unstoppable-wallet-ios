import Combine
import Foundation
import HsToolKit
import MarketKit
import RxSwift
import ZanoKit

class ZanoAdapter {
    static let networkType: ZanoKit.NetworkType = .mainnet
    static let confirmationsThreshold = Int(Kit.confirmationsThreshold)

    var coinRate: Decimal { 1_000_000_000_000 } // pow(10, 12)

    private let kit: ZanoKit.Kit
    private let zanoBalanceDataSubject = PublishSubject<ZanoBalanceData>()
    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    let transactionRecordsSubject = PublishSubject<[ZanoTransactionRecord]>()
    private let depositAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
            syncing = balanceState.syncing
        }
    }

    private(set) var syncing: Bool = true

    let token: Token
    private let transactionSource: TransactionSource

    init(wallet: Wallet, restoreSettings: RestoreSettings, nodeUrl: String) throws {
        let logger = Core.shared.logger.scoped(with: "ZanoKit")

        switch wallet.account.type {
        case let .mnemonic(words, passphrase, _):
            let creationDate = RestoreHeight.getDate(height: Int64(restoreSettings.birthdayHeight ?? 0))
            let creationTimestamp = UInt64(creationDate.timeIntervalSince1970)
            kit = try ZanoKit.Kit(
                wallet: .bip39(seed: words, passphrase: passphrase, creationTimestamp: creationTimestamp),
                walletId: wallet.account.id,
                daemonAddress: nodeUrl,
                networkType: Self.networkType,
                reachabilityManager: Core.shared.reachabilityManager,
                logger: logger,
                zanoCoreLogLevel: -1
            )

        default:
            throw AdapterError.unsupportedAccount
        }

        token = wallet.token
        transactionSource = wallet.transactionSource

        balanceState = .notSynced(error: AppError.unknownError.localizedDescription)
        kit.delegate = self
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> ZanoTransactionRecord {
        let blockHeight = transaction.blockHeight > 0 ? Int(transaction.blockHeight) : nil

        switch transaction.type {
        case .outgoing, .sentToSelf:
            return ZanoOutgoingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.uid,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: blockHeight,
                confirmationsThreshold: Self.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: Decimal(transaction.fee) / coinRate,
                failed: transaction.isFailed,
                amount: Decimal(transaction.amount) / coinRate,
                to: transaction.recipientAddress,
                sentToSelf: transaction.type == TransactionType.sentToSelf,
                memo: transaction.memo
            )
        case .incoming:
            return ZanoIncomingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.uid,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: blockHeight,
                confirmationsThreshold: Self.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: Decimal(transaction.fee) / coinRate,
                failed: transaction.isFailed,
                amount: Decimal(transaction.amount) / coinRate,
                from: nil,
                to: transaction.recipientAddress,
                memo: transaction.memo
            )
        }
    }

    private func zanoBalanceData(balanceInfo: BalanceInfo) -> ZanoBalanceData {
        ZanoBalanceData(
            all: Decimal(balanceInfo.total) / coinRate,
            unlocked: Decimal(balanceInfo.unlocked) / coinRate
        )
    }

    private func adapterStateFromKit() -> AdapterState {
        let state = kit.walletState

        switch state {
        case .connecting:
            return .connecting

        case .synced:
            return .synced

        case let .syncing(progress, remainingBlockCount):
            return .syncing(progress: min(99, progress), remaining: max(1, remainingBlockCount), lastBlockDate: nil)

        case let .notSynced(error):
            return .notSynced(error: error.localizedDescription)

        case .idle:
            return .notSynced(error: AppError.noConnection.localizedDescription)
        }
    }

    public var explorerTitle: String {
        "Zano Explorer"
    }

    public func explorerUrl(transactionHash: String) -> String? {
        "https://explorer.zano.org/transaction/\(transactionHash)"
    }

    public func explorerUrl(address _: String) -> String? {
        ""
    }
}

extension ZanoAdapter: IAdapter {
    var isMainNet: Bool {
        true
    }

    var debugInfo: String {
        ""
    }

    func start() {
        kit.start()
    }

    func stop() {
        kit.stop()
    }

    func refresh() {
        kit.refresh()
    }

    func restart() {
        kit.restart()
    }

    var statusInfo: [(String, Any)] {
        kit.statusInfo
    }
}

extension ZanoAdapter: ZanoKitDelegate {
    func assetsDidChange(assets _: [AssetInfo]) {
        // For now, we only handle native ZANO asset
    }

    func balancesDidChange(balances: [BalanceInfo]) {
        if let nativeBalance = balances.first(where: { $0.isNative }) {
            zanoBalanceDataSubject.onNext(zanoBalanceData(balanceInfo: nativeBalance))
        }
    }

    func walletStateDidChange(state _: WalletState) {
        balanceState = adapterStateFromKit()
        lastBlockUpdatedSubject.onNext(())
    }

    func transactionsDidChange(transactions: [TransactionInfo]) {
        let nativeTransactions = transactions.filter(\.isNative)
        let records = nativeTransactions.map { transactionRecord(fromTransaction: $0) }
        if !records.isEmpty {
            transactionRecordsSubject.onNext(records)
        }
    }
}

extension ZanoAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceData: BalanceData {
        zanoBalanceData.balanceData
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        zanoBalanceDataSubject.map(\.balanceData).asObservable()
    }
}

extension ZanoAdapter {
    var zanoBalanceData: ZanoBalanceData {
        zanoBalanceData(balanceInfo: kit.nativeBalance)
    }

    var zanoBalanceDataObservable: Observable<ZanoBalanceData> {
        zanoBalanceDataSubject.asObservable()
    }

    var minimumSendAmount: Decimal {
        0.0
    }

    func estimateFee() -> Decimal {
        let fee = kit.estimateFee(priority: .default)
        return Decimal(fee) / coinRate
    }

    func send(to address: String, amount: ZanoSendAmount, memo: String?) throws {
        _ = try kit.send(to: address, assetId: ZanoAssetId, amount: convertToAtomic(amount: amount), priority: .default, memo: memo)
    }

    func convertToAtomic(amount: ZanoSendAmount) -> SendAmount {
        switch amount {
        case .all:
            return .all
        case let .value(value):
            let coinValue: Decimal = value * coinRate
            let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: Int16(truncatingIfNeeded: 0), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let atomicValue = NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
            return .value(atomicValue)
        }
    }
}

extension ZanoAdapter: ITransactionsAdapter {
    func rawTransaction(hash _: String) -> String? {
        nil
    }

    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: Int(kit.lastBlockInfo), timestamp: nil)
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
                    case (is ZanoIncomingTransactionRecord, .incoming): return transaction
                    case (is ZanoOutgoingTransactionRecord, .outgoing): return transaction
                    case let (tx as ZanoOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(paginationData: String?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        let zanoFilter: TransactionFilterType?
        switch filter {
        case .all: zanoFilter = nil
        case .incoming: zanoFilter = .incoming
        case .outgoing: zanoFilter = .outgoing
        default: return Single.just([])
        }

        let transactions = kit.transactions(assetId: ZanoAssetId, fromHash: paginationData, descending: true, type: zanoFilter, limit: limit).map {
            transactionRecord(fromTransaction: $0)
        }

        return Single.just(transactions)
    }

    func allTransactionsAfter(paginationData _: String?) -> Single<[TransactionRecord]> {
        Single.just([])
    }
}

extension ZanoAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(kit.receiveAddress)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        depositAddressSubject.eraseToAnyPublisher()
    }

    var usedAddresses: [UsedAddress] {
        []
    }
}

extension ZanoAdapter {
    struct ZanoBalanceData {
        let all: Decimal
        let unlocked: Decimal

        var balanceData: BalanceData {
            BalanceData(total: all, available: unlocked)
        }
    }
}

extension ZanoAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.removeAll(except: excludedWalletIds)
    }

    static func isValidAddress(_ address: String) -> Bool {
        Kit.isValid(address: address, networkType: networkType)
    }
}

enum ZanoSendAmount {
    case value(Decimal)
    case all(Decimal)

    var value: Decimal {
        switch self {
        case let .all(value): return value
        case let .value(value): return value
        }
    }
}
