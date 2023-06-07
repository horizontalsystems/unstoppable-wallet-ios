import Foundation
import UIKit
import ZcashLightClientKit
import RxSwift
import RxRelay
import HdWalletKit
import HsToolKit
import MarketKit
import HsExtensions
import Combine

class ZcashAdapter {
    private static let endPoint = "lightwalletd.electriccoin.co" //"mainnet.lightwalletd.com"
    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.zcash-adapter", qos: .userInitiated)

    private let disposeBag = DisposeBag()
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
    private var viewingKey: UnifiedFullViewingKey? // this being a single account does not need to be an array
    private var spendingKey: UnifiedSpendingKey?
    private var logger: HsToolKit.Logger?

    private(set) var network: ZcashNetwork
    private(set) var fee: Decimal

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private var preparing: Bool = false
    private var lastBlockHeight: Int = 0

    private var waitForStart: Bool = false {
        didSet {
            if waitForStart && zAddress != nil {     // already prepared and has address
                syncMain()
            }
        }
    }

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

    private func defaultFee(network: ZcashNetwork, height: Int? = nil) -> Zatoshi {
        let fee: Zatoshi
        if let lastBlockHeight = height {
            fee = network.constants.defaultFee(for: lastBlockHeight)
        } else {
            fee = network.constants.defaultFee()
        }
        return fee
    }

    private func defaultFeeDecimal(network: ZcashNetwork, height: Int? = nil) -> Decimal {
        defaultFee(network: network, height: height).decimalValue.decimalValue
    }

    init(wallet: Wallet, restoreSettings: RestoreSettings) throws {
        logger = App.shared.logger.scoped(with: "ZCashKit") //HsToolKit.Logger(minLogLevel: .debug)

        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        network = ZcashNetworkBuilder.network(for: .mainnet)
        fee = network.constants.defaultFee().decimalValue.decimalValue

        token = wallet.token
        transactionSource = wallet.transactionSource
        uniqueId = wallet.account.id

        let birthday: BlockHeight
        switch wallet.account.origin {
        case .created: birthday = Self.newBirthdayHeight(network: network)
        case .restored:
            if let height = restoreSettings.birthdayHeight {
                birthday = max(height, network.constants.saplingActivationHeight)
            } else {
                birthday = network.constants.saplingActivationHeight
            }
        }
        self.birthday = birthday

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

        // subscribe on background and events from sapling downloader
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        subscribe(disposeBag, saplingDownloader.stateObservable) { [weak self] in self?.downloaderStatusUpdated(state: $0) }

        prepare(initializer: initializer, seedData: seedData, walletBirthday: birthday)
    }

    private func prepare(initializer: Initializer, seedData: [UInt8], walletBirthday: BlockHeight) {
        preparing = true
        state = .preparing

        Task {
            do {
                let tool = initializer.makeDerivationTool()
                guard let unifiedSpendingKey = try? await tool.deriveUnifiedSpendingKey(seed: seedData, accountIndex: 0),
                      let unifiedViewingKey = try? await tool.deriveUnifiedFullViewingKey(from: unifiedSpendingKey) else {

                    throw AppError.ZcashError.cantCreateKeys
                }

                spendingKey = unifiedSpendingKey
                viewingKey = unifiedViewingKey


                let result = try await synchronizer.prepare(with: seedData, viewingKeys: [unifiedViewingKey], walletBirthday: walletBirthday)
                if case .seedRequired = result {
                    throw AppError.ZcashError.seedRequired
                }
                logger?.log(level: .debug, message: "Successful prepared!")
                guard let address = try? await synchronizer.getUnifiedAddress(accountIndex: 0),
                        let saplingAddress = try? address.saplingReceiver() else {
                    throw AppError.ZcashError.noReceiveAddress
                }
                zAddress = saplingAddress.stringEncoded
                logger?.log(level: .debug, message: "Successful get address for 0 account! \(saplingAddress.stringEncoded)")

                let transactionPool = ZcashTransactionPool(receiveAddress: saplingAddress, synchronizer: synchronizer)
                self.transactionPool = transactionPool

                logger?.log(level: .debug, message: "Starting fetch transactions.")
                await transactionPool.initTransactions()
                let wrapped = transactionPool.all

                if !wrapped.isEmpty {
                    logger?.log(level: .debug, message: "Send to pool all transactions \(wrapped.count)")
                    transactionRecordsSubject.onNext(wrapped.map {
                        transactionRecord(fromTransaction: $0)
                    })
                }

                let shielded = await (try? synchronizer.getShieldedBalance(accountIndex: 0).decimalValue.decimalValue) ?? 0
                let shieldedVerified = await (try? synchronizer.getShieldedVerifiedBalance(accountIndex: 0).decimalValue.decimalValue) ?? 0
                balanceSubject.onNext(BalanceData(
                        balance: shieldedVerified,
                        balanceLocked: shielded - shieldedVerified
                ))

                finishPrepare()
            } catch {
                setPreparing(error: error)
            }
        }
    }

    private func setPreparing(error: Error) {
        preparing = false
        state = .notSynced(error: error)
        logger?.log(level: .error, message: "Has preparing error! \(error)")
    }

    private func finishPrepare() {
        preparing = false
        state = .idle

        if waitForStart {
            logger?.log(level: .debug, message: "Start kit after finish preparing!")
            start()
        }
    }

    @objc private func didEnterBackground(_ notification: Notification) {
        stop()
    }

    private func downloaderStatusUpdated(state: DownloadService.State) {
        switch state {
        case .idle:
            syncMain()
        case .inProgress(let progress):
            self.state = .downloadingSapling(progress: Int(progress * 100))
        }
    }

    private func progress(p: BlockProgress) -> Double {
        let overall = p.targetHeight - birthday

        return Double(overall > 0 ? Float((p.progressHeight - birthday)) / Float(overall) : 0)
    }

    private func sync(state: SynchronizerState) {
        synchronizerState = state

        var syncStatus = self.state

        switch state.syncStatus {
        case .disconnected:
            logger?.log(level: .debug, message: "State: Disconnected")
            syncStatus = .syncing(progress: nil, lastBlockDate: nil)
        case .stopped:
            logger?.log(level: .debug, message: "State: Stopped")
            syncStatus = .notSynced(error: AppError.unknownError)
        case .synced:
            logger?.log(level: .debug, message: "State: Synced")
            syncStatus = .synced
            lastBlockHeight = max(state.latestScannedHeight, lastBlockHeight)
            logger?.log(level: .debug, message: "Update BlockHeight = \(lastBlockHeight)")
        case .syncing(let progress):
            logger?.log(level: .debug, message: "State: Syncing")
            logger?.log(level: .debug, message: "State progress: \(progress)")
            lastBlockHeight = max(progress.progressHeight, lastBlockHeight)
            logger?.log(level: .debug, message: "Update BlockHeight = \(lastBlockHeight)")

            lastBlockUpdatedSubject.onNext(())

            syncStatus = .downloadingBlocks(number: progress.progressHeight, lastBlock: progress.targetHeight)
        case .enhancing(let p):
            logger?.log(level: .debug, message: "State: Enhancing")
            logger?.log(level: .debug, message: "State: ==> \n\(p)")
            syncStatus = .enhancingTransactions(number: p.enhancedTransactions, count: p.totalTransactions)
        case .unprepared:
            syncStatus = .notSynced(error: AppError.unknownError)
        case .fetching:
            logger?.log(level: .debug, message: "State: Fetching")
            syncStatus = .syncing(progress: 0, lastBlockDate: nil)
        case .error(let error):
            logger?.log(level: .error, message: "State: Error: \(error)")
            syncStatus = .notSynced(error: AppError.unknownError)
        }

        if syncStatus != self.state {
            self.state = syncStatus
        }
    }

    private func sync(event: SynchronizerEvent) {
        switch event {
        case .foundTransactions(let transactions, let inRange):
            logger?.log(level: .debug, message: "found \(transactions.count) mined txs in range: \(inRange)")
            transactions.forEach { overview in
                logger?.log(level: .debug, message: "tx: v =\(overview.value.decimalValue.decimalString) : fee = \(overview.fee?.decimalString() ?? "N/A") : height = \(overview.minedHeight?.description ?? "N/A")")
            }
            Task {
                let newTxs = await transactionPool?.sync(transactions: transactions) ?? []
                transactionRecordsSubject.onNext(newTxs.map {
                    transactionRecord(fromTransaction: $0)
                })
            }
        case .minedTransaction(let pendingEntity):
            logger?.log(level: .debug, message: "found pending tx: v =\(pendingEntity.value.decimalValue.decimalString) : fee = \(pendingEntity.fee?.decimalString() ?? "N/A")")
            update(transactions: [pendingEntity])
        default:
            logger?.log(level: .debug, message: "Event: \(event)")
        }
    }

    private func reSyncPending() {
        Task {
            let pending = await synchronizer.pendingTransactions
            logger?.log(level: .debug, message: "Resync pending txs: \(pending.count)")
            pending.forEach { entity in
                logger?.log(level: .debug, message: "TX: \(entity.createTime) : \(entity.value.decimalValue.description) : \(entity.recipient.asString ?? ""): \(entity.memo?.encodedString ?? "NoMemo")")
            }
            if !pending.isEmpty {
                update(transactions: pending)
            }
        }
    }

    private func update(transactions: [PendingTransactionEntity]) {
        let newTxs = transactionPool?.sync(transactions: transactions) ?? []
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
                    fee: defaultFeeDecimal(network: network, height: transaction.minedHeight),
                    failed: transaction.failed,
                    lockInfo: nil,
                    conflictingHash: nil,
                    showRawTransaction: showRawTransaction,
                    amount: abs(transaction.value.decimalValue.decimalValue),
                    from: nil,
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
                    fee: defaultFeeDecimal(network: self.network, height: transaction.minedHeight),
                    failed: transaction.failed,
                    lockInfo: nil,
                    conflictingHash: nil,
                    showRawTransaction: showRawTransaction,
                    amount: abs(transaction.value.decimalValue.decimalValue),
                    to: transaction.toAddress,
                    sentToSelf: false,
                    memo: transaction.memo
            )
        }
    }

    static private var cloudSpendParamsURL: URL? {
        URL(string: ZcashSDK.cloudParameterURL + ZcashSDK.spendParamFilename)
    }

    static private var cloudOutputParamsURL: URL? {
        URL(string: ZcashSDK.cloudParameterURL + ZcashSDK.outputParamFilename)
    }

    private func saplingDataExist() -> Bool {
        var isExist = true

        if let cloudSpendParamsURL = Self.cloudOutputParamsURL,
           let destinationURL = try? Self.outputParamsURL(uniqueId: uniqueId),
           !DownloadService.existing(url: destinationURL) {
            isExist = false
            saplingDownloader.download(source: cloudSpendParamsURL, destination: destinationURL)
        }

        if let cloudSpendParamsURL = Self.cloudSpendParamsURL,
           let destinationURL = try? Self.spendParamsURL(uniqueId: uniqueId),
           !DownloadService.existing(url: destinationURL) {
            isExist = false
            saplingDownloader.download(source: cloudSpendParamsURL, destination: destinationURL)
        }

        return isExist
    }

    func fixPendingTransactionsIfNeeded(completion: (() -> ())? = nil) {
        // check if we need to perform the fix or leave
        // get all the pending transactions
        guard !App.shared.localStorage.zcashAlwaysPendingRewind else {
            completion?()
            return
        }

        Task {
            let txs = await synchronizer.pendingTransactions
            // fetch the first one that's reported to be unmined
            guard let firstUnmined = txs.filter({ !$0.isMined }).first else {
                App.shared.localStorage.zcashAlwaysPendingRewind = true
                completion?()
                return
            }

            rewind(unmined: firstUnmined, completion: completion)
        }
    }

    private func rewind(unmined: PendingTransactionEntity, completion: (() -> ())? = nil) {
        synchronizer
                .rewind(.transaction(unmined.makeTransactionEntity(defaultFee: defaultFee(network: network))))
                .sink(receiveCompletion: { result in
                        switch result {
                        case .finished:
                            App.shared.localStorage.zcashAlwaysPendingRewind = true
                            completion?()
                        case .failure:
                            self.rewindQuick()
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
    }

    private func rewindQuick(completion: (() -> ())? = nil) {
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
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
    }

    private var _balanceData: BalanceData {
        guard let synchronizerState = synchronizerState else {
            return BalanceData(balance: 0)
        }

        let verifiedBalance: Zatoshi = synchronizerState.shieldedBalance.verified
        let balance: Zatoshi = synchronizerState.shieldedBalance.total
        let diff = balance - verifiedBalance

        return BalanceData(
                balance: verifiedBalance.decimalValue.decimalValue,
                balanceLocked: diff.decimalValue.decimalValue
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Task { [weak self] in
            await self?.synchronizer.stop()
            self?.logger?.log(level: .debug, message: "Synchronizer Was Stopped")
        }
    }

}

extension ZcashAdapter {
    public static func newBirthdayHeight(network: ZcashNetwork) -> Int {
        BlockHeight.ofLatestCheckpoint(network: network)
    }

    static func initializer(network: ZcashNetwork, uniqueId: String) throws -> Initializer {
        Initializer(
                cacheDbURL: nil,
                fsBlockDbRoot: try fsBlockDbRootURL(uniqueId: uniqueId, network: network),
                dataDbURL: try dataDbURL(uniqueId: uniqueId, network: network),
                pendingDbURL: try pendingDbURL(uniqueId: uniqueId, network: network),
                endpoint: LightWalletEndpoint(address: endPoint, port: 9067, secure: true, streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000),
                network: network,
                spendParamsURL: try spendParamsURL(uniqueId: uniqueId),
                outputParamsURL: try outputParamsURL(uniqueId: uniqueId),
                saplingParamsSourceURL: SaplingParamsSourceURL.default,
                alias: .custom(uniqueId),
                logLevel: .error
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

    private static func fsBlockDbRootURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.networkType.chainName + uniqueId + ZcashSDK.defaultFsCacheName, isDirectory: true)
    }

    private static func cacheDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultCacheDbName, isDirectory: false)
    }

    private static func dataDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultDataDbName, isDirectory: false)
    }

    private static func pendingDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultPendingDbName, isDirectory: false)
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
        guard !preparing else {             // postpone start library until preparing will finish
            logger?.log(level: .debug, message: "Can't start because preparing!")
            waitForStart = true
            return
        }

        if zAddress == nil {         // else we need to try prepare library again
            logger?.log(level: .debug, message: "No address, try to prepare kit again!")
            do {
                let initializer = try Self.initializer(network: network, uniqueId: uniqueId)
                prepare(initializer: initializer, seedData: seedData, walletBirthday: birthday)
            } catch {
                logger?.log(level: .error, message: "Can't start adapter: \(error.localizedDescription)")
            }

            return
        }

        waitForStart = false                // if we has address just start syncing library or downloading sapling data
        if saplingDataExist() {
            logger?.log(level: .debug, message: "Start syncing kit!")
            syncMain(retry: true)
        }
    }

    func stop() {
        Task {
            await synchronizer.stop()
            logger?.log(level: .debug, message: "Synchronizer will stop")
        }
    }

    func refresh() {
        start()
    }

    private func syncMain(retry: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            self?.sync(retry: true)
        }
    }

    private func sync(retry: Bool = false) {
        balanceSubject.onNext(_balanceData)
        fixPendingTransactionsIfNeeded { [weak self] in
            self?.logger?.log(level: .debug, message: "\(Date()) Try to start synchronizer : retry = \(retry), by Thread:\(Thread.current)")

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
        []
    }

    var debugInfo: String {
        let zAddress = zAddress ?? "No Info"
        var balanceState = "No Balance Information yet"

        if let status = self.synchronizerState {
            balanceState = """
                           shielded balance
                             total:  \(balanceData.balanceTotal.description)
                           verified:  \(balanceData.balance)
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

    func transactionsObservable(token: Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
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

    func transactionsSingle(from: TransactionRecord?, token: Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
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

}

extension ZcashAdapter: ISendZcashAdapter {
    enum AddressType {
        case shielded
        case transparent
    }

    var availableBalance: Decimal {
        max(0, balanceData.balance - fee) //TODO: check
    }

    func validate(address: String) throws -> AddressType {
        guard address != receiveAddress.address else {
            throw AppError.addressInvalid
        }

        do {
            switch try Recipient(address, network: self.network.networkType) {
            case .transparent:
                return .transparent
            case .sapling, .unified: // I'm keeping changes to the minimum. Unified Address should be treated as a different address type which will include some shielded pool and possibly others as well.
                return .shielded
            }
        } catch {
            //FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }

    func sendSingle(amount: Decimal, address: Recipient, memo: Memo?) -> Single<()> {
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
                            memo: memo)
                    self.logger?.log(level: .debug, message: "Successful send TX: \(pendingEntity.createTime) : \(pendingEntity.value.decimalValue.description) : \(pendingEntity.recipient.asString ?? "") : \(pendingEntity.memo?.encodedString ?? "NoMemo")")
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
            //FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }

}

extension EnhancementProgress {
    var progress: Int {
        guard totalTransactions <= 0 else {
            return 0
        }
        return Int(Double(self.enhancedTransactions)/Double(self.totalTransactions)) * 100
    }
}

enum ZCashAdapterState: Equatable {
    case idle
    case preparing
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case downloadingSapling(progress: Int)
    case downloadingBlocks(number: Int, lastBlock: Int)
    case scanningBlocks(number: Int, lastBlock: Int)
    case enhancingTransactions(number: Int, count: Int)
    case notSynced(error: Error)

    public static func ==(lhs: ZCashAdapterState, rhs: ZCashAdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.preparing, .preparing): return true
        case (.synced, .synced): return true
        case (.syncing(let lProgress, let lLastBlockDate), .syncing(let rProgress, let rLastBlockDate)): return lProgress == rProgress && lLastBlockDate == rLastBlockDate
        case (.downloadingSapling(let lProgress), .downloadingSapling(let rProgress)): return lProgress == rProgress
        case (.downloadingBlocks(let lNumber, let lLast), .downloadingBlocks(let rNumber, let rLast)): return lNumber == rNumber && lLast == rLast
        case (.scanningBlocks(let lNumber, let lLast), .scanningBlocks(let rNumber, let rLast)): return lNumber == rNumber && lLast == rLast
        case (.enhancingTransactions(let lNumber, let lCount), .enhancingTransactions(let rNumber, let rCount)): return lNumber == rNumber && lCount == rCount
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }

    var adapterState: AdapterState {
        switch self {
        case .idle: return .customSyncing(main: "Stopped", secondary: nil, progress: nil)
        case .preparing: return .customSyncing(main: "Preparing...", secondary: nil, progress: nil)
        case .synced: return .synced
        case .syncing(let progress, let lastDate): return .syncing(progress: progress, lastBlockDate: lastDate)
        case .downloadingSapling(let progress):
            return .customSyncing(main: "Downloading Sapling... \(progress)%", secondary: nil, progress: progress)
        case .downloadingBlocks(let number, let lastBlock):
            return .customSyncing(main: "Downloading Blocks", secondary: lastBlock == 0 ? nil : "\(number)/\(lastBlock)", progress: nil)
        case .scanningBlocks(let number, let lastBlock):
            return .customSyncing(main: "Scanning Blocks", secondary: "\(number)/\(lastBlock)", progress: nil)
        case .enhancingTransactions(let number, let count):
            let progress: String? = count == 0 ? nil : "\(number)/\(count)"
            return .customSyncing(main: "Enhancing Transactions", secondary: progress, progress: nil)
        case .notSynced(let error): return .notSynced(error: error)
        }
    }

    var isDownloading: Bool {
        switch self {
        case .downloadingBlocks: return true
        default: return false
        }
    }

    var isScanning: Bool {
        switch self {
        case .scanningBlocks: return true
        default: return false
        }
    }

    var lastProcessedBlockHeight: Int? {
        switch self {
        case .downloadingBlocks(_, let last), .scanningBlocks(_, let last): return last
        default: return nil
        }
    }

}
