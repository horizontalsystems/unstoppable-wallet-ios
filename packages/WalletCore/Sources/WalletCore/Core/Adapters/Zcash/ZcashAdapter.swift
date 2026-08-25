import Combine
import Foundation
import GRDB
import HdWalletKit
import HsExtensions
import HsToolKit
import MarketKit
import RxRelay
import RxSwift
import UIKit
import ZcashLightClientKit

class ZcashAdapter {
    static let minimalThreshold: Decimal = 0.0004 // minimal transparent balance to shielding

    static let defaultZip317MarginalFee = ZcashSendService.defaultZip317MarginalFee
    static let zip317MarginalFeeRange = ZcashSendService.zip317MarginalFeeRange
    static let defaultTxExpiryHeightDelta = ZcashSendService.defaultTxExpiryHeightDelta

    static var networkType: NetworkType {
        Core.shared.testNetManager.testNetEnabled ? .testnet : .mainnet
    }

    static var defaultEndpoint: LightWalletEndpoint {
        endpoint(url: (networkType == .mainnet ? ZcashNode.defaultNodes : ZcashNode.defaultTestnetNodes)[0].url)
    }

    static func endpoint(url: URL) -> LightWalletEndpoint {
        LightWalletEndpoint(address: url.host ?? "zec.rocks", port: url.port ?? 443, secure: url.scheme != "http", streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000)
    }

    private let queue = DispatchQueue(label: "\(AppConfig.label).zcash-adapter", qos: .userInitiated)

    private let token: Token
    private let transactionSource: TransactionSource

    private let synchronizer: Synchronizer
    private let zCashAdapterStorage: ZcashAdapterStorage
    private let migrator: ZcashMigrator

    private let syncService: ZcashSyncService
    private let balanceService: ZcashBalanceService
    private let historyService: ZcashHistoryService
    private let sendService: ZcashSendService
    private let endpointService: ZcashEndpointService
    private let recordFactory: ZcashTransactionRecordFactory

    private let uniqueId: String
    private let birthday: BlockHeight
    private let initMode: WalletInitMode
    private var logger: HsToolKit.Logger?

    private(set) var network: ZcashNetwork

    init(wallet: Wallet, restoreSettings: RestoreSettings, endpoint: LightWalletEndpoint) throws {
        logger = Core.shared.logger.scoped(with: "ZCashKit")
//        logger = HsToolKit.Logger(minLogLevel: .debug)

        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        network = ZcashNetworkBuilder.network(for: Self.networkType)

        token = wallet.token
        transactionSource = wallet.transactionSource
        uniqueId = wallet.account.id

        var existingMode: WalletInitMode?
        if let dbUrl = try? ZcashFileStore.dataDbURL(uniqueId: uniqueId, network: network),
           ZcashFileStore.exist(url: dbUrl)
        {
            existingMode = .existingWallet
        }
        switch wallet.account.origin {
        case .created:
            // The height saved at account creation (and rewritten by a rescan) wins;
            // ignoring it here made a created wallet's rescan height silently vanish.
            // A saved height older than the freshest checkpoint means the user rescanned
            // for history: sync must run in restore mode. In newWallet mode the SDK creates
            // the account from the latest BUNDLED checkpoint (it does NOT snap to the chain
            // tip — verified against SDK 2.7 sources), so a fresh wallet still scans the
            // bundled-checkpoint→tip gap, which grows as the frozen pin ages.
            if let height = restoreSettings.birthdayHeight {
                birthday = max(height, network.constants.saplingActivationHeight)
                // Account creation writes exactly newBirthdayHeight, so any other value can
                // only come from a rescan and must scan history; a height above the bundled
                // checkpoint still starts from the nearest checkpoint below it.
                initMode = existingMode ?? (birthday == Self.newBirthdayHeight(network: network) ? .newWallet : .restoreWallet)
            } else {
                birthday = Self.newBirthdayHeight(network: network)
                initMode = existingMode ?? .newWallet
            }
        case .restored:
            if let height = restoreSettings.birthdayHeight {
                birthday = max(height, network.constants.saplingActivationHeight)
            } else {
                birthday = network.constants.saplingActivationHeight
            }
            initMode = existingMode ?? .restoreWallet
        }

        let seedData = [UInt8](seed)

        // initialize DB and get cached balances
        let databaseURL = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("zCash.storage")
        let dbPool = try DatabasePool(path: databaseURL.path)
        zCashAdapterStorage = try ZcashAdapterStorage(dbPool: dbPool)
        migrator = ZcashMigrator(uniqueId: uniqueId, threshold: Self.minimalThreshold, network: network, storage: zCashAdapterStorage, logger: logger)

        let initializer = try ZcashAdapter.initializer(network: network, uniqueId: uniqueId, endpoint: endpoint)
        synchronizer = SDKSynchronizer(initializer: initializer)

        balanceService = try ZcashBalanceService(uniqueId: uniqueId, storage: zCashAdapterStorage, migrator: migrator, logger: logger)
        historyService = ZcashHistoryService(synchronizer: synchronizer, queue: queue, logger: logger)
        let terminalStore = ZcashTerminalResubmissionStore(uniqueId: uniqueId, network: network.networkType.chainName, storage: zCashAdapterStorage)
        sendService = ZcashSendService(synchronizer: synchronizer, migrator: migrator, terminalStore: terminalStore, logger: logger)
        endpointService = ZcashEndpointService(synchronizer: synchronizer, network: network, endpoint: endpoint, logger: logger)
        recordFactory = ZcashTransactionRecordFactory(token: token, transactionSource: transactionSource, migrator: migrator)

        syncService = ZcashSyncService(
            synchronizer: synchronizer,
            network: network,
            seedData: seedData,
            birthday: birthday,
            initMode: initMode,
            queue: queue,
            balanceService: balanceService,
            historyService: historyService,
            sendService: sendService,
            migrator: migrator,
            logger: logger
        )

        balanceService.syncService = syncService
        sendService.syncService = syncService
        sendService.endpointService = endpointService
        sendService.historyService = historyService
        endpointService.syncService = syncService
        recordFactory.syncService = syncService
    }

    var uAddress: UnifiedAddress? {
        syncService.uAddress
    }

    var tAddress: TransparentAddress? {
        syncService.tAddress
    }

    var areFundsSpendable: Bool {
        syncService.areFundsSpendable
    }

    var spendMode: BalanceAdapterSpendMode {
        areFundsSpendable ? .allowedWhenSyncing : .fromBalanceState
    }

    var zCashBalanceData: ZcashBalanceData {
        balanceService.zCashBalanceData
    }

    var zCashBalanceDataPublisher: AnyPublisher<ZcashBalanceData, Never> {
        balanceService.$zCashBalanceData
    }

    var balanceState: AdapterState {
        syncService.state.adapterState
    }

    var syncing: Bool {
        syncService.syncing
    }

    var isIronwoodActive: Bool {
        migrator.ironwoodActive(latestHeight: syncService.lastBlockHeight)
    }

    var isPreparing: Bool {
        syncService.isPreparing
    }

    func getSingleUseTransparentAddress() async throws -> SingleUseTransparentAddress? {
        guard let account = try await synchronizer.listAccounts().first else {
            throw AppError.ZcashError.noReceiveAddress
        }

        return try await synchronizer.getSingleUseTransparentAddress(accountUUID: account.id)
    }

    func getCustomUnifiedAddress() async throws -> UnifiedAddress? {
        guard let account = try await synchronizer.listAccounts().first else {
            throw AppError.ZcashError.noReceiveAddress
        }

        return try await synchronizer.getCustomUnifiedAddress(accountUUID: account.id, receivers: [.orchard, .sapling])
    }

    // Used by AdapterManager to revert the stored selection on switch failure.
    var currentEndpointURL: URL? {
        endpointService.currentEndpointURL
    }

    func isEndpointAvailable(_ endpoint: LightWalletEndpoint) async -> Bool {
        await endpointService.isEndpointAvailable(endpoint)
    }

    func switchEndpoint(_ endpoint: LightWalletEndpoint) async throws {
        try await endpointService.switchEndpoint(endpoint)
    }

    func transactionRecord(fromTransaction transaction: ZcashTransactionWrapper) -> TransactionRecord {
        recordFactory.transactionRecord(fromTransaction: transaction)
    }

    public func wipe() -> AnyPublisher<Void, Error> {
        syncService.wipe()
    }
}

extension ZcashAdapter {
    static func estimateBirthdayHeight(date: Date, isMainnet: Bool = ZcashAdapter.networkType == .mainnet) -> BlockHeight {
        SDKSynchronizer.estimateBirthdayHeight(for: date, isMainnet: isMainnet)
    }

    public static func estimateBirthdayTime(for height: BlockHeight, isMainnet: Bool = ZcashAdapter.networkType == .mainnet) -> UInt32 {
        SDKSynchronizer.birthdayTime(for: height, isMainnet: isMainnet)
    }

    static func addresses(for accountType: AccountType, network: ZcashNetwork) async throws -> (unified: UnifiedAddress, transparent: TransparentAddress) {
        guard let seed = accountType.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let seedData = [UInt8](seed)
        let tool = DerivationTool(networkType: network.networkType)

        guard let unifiedSpendingKey = try? tool.deriveUnifiedSpendingKey(seed: seedData, accountIndex: .zero),
              let _ = try? tool.deriveUnifiedFullViewingKey(from: unifiedSpendingKey)
        else {
            throw AppError.ZcashError.cantCreateKeys
        }

        let uniqueId = UUID().uuidString
        let initializer = try ZcashAdapter.initializer(network: network, uniqueId: uniqueId)
        let synchronizer = SDKSynchronizer(initializer: initializer)

        let birthday = BlockHeight.ofLatestCheckpoint(network: network)

        let result = try await synchronizer.prepare(
            with: seedData,
            walletBirthday: birthday,
            for: .newWallet,
            name: "",
            keySource: nil
        )

        if case .seedRequired = result {
            throw AppError.ZcashError.seedRequired
        }

        guard let account = try await synchronizer.listAccounts().first else {
            throw AppError.ZcashError.noReceiveAddress
        }

        guard let uAddress = try? await synchronizer.getUnifiedAddress(accountUUID: account.id),
              let tAddress = try? await synchronizer.getTransparentAddress(accountUUID: account.id)
        else {
            throw AppError.ZcashError.noReceiveAddress
        }

        synchronizer.stop()

        return (uAddress, tAddress)
    }

    static func firstAddress(accountType: AccountType, addressType: AddressType) async throws -> String {
        let network = ZcashNetworkBuilder.network(for: networkType)
        let (uAddress, tAddress) = try await addresses(for: accountType, network: network)
        return addressType == .shielded ? uAddress.stringEncoded : tAddress.stringEncoded
    }
}

extension ZcashAdapter {
    public static func newBirthdayHeight(network: ZcashNetwork) -> Int {
        BlockHeight.ofLatestCheckpoint(network: network)
    }

    static func initializer(network: ZcashNetwork, uniqueId: String, endpoint: LightWalletEndpoint = defaultEndpoint) throws -> Initializer {
        // One-time cleanup: promote any pre-existing per-wallet sapling params
        // ("sapling-{spend,output}_<uniqueId>.params") to the shared, wallet-agnostic
        // location so existing users don't have to re-download ~51MB.
        ZcashFileStore.migrateSharedSaplingParamsIfNeeded()

        return try Initializer(
            cacheDbURL: nil,
            fsBlockDbRoot: ZcashFileStore.fsBlockDbRootURL(uniqueId: uniqueId, network: network),
            generalStorageURL: ZcashFileStore.generalStorageURL(uniqueId: uniqueId, network: network),
            dataDbURL: ZcashFileStore.dataDbURL(uniqueId: uniqueId, network: network),
            torDirURL: ZcashFileStore.torDirURL(uniqueId: uniqueId, network: network),
            endpoint: endpoint,
            network: network,
            spendParamsURL: ZcashFileStore.spendParamsURL(),
            outputParamsURL: ZcashFileStore.outputParamsURL(),
            saplingParamsSourceURL: SaplingParamsSourceURL.default,
            alias: .custom(uniqueId),
            loggingPolicy: .noLogging,
//          loggingPolicy: .default(.debug),
            isTorEnabled: false,
            isExchangeRateEnabled: false
        )
    }

    public static func clear(except excludedWalletIds: [String]) throws {
        try ZcashFileStore.clear(except: excludedWalletIds)
    }
}

extension ZcashAdapter: IAdapter {
    var isMainNet: Bool {
        network.networkType == .mainnet
    }

    func start() {
        syncService.start()
    }

    func stop() {
        syncService.stop()
    }

    func refresh() {
        syncService.refresh()
    }

    var statusInfo: [(String, Any)] {
        [
            ("Last Block Info", syncService.lastBlockHeight),
            ("Sync State", syncService.state.description),
            ("Birthday Height", birthday.description),
            ("Init Mode", initMode.description),
        ]
    }

    var debugInfo: String {
        let zAddress = uAddress?.stringEncoded ?? "No Info"
        var balanceState = "No Balance Information yet"

        if let status = syncService.synchronizerState, let accountId = syncService.accountId {
            balanceState = """
            shielded balance (BalanceData)
                accountId: \(accountId)
                total:  \(balanceData.total.description)
                verified:  \(balanceData.available)
            unshielded balance: \(String(describing: status.accountsBalances[accountId]?.unshielded ?? Zatoshi(0)))
            """
        }
        return """
        ZcashAdapter
        z-address: \(String(describing: zAddress))
        spendingKeys: \(syncService.spendingKey?.description ?? "N/A")
        balanceState: \(balanceState)
        """
    }
}

extension ZcashAdapter: ITransactionsAdapter {
    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: syncService.lastBlockHeight, timestamp: nil)
    }

    var syncingObservable: Observable<Void> {
        syncService.balanceStateUpdatedObservable.map { _ in () }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        syncService.lastBlockUpdatedObservable
    }

    var explorerTitle: String {
        "blockchair.com"
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func explorerUrl(transactionHash: String) -> String? {
        network.networkType == .mainnet ? "https://blockchair.com/zcash/transaction/" + transactionHash : nil
    }

    func transactionsObservable(token _: Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        historyService.transactionsObservable
            .map { [weak self] transactions in
                transactions.compactMap { transaction -> TransactionRecord? in
                    if let address, let recipient = transaction.recipientAddress, address.lowercased() != recipient.lowercased() {
                        return nil
                    }

                    guard let record = self?.transactionRecord(fromTransaction: transaction) else {
                        return nil
                    }

                    switch (record, filter) {
                    case (_, .all): return record
                    case (is BitcoinIncomingTransactionRecord, .incoming): return record
                    case (is BitcoinOutgoingTransactionRecord, .outgoing): return record
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(paginationData: String?, token _: Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        historyService.transactionsSingle(paginationData: paginationData, filter: filter, descending: true, address: address, limit: limit).map { [weak self] txs in
            txs.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        historyService.transactionsSingle(paginationData: paginationData, filter: .all, descending: false, address: nil, limit: nil).map { [weak self] txs in
            txs.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func rawTransaction(hash: String) -> String? {
        historyService.rawTransaction(hash: hash)
    }
}

extension ZcashAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        syncService.balanceStateUpdatedObservable
    }

    var balanceData: BalanceData {
        balanceService.balanceData
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceService.balanceDataUpdatedObservable
    }
}

extension ZcashAdapter: IDepositAdapter {
    public var receiveAddress: DepositAddress {
        .init(uAddress?.stringEncoded ?? "n/a".localized)
    }

    public var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        syncService.receiveAddressPublisher
    }
}

extension ZcashAdapter {
    public enum AddressType {
        case shielded
        case transparent
    }

    struct TransferOutput {
        let amount: Decimal
        let address: Recipient
        let memo: Memo?
    }

    var availableBalance: Decimal {
        max(0, balanceData.available)
    }

    func sendProposal(
        amount: Decimal,
        address: Recipient,
        memo: Memo?,
        zip317MarginalFee: Zatoshi = ZcashAdapter.defaultZip317MarginalFee
    ) async throws -> Proposal {
        try await sendService.sendProposal(amount: amount, address: address, memo: memo, zip317MarginalFee: zip317MarginalFee)
    }

    func sendProposal(
        outputs: [TransferOutput],
        zip317MarginalFee: Zatoshi = ZcashAdapter.defaultZip317MarginalFee
    ) async throws -> Proposal {
        try await sendService.sendProposal(outputs: outputs, zip317MarginalFee: zip317MarginalFee)
    }

    func shieldProposal(
        threshold: Decimal,
        address: Recipient?,
        memo: Memo?,
        zip317MarginalFee: Zatoshi = ZcashAdapter.defaultZip317MarginalFee
    ) async throws -> Proposal? {
        try await sendService.shieldProposal(threshold: threshold, address: address, memo: memo, zip317MarginalFee: zip317MarginalFee)
    }

    func validate(address: String, checkSendToSelf: Bool = true) throws -> AddressType {
        if checkSendToSelf, uAddress?.stringEncoded.lowercased() == address.lowercased() || tAddress?.stringEncoded == address.lowercased() {
            throw AppError.zcash(reason: .sendToSelf)
        }

        do {
            switch try Recipient(address, network: network.networkType) {
            case .transparent:
                return .transparent
            case .sapling, .unified, .tex: // I'm keeping changes to the minimum. Unified Address should be treated as a different address type which will include some shielded pool and possibly others as well.
                return .shielded
            }
        } catch {
            // FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }

    func sendSingle(
        amount: Decimal,
        address: Recipient,
        memo: Memo?,
        zip317MarginalFee: Zatoshi = ZcashAdapter.defaultZip317MarginalFee
    ) -> Single<Void> {
        sendService.sendSingle(amount: amount, address: address, memo: memo, zip317MarginalFee: zip317MarginalFee)
    }

    func send(
        amount: Decimal,
        address: Recipient,
        memo: Memo?,
        zip317MarginalFee: Zatoshi = ZcashAdapter.defaultZip317MarginalFee
    ) async throws {
        try await sendService.send(amount: amount, address: address, memo: memo, zip317MarginalFee: zip317MarginalFee)
    }

    @discardableResult func send(
        proposal: Proposal,
        zip317MarginalFee: Zatoshi = ZcashAdapter.defaultZip317MarginalFee
    ) async throws -> String? {
        try await sendService.send(proposal: proposal, zip317MarginalFee: zip317MarginalFee)
    }

    func migrationProposal() async throws -> (amount: Decimal, fee: Decimal) {
        try await sendService.migrationProposal(orchardBalance: zCashBalanceData.orchard)
    }

    func clearMigrationHistory() {
        migrator.clearOnWipe()
    }

    func performMigration() async throws -> String? {
        try await sendService.performMigration()
    }

    func recipient(from stringEncodedAddress: String) -> ZcashLightClientKit.Recipient? {
        try? Recipient(stringEncodedAddress, network: network.networkType)
    }

    func resubmitPendingTransactions() async {
        await sendService.resubmitPendingTransactions()
    }

    static func isResubmissionCandidate(isSentTransaction: Bool, minedHeight: BlockHeight?, hasRaw: Bool, expiryHeight: BlockHeight?, latestHeight: BlockHeight) -> Bool {
        ZcashSendService.isResubmissionCandidate(isSentTransaction: isSentTransaction, minedHeight: minedHeight, hasRaw: hasRaw, expiryHeight: expiryHeight, latestHeight: latestHeight)
    }
}

class ZcashAddressValidator {
    private let network: ZcashNetwork

    init(network: ZcashNetwork) {
        self.network = network
    }

    public func validate(address: String) throws -> Recipient {
        do {
            return try Recipient(address, network: network.networkType)
        } catch {
            // FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }
}

extension Recipient {
    var isTransparent: Bool {
        switch self {
        case .tex, .transparent: return true
        case .sapling, .unified: return false
        }
    }
}

enum ZCashAdapterState: Equatable {
    case idle
    case preparing
    case synced
    case syncing(progress: Int?, remaining: Int?, lastBlockDate: Date?)
    case notSynced(error: Error)

    public static func == (lhs: ZCashAdapterState, rhs: ZCashAdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.preparing, .preparing): return true
        case (.synced, .synced): return true
        case let (.syncing(lProgress, lRemaining, lLastBlockDate), .syncing(rProgress, rRemaining, rLastBlockDate)): return lProgress == rProgress && lRemaining == rRemaining && lLastBlockDate == rLastBlockDate
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }

    var adapterState: AdapterState {
        switch self {
        case .idle: return .customSyncing(main: "Starting...", secondary: nil, progress: nil)
        case .preparing: return .customSyncing(main: "Preparing...", secondary: nil, progress: nil)
        case .synced: return .synced
        case let .syncing(progress, remaining, lastDate): return .syncing(progress: progress, remaining: remaining, lastBlockDate: lastDate)
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }

    var description: String {
        switch self {
        case .idle: return "Idle"
        case .preparing: return "Preparing..."
        case .synced: return "Synced"
        case let .syncing(progress, _, lastDate): return "Syncing: progress = \(progress?.description ?? "N/A"), lastBlockDate: \(lastDate?.description ?? "N/A")"
        case let .notSynced(error): return "Not synced \(error.localizedDescription)"
        }
    }

    var isPrepairing: Bool {
        switch self {
        case .preparing: return true
        default: return false
        }
    }
}

extension WalletInitMode {
    var description: String {
        switch self {
        case .newWallet: return "New Wallet"
        case .existingWallet: return "Existing Wallet"
        case .restoreWallet: return "Restored Wallet"
        }
    }
}

extension Zip32AccountIndex {
    static let zero: Self = .init(0)
}
