import Combine
import Foundation
import HdWalletKit
import HsExtensions
import HsToolKit
import MarketKit
import RxRelay
import RxSwift
import UIKit
import ZcashLightClientKit

class ZcashAdapter {
    private static let endPoint = "mainnet.lightwalletd.com" // "lightwalletd.electriccoin.co"
    private let queue = DispatchQueue(label: "\(AppConfig.label).zcash-adapter", qos: .userInitiated)

    private var cancellables: [AnyCancellable] = []

    private let token: Token
    private let transactionSource: TransactionSource

    private let saplingDownloader = DownloadService(queueLabel: "io.SaplingDownloader")

    private let synchronizer: Synchronizer

    private var zAddress: String?
    private var transactionPool: ZcashTransactionPool?

    private let uniqueId: String
    private let seedData: [UInt8]
    private let birthday: BlockHeight
    private let initMode: WalletInitMode
    private var viewingKey: UnifiedFullViewingKey? // this being a single account does not need to be an array
    private var spendingKey: UnifiedSpendingKey?
    private var logger: HsToolKit.Logger?

    private(set) var network: ZcashNetwork
    private(set) var fee: Decimal

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()
    private let depositAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    private var started = false
    private var lastBlockHeight: Int = 0

    private var synchronizerState: SynchronizerState? {
        didSet {
            lastBlockUpdatedSubject.onNext(())
            balanceSubject.onNext(_balanceData)
        }
    }

    private var state: ZCashAdapterState = .idle {
        didSet {
            balanceStateSubject.onNext(balanceState)
            syncing = balanceState.syncing
        }
    }

    var balanceState: AdapterState {
        state.adapterState
    }

    private(set) var syncing: Bool = true

    init(wallet: Wallet, restoreSettings: RestoreSettings) throws {
        logger = App.shared.logger.scoped(with: "ZCashKit") // HsToolKit.Logger(minLogLevel: .debug) //

        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        network = ZcashNetworkBuilder.network(for: .mainnet)

        // todo: update fee settings
        fee = network.constants.defaultFee().decimalValue.decimalValue

        token = wallet.token
        transactionSource = wallet.transactionSource
        uniqueId = wallet.account.id

        var existingMode: WalletInitMode?
        if let dbUrl = try? Self.spendParamsURL(uniqueId: uniqueId),
           Self.exist(url: dbUrl) {
            existingMode = .existingWallet
        }
        switch wallet.account.origin {
        case .created:
            birthday = Self.newBirthdayHeight(network: network)
            initMode = existingMode ?? .newWallet
        case .restored:
            if let height = restoreSettings.birthdayHeight {
                birthday = max(height, network.constants.saplingActivationHeight)
            } else {
                birthday = network.constants.saplingActivationHeight
            }
            initMode = existingMode ?? .restoreWallet
        }

        let seedData = [UInt8](seed)
        self.seedData = seedData

        let initializer = try ZcashAdapter.initializer(network: network, uniqueId: uniqueId)
        synchronizer = SDKSynchronizer(initializer: initializer)
        // subscribe on sync states
        synchronizer
            .stateStream
            .throttle(for: .seconds(0.3), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] state in self?.sync(state: state) })
            .store(in: &cancellables)

        // subscribe on new transactions
        synchronizer
            .eventStream
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in self?.sync(event: event) })
            .store(in: &cancellables)

        saplingDownloader
            .$state
            .sink(receiveValue: { [weak self] in self?.downloaderStatusUpdated(state: $0) })
            .store(in: &cancellables)

        // subscribe on background and events from sapling downloader
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func prepare(seedData: [UInt8], walletBirthday: BlockHeight, for initMode: WalletInitMode) {
        guard !state.isPrepairing else {
            return
        }
        state = .preparing

        depositAddressSubject.send(.loading)
        Task { [weak self, synchronizer] in
            do {
                let tool = DerivationTool(networkType: .mainnet)
                guard let unifiedSpendingKey = try? tool.deriveUnifiedSpendingKey(seed: seedData, accountIndex: 0),
                      let unifiedViewingKey = try? tool.deriveUnifiedFullViewingKey(from: unifiedSpendingKey)
                else {
                    throw AppError.ZcashError.cantCreateKeys
                }

                self?.spendingKey = unifiedSpendingKey
                self?.viewingKey = unifiedViewingKey

                let result = try await synchronizer.prepare(with: seedData, walletBirthday: walletBirthday, for: initMode)
                if case .seedRequired = result {
                    throw AppError.ZcashError.seedRequired
                }
                self?.logger?.log(level: .debug, message: "Successful prepared!")
                guard let address = try? await synchronizer.getUnifiedAddress(accountIndex: 0),
                      let saplingAddress = try? address.saplingReceiver()
                else {
                    throw AppError.ZcashError.noReceiveAddress
                }
                self?.zAddress = saplingAddress.stringEncoded
                self?.depositAddressSubject.send(.completed(DepositAddress(saplingAddress.stringEncoded)))

                self?.logger?.log(level: .debug, message: "Successful get address for 0 account! \(saplingAddress.stringEncoded)")

                let transactionPool = ZcashTransactionPool(receiveAddress: saplingAddress, synchronizer: synchronizer)
                self?.transactionPool = transactionPool

                self?.logger?.log(level: .debug, message: "Starting fetch transactions.")
                await transactionPool.initTransactions()
                let wrapped = transactionPool.all

                if !wrapped.isEmpty {
                    self?.logger?.log(level: .debug, message: "Send to pool all transactions \(wrapped.count)")
                    self?.transactionRecordsSubject.onNext(wrapped.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    })
                }

                let shielded = await (try? synchronizer.getShieldedBalance(accountIndex: 0).decimalValue.decimalValue) ?? 0
                let shieldedVerified = await (try? synchronizer.getShieldedVerifiedBalance(accountIndex: 0).decimalValue.decimalValue) ?? 0
                self?.balanceSubject.onNext(
                    VerifiedBalanceData(
                            fullBalance: shielded,
                            available: shieldedVerified
                    )
                )
                let height = try await synchronizer.latestHeight()
                self?.lastBlockHeight = height

                self?.lastBlockUpdatedSubject.onNext(())

                self?.finishPrepare()
            } catch {
                self?.setPreparing(error: error)
            }
        }
    }

    private func setPreparing(error: Error) {
        state = .notSynced(error: error)
        logger?.log(level: .error, message: "Has preparing error! \(error)")
    }

    private func finishPrepare() {
        state = .idle

        logger?.log(level: .debug, message: "Start kit after finish preparing!")
        startSynchronizer()
    }

    private func startSynchronizer() {
        guard !state.isPrepairing else { // postpone start library until preparing will finish
            logger?.log(level: .debug, message: "Can't start because preparing!")
            return
        }

        if zAddress == nil { // else we need to try prepare library again
            logger?.log(level: .debug, message: "No address, try to prepare kit again!")
            prepare(seedData: seedData, walletBirthday: birthday, for: initMode)

            return
        }

        if saplingDataExist() {
            logger?.log(level: .debug, message: "Start syncing kit!")
            syncMain()
        }
    }

    @objc private func didEnterBackground(_: Notification) {
        stop()
    }

    private func downloaderStatusUpdated(state: DownloadService.State) {
        switch state {
        case .idle:
            ()
        case .success:
            syncMain()
        case let .inProgress(progress):
            self.state = .downloadingSapling(progress: Int(progress * 100))
        }
    }

    private func sync(state: SynchronizerState) {
        synchronizerState = state

        var syncStatus = self.state

        switch state.syncStatus {
        case .unprepared:
            if started {
                logger?.log(level: .debug, message: "State: Disconnected")
                syncStatus = .syncing(progress: nil, lastBlockDate: nil)
            } else {
                syncStatus = .idle
            }
        case .stopped:
            logger?.log(level: .debug, message: "State: Disconnected")
            syncStatus = .syncing(progress: nil, lastBlockDate: nil)
        case .upToDate:
            if !started {
                started = true
            }
            logger?.log(level: .debug, message: "State: Synced")
            syncStatus = .synced
            lastBlockHeight = max(state.latestBlockHeight, lastBlockHeight)
            logger?.log(level: .debug, message: "Update BlockHeight = \(lastBlockHeight)")
            checkFailingTransactions()
        case let .syncing(progress):
            if !started {
                started = true
            }
            logger?.log(level: .debug, message: "State: Syncing")
            logger?.log(level: .debug, message: "State progress: \(progress)")
            lastBlockHeight = max(state.latestBlockHeight, lastBlockHeight)
            logger?.log(level: .debug, message: "Update BlockHeight = \(lastBlockHeight)")

            lastBlockUpdatedSubject.onNext(())

            syncStatus = .downloadingBlocks(progress: progress, lastBlock: state.latestBlockHeight)
        case let .error(error):
            if !started, case .synchronizerDisconnected = error as? ZcashError {
                syncStatus = .idle
            } else {
                started = true
                logger?.log(level: .error, message: "State: Error: \(error)")
                syncStatus = .notSynced(error: AppError.unknownError)
            }
        }

        if syncStatus != self.state {
            self.state = syncStatus
        }
    }

    private func sync(event: SynchronizerEvent) {
        switch event {
        case let .foundTransactions(transactions, inRange):
            logger?.log(level: .debug, message: "found \(transactions.count) mined txs in range: \(inRange)")
            transactions.forEach { overview in
                logger?.log(level: .debug, message: "tx: v =\(overview.value.decimalValue.decimalString) : fee = \(overview.fee?.decimalString() ?? "N/A") : height = \(overview.minedHeight?.description ?? "N/A")")
            }
            let lastBlockHeight = max(inRange.upperBound, lastBlockHeight)
            Task {
                let newTxs = await transactionPool?.sync(transactions: transactions, lastBlockHeight: lastBlockHeight) ?? []
                transactionRecordsSubject.onNext(newTxs.map {
                    transactionRecord(fromTransaction: $0)
                })
            }
        case let .minedTransaction(pendingEntity):
            logger?.log(level: .debug, message: "found pending tx: v =\(pendingEntity.value.decimalValue.decimalString) : fee = \(pendingEntity.fee?.decimalString() ?? "N/A")")
            Task {
                try await update(transactions: [pendingEntity])
            }
        default:
            logger?.log(level: .debug, message: "Event: \(event)")
        }
    }

    private func checkFailingTransactions() {
        reSyncPending()
    }

    private func reSyncPending() {
        Task {
            let pending = await synchronizer.transactions.filter { overview in overview.minedHeight == nil }
            logger?.log(level: .debug, message: "Resync pending txs: \(pending.count)")
            pending.forEach { entity in
                logger?.log(level: .debug, message: "TX : \(entity.value.decimalValue.description)")
            }
            if !pending.isEmpty {
                try await update(transactions: pending)
            }
        }
    }

    private func update(transactions: [ZcashTransaction.Overview]) async throws {
        let newTxs = await transactionPool?.sync(transactions: transactions, lastBlockHeight: lastBlockHeight) ?? []
        logger?.log(level: .debug, message: "pool will update txs: \(newTxs.count)")
        transactionRecordsSubject.onNext(newTxs.map {
            transactionRecord(fromTransaction: $0)
        })
    }

    func transactionRecord(fromTransaction transaction: ZcashTransactionWrapper) -> TransactionRecord {
        let showRawTransaction = transaction.minedHeight == nil || transaction.failed

        // TODO: Should have it's own transactions with memo
        if !transaction.isSentTransaction {
            return BitcoinIncomingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.defaultRewindDistance,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: transaction.fee?.decimalValue.decimalValue,
                failed: transaction.failed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction,
                amount: abs(transaction.value.decimalValue.decimalValue),
                from: transaction.recipientAddress,
                memo: transaction.memo
            )
        } else {
            return BitcoinOutgoingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.defaultRewindDistance,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: transaction.fee?.decimalValue.decimalValue,
                failed: transaction.failed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction,
                amount: abs(transaction.value.decimalValue.decimalValue),
                to: transaction.recipientAddress,
                sentToSelf: false,
                memo: transaction.memo
            )
        }
    }

    private static var cloudSpendParamsURL: URL? {
        URL(string: ZcashSDK.cloudParameterURL + ZcashSDK.spendParamFilename)
    }

    private static var cloudOutputParamsURL: URL? {
        URL(string: ZcashSDK.cloudParameterURL + ZcashSDK.outputParamFilename)
    }

    private func saplingDataExist() -> Bool {
        var isExist = true

        if let cloudSpendParamsURL = Self.cloudOutputParamsURL,
           let destinationURL = try? Self.outputParamsURL(uniqueId: uniqueId),
           !DownloadService.existing(url: destinationURL)
        {
            isExist = false
            saplingDownloader.download(source: cloudSpendParamsURL, destination: destinationURL)
        }

        if let cloudSpendParamsURL = Self.cloudSpendParamsURL,
           let destinationURL = try? Self.spendParamsURL(uniqueId: uniqueId),
           !DownloadService.existing(url: destinationURL)
        {
            isExist = false
            saplingDownloader.download(source: cloudSpendParamsURL, destination: destinationURL)
        }

        return isExist
    }

    func fixPendingTransactionsIfNeeded(completion: (() -> Void)? = nil) {
        // check if we need to perform the fix or leave
        // get all the pending transactions
        guard !App.shared.localStorage.zcashAlwaysPendingRewind else {
            completion?()
            return
        }

        Task {
            let txs = await synchronizer.transactions.filter { overview in overview.minedHeight == nil }
            // fetch the first one that's reported to be unmined
            guard let firstUnmined = txs.filter({ $0.minedHeight == nil }).first else {
                App.shared.localStorage.zcashAlwaysPendingRewind = true
                completion?()
                return
            }

            rewind(unmined: firstUnmined, completion: completion)
        }
    }

    private func rewind(unmined: ZcashTransaction.Overview, completion: (() -> Void)? = nil) {
        synchronizer
            .rewind(.transaction(unmined))
            .sink(receiveCompletion: { result in
                      switch result {
                      case .finished:
                          App.shared.localStorage.zcashAlwaysPendingRewind = true
                          completion?()
                      case .failure:
                          self.rewindQuick()
                      }
                  },
                  receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func rewindQuick(completion: (() -> Void)? = nil) {
        synchronizer
            .rewind(.quick)
            .sink(receiveCompletion: { [weak self] result in
                      switch result {
                      case .finished:
                          App.shared.localStorage.zcashAlwaysPendingRewind = true
                          self?.logger?.log(level: .debug, message: "rewind Successful")
                          completion?()
                      case let .failure(error):
                          self?.state = .notSynced(error: error)
                          completion?()
                          self?.logger?.log(level: .error, message: "attempt to fix pending transactions failed with error: \(error)")
                      }
                  },
                  receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private var _balanceData: BalanceData {
        guard let synchronizerState = synchronizerState else {
            return BalanceData(available: 0)
        }

        return VerifiedBalanceData(
            fullBalance: synchronizerState.shieldedBalance.total.decimalValue.decimalValue,
            available: synchronizerState.shieldedBalance.verified.decimalValue.decimalValue
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Task { [weak self] in
            self?.synchronizer.stop()
            self?.logger?.log(level: .debug, message: "Synchronizer Was Stopped")
        }
    }
}

extension ZcashAdapter {
    public static func newBirthdayHeight(network: ZcashNetwork) -> Int {
        BlockHeight.ofLatestCheckpoint(network: network)
    }

    static func initializer(network: ZcashNetwork, uniqueId: String) throws -> Initializer {
        try Initializer(
            cacheDbURL: nil,
            fsBlockDbRoot: fsBlockDbRootURL(uniqueId: uniqueId, network: network),
            generalStorageURL: generalStorageURL(uniqueId: uniqueId, network: network),
            dataDbURL: dataDbURL(uniqueId: uniqueId, network: network),
            endpoint: LightWalletEndpoint(address: endPoint, port: 9067, secure: true, streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000),
            network: network,
            spendParamsURL: spendParamsURL(uniqueId: uniqueId),
            outputParamsURL: outputParamsURL(uniqueId: uniqueId),
            saplingParamsSourceURL: SaplingParamsSourceURL.default,
            alias: .custom(uniqueId),
            loggingPolicy: .default(.error)
        )
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("z-cash-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    private static func exist(url: URL) -> Bool {
        let fileManager = FileManager.default

        do {
            return try fileManager.fileExists(coordinatingAccessAt: url).exists
        } catch {
            return false
        }
    }

    private static func fsBlockDbRootURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.networkType.chainName + uniqueId + ZcashSDK.defaultFsCacheName, isDirectory: true)
    }

    private static func generalStorageURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.networkType.chainName + uniqueId + "general_storage", isDirectory: true)
    }

    private static func cacheDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultCacheDbName, isDirectory: false)
    }

    private static func dataDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultDataDbName, isDirectory: false)
    }

    private static func spendParamsURL(uniqueId: String) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent("sapling-spend_\(uniqueId).params")
    }

    private static func outputParamsURL(uniqueId: String) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent("sapling-output_\(uniqueId).params")
    }

    public static func clear(except excludedWalletIds: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedWalletIds.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }
}

extension ZcashAdapter: IAdapter {
    var isMainNet: Bool {
        network.networkType == .mainnet
    }

    func start() {
        prepare(seedData: seedData, walletBirthday: birthday, for: initMode)
    }

    func stop() {
        synchronizer.stop()
        logger?.log(level: .debug, message: "Synchronizer will stop")
    }

    func refresh() {
        startSynchronizer()
    }

    private func syncMain() {
        DispatchQueue.main.async { [weak self] in
            self?.sync()
        }
    }

    private func sync() {
        balanceSubject.onNext(_balanceData)
        fixPendingTransactionsIfNeeded { [weak self] in
            self?.logger?.log(level: .debug, message: "\(Date()) Try to start synchronizer :by Thread:\(Thread.current)")
            Task { [weak self] in
                do {
                    try await self?.synchronizer.start(retry: true)
                } catch {
                    self?.state = .notSynced(error: error)
                }
            }
        }
    }

    var statusInfo: [(String, Any)] {
        [
            ("Last Block Info", lastBlockHeight),
            ("Sync State", state.description),
            ("Birthday Height", birthday.description),
            ("Init Mode", initMode.description),
        ]
    }

    var debugInfo: String {
        let zAddress = zAddress ?? "No Info"
        var balanceState = "No Balance Information yet"

        if let status = synchronizerState {
            balanceState = """
            shielded balance
              total:  \(balanceData.balanceTotal.description)
            verified:  \(balanceData.available)
            transparent balance
                 total: \(String(describing: status.transparentBalance.total))
              verified: \(String(describing: status.transparentBalance.verified))
            """
        }
        return """
        ZcashAdapter
        z-address: \(String(describing: zAddress))
        spendingKeys: \(spendingKey?.description ?? "N/A")
        balanceState: \(balanceState)
        """
    }
}

extension ZcashAdapter: ITransactionsAdapter {
    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: lastBlockHeight, timestamp: nil)
    }

    var syncingObservable: Observable<Void> {
        balanceStateSubject.map { _ in () }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        lastBlockUpdatedSubject.asObservable()
    }

    var explorerTitle: String {
        "blockchair.com"
    }

    func explorerUrl(transactionHash: String) -> String? {
        network.networkType == .mainnet ? "https://blockchair.com/zcash/transaction/" + transactionHash : nil
    }

    func transactionsObservable(token _: Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
            .map { transactions in
                transactions.compactMap { transaction -> TransactionRecord? in
                    switch (transaction, filter) {
                    case (_, .all): return transaction
                    case (is BitcoinIncomingTransactionRecord, .incoming): return transaction
                    case (is BitcoinOutgoingTransactionRecord, .outgoing): return transaction
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(from: TransactionRecord?, token _: Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        transactionPool?.transactionsSingle(from: from, filter: filter, limit: limit).map { [weak self] txs in
            txs.compactMap { self?.transactionRecord(fromTransaction: $0) }
        } ?? .just([])
    }

    func rawTransaction(hash: String) -> String? {
        transactionPool?.transaction(by: hash)?.raw?.hs.hex
    }
}

extension ZcashAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceData: BalanceData {
        _balanceData
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceSubject.asObservable()
    }
}

extension ZcashAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        // only first account
        DepositAddress(zAddress ?? "n/a".localized)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        depositAddressSubject.eraseToAnyPublisher()
    }
}

extension ZcashAdapter: ISendZcashAdapter {
    enum AddressType {
        case shielded
        case transparent
    }

    var availableBalance: Decimal {
        max(0, balanceData.available - fee)
    }

    func validate(address: String, checkSendToSelf: Bool = true) throws -> AddressType {
        if checkSendToSelf, address == receiveAddress.address {
            throw AppError.zcash(reason: .sendToSelf)
        }

        do {
            switch try Recipient(address, network: network.networkType) {
            case .transparent:
                return .transparent
            case .sapling, .unified: // I'm keeping changes to the minimum. Unified Address should be treated as a different address type which will include some shielded pool and possibly others as well.
                return .shielded
            }
        } catch {
            // FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }

    func sendSingle(amount: Decimal, address: Recipient, memo: Memo?) -> Single<Void> {
        guard let spendingKey else {
            return .error(AppError.ZcashError.noReceiveAddress)
        }

        return Single.create { [weak self] observer in
            guard let self else {
                observer(.error(AppError.unknownError))
                return Disposables.create()
            }
            Task {
                do {
                    let pendingEntity = try await self.synchronizer.sendToAddress(
                        spendingKey: spendingKey,
                        zatoshi: Zatoshi.from(decimal: amount),
                        toAddress: address,
                        memo: memo
                    )
                    self.logger?.log(level: .debug, message: "Successful send TX: : \(pendingEntity.value.decimalValue.description):")
                    self.reSyncPending()
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func recipient(from stringEncodedAddress: String) -> ZcashLightClientKit.Recipient? {
        try? Recipient(stringEncodedAddress, network: network.networkType)
    }
}

class ZcashAddressValidator {
    private let network: ZcashNetwork

    init(network: ZcashNetwork) {
        self.network = network
    }

    public func validate(address: String) throws {
        do {
            _ = try Recipient(address, network: network.networkType)
        } catch {
            // FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }
}

extension EnhancementProgress {
    var progress: Int {
        guard totalTransactions <= 0 else {
            return 0
        }
        return Int(Double(enhancedTransactions) / Double(totalTransactions)) * 100
    }
}

enum ZCashAdapterState: Equatable {
    case idle
    case preparing
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case downloadingSapling(progress: Int)
    case downloadingBlocks(progress: Float, lastBlock: Int)
    case notSynced(error: Error)

    public static func == (lhs: ZCashAdapterState, rhs: ZCashAdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.preparing, .preparing): return true
        case (.synced, .synced): return true
        case let (.syncing(lProgress, lLastBlockDate), .syncing(rProgress, rLastBlockDate)): return lProgress == rProgress && lLastBlockDate == rLastBlockDate
        case let (.downloadingSapling(lProgress), .downloadingSapling(rProgress)): return lProgress == rProgress
        case let (.downloadingBlocks(lNumber, lLast), .downloadingBlocks(rNumber, rLast)): return lNumber == rNumber && lLast == rLast
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }

    var adapterState: AdapterState {
        switch self {
        case .idle: return .customSyncing(main: "Starting...", secondary: nil, progress: nil)
        case .preparing: return .customSyncing(main: "Preparing...", secondary: nil, progress: nil)
        case .synced: return .synced
        case let .syncing(progress, lastDate): return .syncing(progress: progress, lastBlockDate: lastDate)
        case let .downloadingSapling(progress):
            return .customSyncing(main: "balance.downloading_sapling".localized(progress), secondary: nil, progress: progress)
        case let .downloadingBlocks(progress, _):
            let percentValue = ValueFormatter.instance.format(percentValue: Decimal(Double(progress * 100)), showSign: false)
            return .customSyncing(main: "balance.downloading_blocks".localized, secondary: percentValue, progress: Int(progress * 100))
        case let .notSynced(error): return .notSynced(error: error)
        }
    }

    var description: String {
        switch self {
        case .idle: return "Idle"
        case .preparing: return "Preparing..."
        case .synced: return "Synced"
        case let .syncing(progress, lastDate): return "Syncing: progress = \(progress?.description ?? "N/A"), lastBlockDate: \(lastDate?.description ?? "N/A")"
        case let .downloadingSapling(progress): return "downloadingSapling: progress = \(progress)"
        case let .downloadingBlocks(progress, _):
            let percentValue = ValueFormatter.instance.format(percentValue: Decimal(Double(progress * 100)), showSign: false)
            return "Downloading Blocks: \(percentValue?.description ?? "N/A") : \(Int(progress * 100))"
        case let .notSynced(error): return "Not synced \(error.localizedDescription)"
        }
    }

    var isDownloading: Bool {
        switch self {
        case .downloadingBlocks: return true
        default: return false
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
