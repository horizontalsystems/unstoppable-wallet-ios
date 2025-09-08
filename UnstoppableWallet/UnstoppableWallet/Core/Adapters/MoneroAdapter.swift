import Combine
import Foundation
import HdWalletKit
import HsToolKit
import MarketKit
import MoneroKit
import RxSwift

class MoneroAdapter {
    static let networkType: MoneroKit.NetworkType = .mainnet
    static let confirmationsThreshold = Int(Kit.confirmationsThreshold)

    var coinRate: Decimal { 1_000_000_000_000 } // pow(10, 12)

    private let kit: MoneroKit.Kit
    private let moneroBalanceDataSubject = PublishSubject<MoneroBalanceData>()
    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    let transactionRecordsSubject = PublishSubject<[BitcoinTransactionRecord]>()
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

    init(wallet: Wallet, restoreSettings: RestoreSettings, node: Node) throws {
        switch wallet.account.type {
        case let .mnemonic(words, passphrase, _):
            let logger = Core.shared.logger.scoped(with: "MoneroKit")

            kit = try MoneroKit.Kit(
                mnemonic: .bip39(seed: words, passphrase: passphrase),
                account: 0,
                restoreHeight: UInt64(restoreSettings.birthdayHeight ?? 0),
                walletId: wallet.account.id,
                node: node,
                networkType: Self.networkType,
                reachabilityManager: Core.shared.reachabilityManager,
                logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        token = wallet.token
        transactionSource = wallet.transactionSource

        balanceState = .notSynced(error: AppError.unknownError.localizedDescription)
        kit.delegate = self
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> BitcoinTransactionRecord {
        let blockHeight = transaction.blockHeight > 0 ? Int(transaction.blockHeight) : nil

        switch transaction.type {
        case .outgoing, .sentToSelf:
            return BitcoinOutgoingTransactionRecord(
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
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                amount: Decimal(transaction.amount) / coinRate,
                to: transaction.recipientAddress,
                sentToSelf: transaction.type == TransactionType.sentToSelf,
                memo: transaction.memo,
                replaceable: false
            )
        case .incoming:
            return BitcoinIncomingTransactionRecord(
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
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                amount: Decimal(transaction.amount) / coinRate,
                from: nil,
                to: transaction.recipientAddress,
                memo: transaction.memo
            )
        }
    }

    private func moneroBalanceData(balanceInfo: BalanceInfo) -> MoneroBalanceData {
        MoneroBalanceData(
            all: Decimal(balanceInfo.all) / coinRate,
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

        case let .syncing(progress, _):
            return .syncing(progress: progress, lastBlockDate: nil)

        case let .notSynced(error):
            return .notSynced(error: error.localizedDescription)

        case .idle:
            return .notSynced(error: AppError.noConnection.localizedDescription)
        }
    }

    public var explorerTitle: String {
        "Blockchair"
    }

    public func explorerUrl(transactionHash: String) -> String? {
        "https://blockchair.com/monero/transaction/\(transactionHash)"
    }

    public func explorerUrl(address _: String) -> String? {
        ""
    }
}

extension MoneroAdapter: IAdapter {
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

extension MoneroAdapter: MoneroKitDelegate {
    func subAddressesUpdated(subaddresses _: [MoneroKit.SubAddress]) {
        depositAddressSubject.send(.completed(receiveAddress))
    }

    func balanceDidChange(balanceInfo: MoneroKit.BalanceInfo) {
        moneroBalanceDataSubject.onNext(moneroBalanceData(balanceInfo: balanceInfo))
    }

    func walletStateDidChange(state _: MoneroKit.WalletState) {
        balanceState = adapterStateFromKit()
        lastBlockUpdatedSubject.onNext(())
    }

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
}

extension MoneroAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceData: BalanceData {
        moneroBalanceData.balanceData
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        moneroBalanceDataSubject.map(\.balanceData).asObservable()
    }
}

extension MoneroAdapter {
    var moneroBalanceData: MoneroBalanceData {
        moneroBalanceData(balanceInfo: kit.balanceInfo)
    }

    var moneroBalanceDataObservable: Observable<MoneroBalanceData> {
        moneroBalanceDataSubject.asObservable()
    }

    var minimumSendAmount: Decimal {
        0.0
    }

    func estimateFee(amount: MoneroSendAmount, address: String, priority: SendPriority) throws -> Decimal {
        let fee = try kit.estimateFee(address: address, amount: convertToPiconero(amount: amount), priority: priority)
        return Decimal(fee) / coinRate
    }

    func send(to address: String, amount: MoneroSendAmount, priority: SendPriority, memo: String?) throws {
        _ = try kit.send(to: address, amount: convertToPiconero(amount: amount), priority: priority, memo: memo)
    }

    func convertToPiconero(amount: MoneroSendAmount) -> SendAmount {
        switch amount {
        case .all:
            return .all
        case let .value(value):
            let coinValue: Decimal = value * coinRate
            let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: Int16(truncatingIfNeeded: 0), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let piconeroValue = NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
            return .value(piconeroValue)
        }
    }
}

extension MoneroAdapter: ITransactionsAdapter {
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
                    case (is BitcoinIncomingTransactionRecord, .incoming): return transaction
                    case (is BitcoinOutgoingTransactionRecord, .outgoing): return transaction
                    case let (tx as BitcoinOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(paginationData: String?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        let bitcoinFilter: TransactionFilterType?
        switch filter {
        case .all: bitcoinFilter = nil
        case .incoming: bitcoinFilter = .incoming
        case .outgoing: bitcoinFilter = .outgoing
        default: return Single.just([])
        }

        let transactions = kit.transactions(fromHash: paginationData, descending: true, type: bitcoinFilter, limit: limit).map {
            transactionRecord(fromTransaction: $0)
        }

        return Single.just(transactions)
    }

    func allTransactionsAfter(paginationData _: String?) -> Single<[TransactionRecord]> {
        Single.just([])
    }
}

extension MoneroAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(kit.receiveAddress)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        depositAddressSubject.eraseToAnyPublisher()
    }

    func usedAddresses(change: Bool) -> [UsedAddress] {
        if change { return [] }
        return kit.usedAddresses.map {
            UsedAddress(index: $0.index, address: $0.address, explorerUrl: nil, transactionsCount: $0.transactionsCount)
        }
    }
}

extension MoneroAdapter {
    struct MoneroBalanceData {
        let all: Decimal
        let unlocked: Decimal

        var balanceData: BalanceData {
            BalanceData(total: all, available: unlocked)
        }
    }
}

extension MoneroAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.removeAll(except: excludedWalletIds)
    }

    static func key(accountType: AccountType, privateKey: Bool, spendKey: Bool) -> String {
        guard case let .mnemonic(words, passphrase, _) = accountType else {
            return ""
        }

        return (try? Kit.key(mnemonic: .bip39(seed: words, passphrase: passphrase), privateKey: privateKey, spendKey: spendKey)) ?? ""
    }
}

enum MoneroSendAmount {
    case value(Decimal)
    case all(Decimal)

    var value: Decimal {
        switch self {
        case let .all(value): return value
        case let .value(value): return value
        }
    }
}

extension SendPriority {
    static func from(string: String) -> SendPriority? {
        switch string {
        case SendPriority.default.description:
            return SendPriority.default
        case SendPriority.low.description:
            return SendPriority.low
        case SendPriority.medium.description:
            return SendPriority.medium
        case SendPriority.high.description:
            return SendPriority.high
        case SendPriority.last.description:
            return SendPriority.last
        default:
            return nil
        }
    }

    var description: String {
        switch self {
        case .default:
            return "monero.priority.default".localized()
        case .low:
            return "monero.priority.low".localized()
        case .medium:
            return "monero.priority.medium".localized()
        case .high:
            return "monero.priority.high".localized()
        case .last:
            return "monero.priority.last".localized()
        }
    }

    var level: ValueLevel {
        switch self {
        case .low, .high:
            return .warning
        case .medium, .default:
            return .regular
        case .last:
            return .error
        }
    }
}
