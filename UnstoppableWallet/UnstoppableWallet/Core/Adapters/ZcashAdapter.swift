import Foundation
import UIKit
import ZcashLightClientKit
import RxSwift
import HdWalletKit
import HsToolKit
import MarketKit
import HsExtensions


class ZcashAdapter {
    private static let limitShowingDownloadBlockCount = 50
    private let disposeBag = DisposeBag()

    private let token: Token
    private let transactionSource: TransactionSource
    private let localStorage = App.shared.localStorage       //temporary decision. Will move to init
    private let saplingDownloader = DownloadService(queueLabel: "io.SaplingDownloader")
    private let synchronizer: SDKSynchronizer
    private var transactionPool: ZcashTransactionPool
    private var address: UnifiedAddress
    private var saplingAddress: SaplingAddress // This should be replaced by unified address.
    private let uniqueId: String
    private let spendingKey: UnifiedSpendingKey // this being a single account does not need to be an array
    private let loggingProxy = ZcashLogger(logLevel: .error)

    private(set) var network: ZcashNetwork
    private(set) var fee: Decimal

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private let birthday: BlockHeight

    private var lastBlockHeight: Int = 0
    private var synchronizerState: SDKSynchronizer.SynchronizerState? {
        didSet {
            let latestScannedBlock = synchronizerState?.latestScannedHeight ?? 0
            lastBlockHeight = max(lastBlockHeight, latestScannedBlock)
            lastBlockUpdatedSubject.onNext(())

            balanceSubject.onNext(_balanceData)
        }
    }

    private var state: ZCashAdapterState {
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
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        network = ZcashNetworkBuilder.network(for: .mainnet)
        fee = network.constants.defaultFee().decimalValue.decimalValue

//        let endPoint = "lightwalletd.testnet.electriccoin.co" // testnet
        let endPoint = "lightwalletd.electriccoin.co" //"mainnet.lightwalletd.com"

        token = wallet.token
        transactionSource = wallet.transactionSource
        uniqueId = wallet.account.id
        switch wallet.account.origin {
        case .created: birthday = Self.newBirthdayHeight(network: network)
        case .restored:
            if let height = restoreSettings.birthdayHeight {
                birthday = max(height, network.constants.saplingActivationHeight)
            } else {
                birthday = network.constants.saplingActivationHeight
            }
        }

        let seedData = [UInt8](seed)
        let derivationTool = DerivationTool(networkType: network.networkType)

        guard let unifiedSpendingKey =  try? derivationTool.deriveUnifiedSpendingKey(seed: seedData, accountIndex: 0),
              let unifiedViewingKey = try? unifiedSpendingKey.deriveFullViewingKey() else {
            throw AppError.ZcashError.noReceiveAddress
        }



        let initializer = Initializer(cacheDbURL:try! ZcashAdapter.cacheDbURL(uniqueId: uniqueId, network: network),
                dataDbURL: try! ZcashAdapter.dataDbURL(uniqueId: uniqueId, network: network),
                pendingDbURL: try! ZcashAdapter.pendingDbURL(uniqueId: uniqueId, network: network),
                endpoint: LightWalletEndpoint(address: endPoint, port: 9067, singleCallTimeoutInMillis: 1000000, streamingCallTimeoutInMillis: 1000000),
                network: network,
                spendParamsURL: try! ZcashAdapter.spendParamsURL(uniqueId: uniqueId),
                outputParamsURL: try! ZcashAdapter.outputParamsURL(uniqueId: uniqueId),
                viewingKeys: [unifiedViewingKey],
                walletBirthday: birthday,
                loggerProxy: loggingProxy)

        spendingKey = unifiedSpendingKey

        synchronizer = try SDKSynchronizer(initializer: initializer)

        state = .downloadingBlocks(number: 0, lastBlock: lastBlockHeight)
        _ = try synchronizer.prepare(with: seedData)

        guard let unifiedAddress = synchronizer.getUnifiedAddress(accountIndex: 0),
              let saplingAddress = unifiedAddress.saplingReceiver() else {
            throw AppError.ZcashError.noReceiveAddress
        }

        address = unifiedAddress
        self.saplingAddress = saplingAddress
        transactionPool = ZcashTransactionPool(synchronizer: synchronizer, receiveAddress: saplingAddress)

        subscribeSynchronizerNotifications()
        subscribeDownloadService()

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        transactionPool.store(confirmedTransactions: synchronizer.clearedTransactions, pendingTransactions: synchronizer.pendingTransactions)

        let shielded = synchronizer.getShieldedBalance().decimalValue.decimalValue
        let shieldedVerified = synchronizer.getShieldedVerifiedBalance().decimalValue.decimalValue
        balanceSubject.onNext(BalanceData(
                balance: shieldedVerified,
                balanceLocked: shielded - shieldedVerified
        ))
    }

    nonisolated private func subscribeSynchronizerNotifications() {
        // state changing
        let center = NotificationCenter.default
        let subscribeToNotifications: [Notification.Name] = [
            .synchronizerStarted,
            .synchronizerProgressUpdated,
            .synchronizerStatusWillUpdate,
            .synchronizerSynced,
            .synchronizerStopped,
            .synchronizerDisconnected,
            .synchronizerSyncing,
            .synchronizerEnhancing,
            .synchronizerFetching,
            .synchronizerFailed
        ]

        for notificationName in subscribeToNotifications {
            center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: notificationName, object: synchronizer)
        }

        center.addObserver(self, selector: #selector(blockProcessorUpdated(_:)), name: Notification.Name.blockProcessorUpdated, object: synchronizer)
        center.addObserver(self, selector: #selector(blockProcessorFinished(_:)), name: Notification.Name.blockProcessorFinished, object: synchronizer)
        center.addObserver(self, selector: #selector(blockProcessorStartedEnhancing(_:)), name: Notification.Name.blockProcessorFinished, object: synchronizer)

//        center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: Notification.Name.synchronizerDisconnected, object: synchronizer)
//        center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: Notification.Name.synchronizerStarted, object: synchronizer)
//        center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: Notification.Name.synchronizerSynced, object: synchronizer)
//        center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: Notification.Name.synchronizerDisconnected, object: synchronizer)
//        center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: Notification.Name.synchronizerFailed, object: synchronizer)

        // sync progress changing
        center.addObserver(self, selector: #selector(processorNotificationUpdated(_:)), name: Notification.Name.synchronizerProgressUpdated, object: synchronizer)

        //found new transactions
        center.addObserver(self, selector: #selector(transactionsUpdated(_:)), name: Notification.Name.synchronizerFoundTransactions, object: synchronizer)

//        //latestHeight
//        center.addObserver(self, selector: #selector(blockHeightUpdated(_:)), name: Notification.Name.blockProcessorUpdated, object: synchronizer.blockProcessor)
    }

    @objc private func blockProcessorUpdated(_ notification: Notification) {
        print("blockProcessorUpdated")
    }

    @objc private func blockProcessorFinished(_ notification: Notification) {
        print("blockProcessorFinished")

    }

    @objc private func blockProcessorStartedEnhancing(_ notification: Notification) {
        print("blockProcessorStartedEnhancing")
    }

    nonisolated private func subscribeDownloadService() {
        subscribe(disposeBag, saplingDownloader.stateObservable) { [weak self] in self?.downloaderStatusUpdated(state: $0) }
    }

    @objc private func didEnterBackground(_ notification: Notification) {
        stop()
    }

    private func downloaderStatusUpdated(state: DownloadService.State) {
        switch state {
        case .idle:
            Task {
                await sync()
            }
        case .inProgress(let progress):
            self.state = .downloadingSapling(progress: Int(progress * 100))
        }
    }

    private func progress(p: BlockProgress) -> Double {
        let overall = p.targetHeight - birthday

        return Double(overall > 0 ? Float((p.progressHeight - birthday)) / Float(overall) : 0)
    }

    @objc private func processorNotificationUpdated(_ notification: Notification) {
        print("\(Date()) ==> SYNCRONIZER update! \(Thread.current)")
        print("Old State: \(state)")
        var newState = state

//        var blockDate: Date? = nil
//        if let blockTime = notification.userInfo?[SDKSynchronizer.NotificationKeys.blockDate] as? Date {
//            blockDate = blockTime
//        }

        switch synchronizer.status {
        case .disconnected:
            print("==> ==> Disconnected")
            newState = .syncing(progress: nil, lastBlockDate: nil)
        case .stopped:
            print("==> ==> Stopped")
            newState = .notSynced(error: AppError.unknownError)
        case .synced:
            print("==> ==> Synced")
            newState = .synced
            synchronizerState = notification.userInfo?[SDKSynchronizer.NotificationKeys.synchronizerState] as? SDKSynchronizer.SynchronizerState
        case .syncing(let p):
            print("==> ==> Syncing")
            print("==> ==> ==> \n\(p)")
            var lastDownloaded = 0
            if case let .downloadingBlocks(number, lastBlock) = state {
                lastDownloaded = number
            }

            let diff = p.progressHeight - lastDownloaded
            if !state.isDownloading ||
                       (diff > Self.limitShowingDownloadBlockCount) { // show first changing state, every 100 blocks and last 100 blocks
                newState = .downloadingBlocks(number: p.progressHeight, lastBlock: p.targetHeight)
            }
        case .enhancing(let p):
            print("==> ==> Enhancing")
            print("==> ==> ==> \n\(p)")
            newState = .enhancingTransactions(number: p.enhancedTransactions, count: p.totalTransactions)
        case .unprepared:
            newState = .notSynced(error: AppError.unknownError)
//        case .scanning(let p):
//            let diff = p.targetHeight - p.progressHeight
//            if !state.isScanning ||
//                       (diff < Self.limitShowingDownloadBlockCount) ||
//                       (diff % Self.limitShowingDownloadBlockCount) == 0 { // show first changing state, every 100 blocks and last 100 blocks
//                newState = .scanningBlocks(number: p.progressHeight, lastBlock: p.targetHeight)
//            }
        case .fetching:
            print("==> ==> Fetching")
            newState = .syncing(progress: 0, lastBlockDate: nil)
        case .error:
            newState = .notSynced(error: AppError.unknownError)
        }

        if newState != state {
            state = newState
        }
    }

    @objc private func transactionsUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let txs = userInfo[SDKSynchronizer.NotificationKeys.foundTransactions] as? [ZcashTransaction.Overview] {
            let newTxs = transactionPool.sync(transactions: txs)
            transactionRecordsSubject.onNext(newTxs.map {
                transactionRecord(fromTransaction: $0)
            })
        }
    }

    @objc private func blockHeightUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let progress = userInfo[CompactBlockProcessorNotificationKey.progress] as? CompactBlockProgress,
           let targetHeight = progress.targetHeight {
            lastBlockHeight = targetHeight
            lastBlockUpdatedSubject.onNext(())
        }
    }

    private func syncPending() async {
        let newTxs = transactionPool.sync(transactions: synchronizer.pendingTransactions)

        if !newTxs.isEmpty {
            transactionRecordsSubject.onNext(newTxs.map {
                transactionRecord(fromTransaction: $0)
            })
        }
    }

    func transactionRecord(fromTransaction transaction: ZcashTransactionWrapper) -> TransactionRecord {
        let showRawTransaction = transaction.minedHeight == nil || transaction.failed

        // TODO: Should have it's own transactions with memo
        if transaction.sentTo(address: receiveAddress) {
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
                    amount: transaction.value.decimalValue.decimalValue,
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
                    amount: transaction.value.decimalValue.decimalValue,
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

    func fixPendingTransactionsIfNeeded() async {
        // check if we need to perform the fix or leave
        guard !localStorage.zcashAlwaysPendingRewind else {
            return
        }

        do {
            // get all the pending transactions
            let txs = try synchronizer.allPendingTransactions()

            // fetch the first one that's reported to be unmined
            guard let firstUnmined = txs.filter({ !$0.isMined }).first else {
                localStorage.zcashAlwaysPendingRewind = true
                return
            }

            try await synchronizer.rewind(.transaction(firstUnmined.makeTransactionEntity(defaultFee: defaultFee(network: network))))
            localStorage.zcashAlwaysPendingRewind = true
        } catch SynchronizerError.rewindErrorUnknownArchorHeight {
            do {
                try await synchronizer.rewind(.quick)
                localStorage.zcashAlwaysPendingRewind = true
            } catch {
                loggingProxy.error("attempt to fix pending transactions failed with error: \(error)", file: #file, function: #function, line: 0)
            }
        } catch {
            loggingProxy.error("attempt to fix pending transactions failed with error: \(error)", file: #file, function: #function, line: 0)
        }
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
        synchronizer.stop()
    }

}

extension ZcashAdapter {
    public static func newBirthdayHeight(network: ZcashNetwork) -> Int {
        BlockHeight.ofLatestCheckpoint(network: network)
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("z-cash-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
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
        self.network.networkType == .mainnet
    }

    func start() {
        Task {
            if saplingDataExist() {
                await sync()
            }
        }
    }

    func stop() {
        synchronizer.stop()
    }


    func refresh() {
        Task { @MainActor in
            if saplingDataExist() {
                await sync(retry: true)
            }
        }
    }

    private func sync(retry: Bool = false) async {
        do {
            balanceSubject.onNext(_balanceData)
            await fixPendingTransactionsIfNeeded()
//            print("\(Date()) Try to start synchronizer : retry = \(retry), by Thread:\(Thread.current)")
            try synchronizer.start(retry: retry)
        } catch {
            state = .notSynced(error: error)
        }
    }

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        let tAddress = self.address.transparentReceiver()?.stringEncoded ?? "No Info"
        let zAddress = self.address.saplingReceiver()?.stringEncoded ?? "No Info"
        var balanceState = "No Balance Information yet"

        if let status = self.synchronizerState {
            balanceState = """
                           shielded balance
                             total:  \(synchronizer.initializer.getBalance().decimalValue.decimalValue)
                           verified:  \(synchronizer.initializer.getVerifiedBalance().decimalValue.decimalValue)
                           transparent balance
                                total: \(String(describing: status.transparentBalance.total))
                             verified: \(String(describing: status.transparentBalance.verified))
                           """
        }
        return """
               ZcashAdapter
               z-address: \(String(describing: zAddress))
               t-address: \(String(describing: tAddress))
               spendingKeys: \(spendingKey.description)
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
        transactionPool.transactionsSingle(from: from, filter: filter, limit: limit).map { [weak self] txs in
            txs.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func rawTransaction(hash: String) -> String? {
        transactionPool.transaction(by: hash)?.raw?.hs.hex
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

    var receiveAddress: String {
        // only first account
        saplingAddress.stringEncoded
    }

}

extension ZcashAdapter: ISendZcashAdapter {
    enum AddressType {
        case shielded
        case transparent
    }

    var availableBalance: Decimal {
        max(0, synchronizer.initializer.getVerifiedBalance().decimalValue.decimalValue - fee)
    }

    func validate(address: String) throws -> AddressType {

        guard address != receiveAddress else {
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

    func sendSingle(
            amount: Decimal,
            address: Recipient, // changed to recipient. no point to getting this far without invalid address
            memo: Memo? // changed to Memo type
    ) -> Single<()> {
        let zatoshi = Zatoshi.from(decimal: amount)
        let synchronizer = synchronizer
        let unifiedSpendingKey = self.spendingKey

        return Single<()>.create { single in
            Task(priority: .userInitiated) { @MainActor in
                do {
                    _ = try await synchronizer.sendToAddress(
                            spendingKey: unifiedSpendingKey,
                            zatoshi: zatoshi,
                            toAddress: address,
                            memo: memo
                    )
                    await self.syncPending()
                    single(.success(()))
                } catch {
                    single(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func recipient(from stringEncodedAddress: String) -> ZcashLightClientKit.Recipient? {
        try? Recipient(stringEncodedAddress, network: self.network.networkType)
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

private class ZcashLogger: ZcashLightClientKit.Logger {

    private let level: HsToolKit.Logger.Level
    private let logger: HsToolKit.Logger

    init(logLevel: HsToolKit.Logger.Level) {
        level = logLevel

        logger = Logger(minLogLevel: logLevel)
    }

    func debug(_ message: String, file: StaticString, function: StaticString, line: Int) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    func info(_ message: String, file: StaticString, function: StaticString, line: Int) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    func event(_ message: String, file: StaticString, function: StaticString, line: Int) {
        log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    func warn(_ message: String, file: StaticString, function: StaticString, line: Int) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    func error(_ message: String, file: StaticString, function: StaticString, line: Int) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    private func log(level: HsToolKit.Logger.Level, message: String, file: StaticString, function: StaticString, line: Int) {
        let file = file.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        let function = function.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        logger.log(level: level, message: message, file: file, function: function, line: line)
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
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case downloadingSapling(progress: Int)
    case downloadingBlocks(number: Int, lastBlock: Int)
    case scanningBlocks(number: Int, lastBlock: Int)
    case enhancingTransactions(number: Int, count: Int)
    case notSynced(error: Error)

    public static func ==(lhs: ZCashAdapterState, rhs: ZCashAdapterState) -> Bool {
        switch (lhs, rhs) {
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
        case .synced: return .synced
        case .syncing(let progress, let lastDate): return .syncing(progress: progress, lastBlockDate: lastDate)
        case .downloadingSapling(let progress):
            return .customSyncing(main: "Downloading Sapling... \(progress)%", secondary: nil, progress: progress)
        case .downloadingBlocks(let number, let lastBlock):
            return .customSyncing(main: "Downloading Blocks", secondary: "\(number)/\(lastBlock)", progress: nil)
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
