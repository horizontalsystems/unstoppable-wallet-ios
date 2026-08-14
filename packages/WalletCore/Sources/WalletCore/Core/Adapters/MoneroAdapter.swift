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
    let transactionRecordsSubject = PublishSubject<[MoneroTransactionRecord]>()
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
    private let accountId: String
    private let accountsSubject = PublishSubject<[MoneroKit.AccountInfo]>()

    init(wallet: Wallet, restoreSettings: RestoreSettings, node: Node) throws {
        let logger = Core.shared.logger.scoped(with: "MoneroKit")
        let activeAccount = UInt32(Core.shared.localStorage.moneroActiveAccount(accountId: wallet.account.id))

        switch wallet.account.type {
        case let .mnemonic(words, passphrase, _):
            kit = try MoneroKit.Kit(
                wallet: .bip39(seed: words, passphrase: passphrase),
                account: activeAccount,
                restoreHeight: UInt64(restoreSettings.birthdayHeight ?? 0),
                walletId: wallet.account.id,
                node: node,
                networkType: Self.networkType,
                reachabilityManager: Core.shared.reachabilityManager,
                logger: logger
            )

        case let .moneroWatchAccount(address, viewKey):
            kit = try MoneroKit.Kit(
                wallet: .watch(address: address, viewKey: viewKey),
                account: activeAccount,
                restoreHeight: UInt64(restoreSettings.birthdayHeight ?? 0),
                walletId: wallet.account.id,
                node: node,
                networkType: Self.networkType,
                reachabilityManager: Core.shared.reachabilityManager,
                logger: logger
            )

        case let .moneroMnemonic(words, passphrase):
            kit = try MoneroKit.Kit(
                wallet: .legacy(seed: words, passphrase: passphrase),
                account: activeAccount,
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
        accountId = wallet.account.id

        balanceState = .notSynced(error: AppError.unknownError.localizedDescription)
        kit.delegate = self
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> MoneroTransactionRecord {
        let blockHeight = transaction.blockHeight > 0 ? Int(transaction.blockHeight) : nil

        switch transaction.type {
        case .outgoing, .sentToSelf:
            return MoneroOutgoingTransactionRecord(
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
                memo: transaction.memo,
                txSecretKey: transaction.txKey
            )
        case .incoming:
            return MoneroIncomingTransactionRecord(
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

        case let .syncing(progress, remainingBlockCount):
            return .syncing(progress: min(99, progress), remaining: max(1, remainingBlockCount), lastBlockDate: nil)

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
        balanceState = adapterStateFromKit()
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

    func accountsUpdated(accounts: [MoneroKit.AccountInfo]) {
        // A persisted selection can point past the wallet's account list (e.g. after a fresh
        // restore on a new device) - fall back to the first account.
        if !accounts.isEmpty, !accounts.contains(where: { $0.index == kit.activeAccount }) {
            setActiveAccount(index: 0)
        }

        accountsSubject.onNext(accounts)
    }

    func balanceDidChange(balanceInfo: MoneroKit.BalanceInfo) {
        moneroBalanceDataSubject.onNext(moneroBalanceData(balanceInfo: balanceInfo))
    }

    func walletStateDidChange(state _: MoneroKit.WalletState) {
        balanceState = adapterStateFromKit()
        lastBlockUpdatedSubject.onNext(())
    }

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        var records = [MoneroTransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }
}

extension MoneroAdapter {
    var accounts: [MoneroKit.AccountInfo] {
        kit.accounts
    }

    var activeAccountIndex: UInt32 {
        kit.activeAccount
    }

    var accountsObservable: Observable<[MoneroKit.AccountInfo]> {
        accountsSubject.asObservable()
    }

    /// Switching needs no kit restart: the wallet scans all accounts in one pass, so this only
    /// changes which account balances, addresses and transactions are reported.
    /// Balance, accounts and transactions re-emit through the kit's delegate callbacks on its
    /// serial event queue - emitting into the Rx subjects directly from this thread would
    /// overlap those emissions (RxSwift subjects must not receive concurrent events).
    func setActiveAccount(index: UInt32) {
        guard index != kit.activeAccount else { return }

        Core.shared.localStorage.setMoneroActiveAccount(accountId: accountId, index: Int(index))
        kit.setActiveAccount(index)

        depositAddressSubject.send(.completed(receiveAddress))
    }

    func createAccount(label: String?) throws -> MoneroKit.AccountInfo {
        try kit.createAccount(label: label)
    }

    func setAccountLabel(index: UInt32, label: String) throws {
        try kit.setAccountLabel(accountIndex: index, label: label)
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

    func estimateFee(amount: MoneroSendAmount, address: String, priority: MoneroKit.SendPriority) throws -> Decimal {
        let fee = try kit.estimateFee(address: address, amount: convertToPiconero(amount: amount), priority: priority)
        return Decimal(fee) / coinRate
    }

    @discardableResult func send(to address: String, amount: MoneroSendAmount, priority: MoneroKit.SendPriority, memo: String?, selectedKeyImages: [String]? = nil) throws -> [String] {
        try kit.send(to: address, amount: convertToPiconero(amount: amount), priority: priority, memo: memo, selectedKeyImages: selectedKeyImages)
    }

    /// Takes the wallet mutex - never call from the main thread.
    func unspentOutputs() throws -> [MoneroKit.UnspentOutput] {
        try kit.unspentOutputs()
    }

    /// Timestamps of known transactions by hash, for labeling outputs in the selection UI.
    func transactionTimestamps() -> [String: Int] {
        Dictionary(kit.transactions(descending: true, type: nil, limit: nil).map { ($0.hash, $0.timestamp) }, uniquingKeysWith: { first, _ in first })
    }

    func subaddress(index: Int) -> String? {
        kit.usedAddresses.first { $0.index == index }?.address
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
                    case (is MoneroIncomingTransactionRecord, .incoming): return transaction
                    case (is MoneroOutgoingTransactionRecord, .outgoing): return transaction
                    case let (tx as MoneroOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(paginationData: String?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        let moneroFilter: TransactionFilterType?
        switch filter {
        case .all: moneroFilter = nil
        case .incoming: moneroFilter = .incoming
        case .outgoing: moneroFilter = .outgoing
        default: return Single.just([])
        }

        let transactions = kit.transactions(fromHash: paginationData, descending: true, type: moneroFilter, limit: limit).map {
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

    var usedAddresses: [UsedAddress] {
        kit.usedAddresses.map {
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
        switch accountType {
        case let .mnemonic(words, passphrase, _):
            return (try? Kit.key(wallet: .bip39(seed: words, passphrase: passphrase), privateKey: privateKey, spendKey: spendKey)) ?? ""

        case let .moneroWatchAccount(address, viewKey):
            return (try? Kit.key(wallet: .watch(address: address, viewKey: viewKey), privateKey: privateKey, spendKey: spendKey)) ?? ""

        default: return ""
        }
    }

    static func address(accountType: AccountType) -> String {
        switch accountType {
        case let .mnemonic(words, passphrase, _):
            return (try? Kit.address(wallet: .bip39(seed: words, passphrase: passphrase), account: 0, index: 1)) ?? ""

        case let .moneroWatchAccount(address, viewKey):
            return (try? Kit.address(wallet: .watch(address: address, viewKey: viewKey), account: 0, index: 0)) ?? ""

        default: return ""
        }
    }
}

public enum MoneroSendAmount {
    case value(Decimal)
    case all(Decimal)

    var value: Decimal {
        switch self {
        case let .all(value): return value
        case let .value(value): return value
        }
    }
}

extension MoneroKit.SendPriority {
    static func from(string: String) -> MoneroKit.SendPriority? {
        switch string {
        case MoneroKit.SendPriority.default.description:
            return MoneroKit.SendPriority.default
        case MoneroKit.SendPriority.low.description:
            return MoneroKit.SendPriority.low
        case MoneroKit.SendPriority.medium.description:
            return MoneroKit.SendPriority.medium
        case MoneroKit.SendPriority.high.description:
            return MoneroKit.SendPriority.high
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
        }
    }

    var level: ValueLevel {
        switch self {
        case .low, .high:
            return .warning
        case .medium, .default:
            return .regular
        }
    }
}
