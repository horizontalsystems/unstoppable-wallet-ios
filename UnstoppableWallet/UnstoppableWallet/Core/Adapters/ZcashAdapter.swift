import Foundation
import UIKit
import ZcashLightClientKit
import RxSwift
import HdWalletKit
import HsToolKit
import MarketKit
import HsExtensions

class ZcashAdapter {
    private let disposeBag = DisposeBag()

    var fee: Decimal { defaultFee() }

    private let token: Token
    private let transactionSource: TransactionSource
    private let localStorage = App.shared.localStorage       //temporary decision. Will move to init
    private let saplingDownloader = DownloadService(queueLabel: "io.SaplingDownloader")
    private let synchronizer: SDKSynchronizer
    private let transactionPool: ZcashTransactionPool
    private let address: UnifiedAddress
    private let uniqueId: String
    private let keys: [String]
    private let loggingProxy = ZcashLogger(logLevel: .error)
    private(set) var network: ZcashNetwork
    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private let birthday: BlockHeight

    private var lastBlockHeight: Int = 0

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

    private func defaultFee(height: Int? = nil) -> Decimal {
        let fee: Zatoshi
        if let lastBlockHeight = height {
            fee = network.constants.defaultFee(for: lastBlockHeight)
        } else {
            fee = network.constants.defaultFee()
        }
        return fee.decimalValue.decimalValue
    }

    init(wallet: Wallet, restoreSettings: RestoreSettings, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }
        network = ZcashNetworkBuilder.network(for: testMode ? .testnet : .mainnet)
        let endPoint = testMode ? "lightwalletd.testnet.electriccoin.co" : "zcash.horizontalsystems.xyz"

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
        let unifiedViewingKeys = try derivationTool.deriveUnifiedViewingKeysFromSeed(seedData, numberOfAccounts: 1)

        guard let uvk = unifiedViewingKeys.first,
              let ua = try? derivationTool.deriveUnifiedAddressFromUnifiedViewingKey(uvk) else {
            throw AppError.ZcashError.noReceiveAddress
        }

        address = ua

        let initializer = Initializer(cacheDbURL:try! ZcashAdapter.cacheDbURL(uniqueId: uniqueId, network: network),
                dataDbURL: try! ZcashAdapter.dataDbURL(uniqueId: uniqueId, network: network),
                pendingDbURL: try! ZcashAdapter.pendingDbURL(uniqueId: uniqueId, network: network),
                endpoint: LightWalletEndpoint(address: endPoint, port: 9067, singleCallTimeoutInMillis: 1000000, streamingCallTimeoutInMillis: 1000000),
                network: network,
                spendParamsURL: try! ZcashAdapter.spendParamsURL(uniqueId: uniqueId),
                outputParamsURL: try! ZcashAdapter.outputParamsURL(uniqueId: uniqueId),
                viewingKeys: unifiedViewingKeys,
                walletBirthday: birthday,
                loggerProxy: loggingProxy)



        try initializer.initialize()
        keys = try derivationTool.deriveSpendingKeys(seed: seedData, numberOfAccounts: 1)

        synchronizer = try SDKSynchronizer(initializer: initializer)

        try synchronizer.prepare()

        transactionPool = ZcashTransactionPool(receiveAddress: address.zAddress)
        transactionPool.store(confirmedTransactions: synchronizer.clearedTransactions, pendingTransactions: synchronizer.pendingTransactions)

        state = .downloadingBlocks(number: 0, lastBlock: lastBlockHeight)
//        lastBlockHeight = try? synchronizer.latestHeight()

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        subscribeSynchronizerNotifications()
        subscribeDownloadService()
    }

    private func subscribeSynchronizerNotifications() {
        let center = NotificationCenter.default

        // state changing
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.synchronizerDisconnected, object: synchronizer)
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.synchronizerStarted, object: synchronizer)
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.synchronizerSynced, object: synchronizer)
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.synchronizerDisconnected, object: synchronizer)
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.synchronizerFailed, object: synchronizer)

        // sync progress changing
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.synchronizerProgressUpdated, object: synchronizer)
        center.addObserver(self, selector: #selector(statusUpdated(_:)), name: Notification.Name.transactionsUpdated, object: synchronizer)

        //found new transactions
        center.addObserver(self, selector: #selector(transactionsUpdated(_:)), name: Notification.Name.synchronizerFoundTransactions, object: synchronizer)

        //latestHeight
        center.addObserver(self, selector: #selector(blockHeightUpdated(_:)), name: Notification.Name.blockProcessorUpdated, object: synchronizer.blockProcessor)
    }

    private func subscribeDownloadService() {
        subscribe(disposeBag, saplingDownloader.stateObservable) { [weak self] in self?.downloaderStatusUpdated(state: $0) }
    }

    @objc private func didEnterBackground(_ notification: Notification) {
       stop()
    }

    private func downloaderStatusUpdated(state: DownloadService.State) {
        switch state {
        case .idle: sync()
        case .inProgress(let progress):
            self.state = .downloadingSapling(progress: Int(progress * 100))
        }
    }

    private func progress(p: BlockProgress) -> Double {
        let overall = p.targetHeight - birthday

        return Double(overall > 0 ? Float((p.progressHeight - birthday)) / Float(overall) : 0)
    }

    @objc private func statusUpdated(_ notification: Notification) {
        var newState = state
        var blockDate: Date? = nil
        if let blockTime = notification.userInfo?[SDKSynchronizer.NotificationKeys.blockDate] as? Date {
            blockDate = blockTime
        }
        switch synchronizer.status {
        case .disconnected: newState = .notSynced(error: AppError.noConnection)
        case .stopped: newState = .notSynced(error: AppError.unknownError)
        case .synced: newState = .synced
        case .downloading(let p):
            newState = .downloadingBlocks(number: p.progressHeight, lastBlock: p.targetHeight)
        case .enhancing(let p):
            newState = .enhancingTransactions(number: p.enhancedTransactions, count: p.totalTransactions)
        case .unprepared:
            newState = .notSynced(error: AppError.unknownError)
        case .validating:
            newState = .syncing(progress: 0, lastBlockDate: blockDate)
        case .scanning(let p):
            newState = .scanningBlocks(number: p.progressHeight, lastBlock: p.targetHeight)
        case .fetching:
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
           let txs = userInfo[SDKSynchronizer.NotificationKeys.foundTransactions] as? [ConfirmedTransactionEntity] {
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

        balanceSubject.onNext(_balanceData)
    }

    private func syncPending() {
        let newTxs = transactionPool.sync(transactions: synchronizer.pendingTransactions)

        if !newTxs.isEmpty {
            transactionRecordsSubject.onNext(newTxs.map {
                transactionRecord(fromTransaction: $0)
            })
        }
    }

    func transactionRecord(fromTransaction transaction: ZcashTransaction) -> TransactionRecord {
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
                    fee: defaultFee(height: transaction.minedHeight),
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
                    fee: defaultFee(height: transaction.minedHeight),
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

    func fixPendingTransactionsIfNeeded() {
        // check if we need to perform the fix or leave
        guard !localStorage.zcashAlwaysPendingRewind else {
            return
        }

        do {
            // get all the pending transactions
            let txs = try synchronizer.allPendingTransactions()

            // fetch the first one that's reported to be unmined
            guard let firstUnmined = txs.filter({ !$0.isMined }).first?.transactionEntity else {
                localStorage.zcashAlwaysPendingRewind = true
                return
            }

            try synchronizer.rewind(.transaction(firstUnmined))
            localStorage.zcashAlwaysPendingRewind = true
        } catch SynchronizerError.rewindErrorUnknownArchorHeight {
            do {
                try synchronizer.rewind(.quick)
                localStorage.zcashAlwaysPendingRewind = true
            } catch {
                loggingProxy.error("attempt to fix pending transactions failed with error: \(error)", file: #file, function: #function, line: 0)
            }
        } catch {
            loggingProxy.error("attempt to fix pending transactions failed with error: \(error)", file: #file, function: #function, line: 0)
        }
    }

    private var _balanceData: BalanceData {
        let verifiedBalance: Zatoshi = synchronizer.initializer.getVerifiedBalance()
        let balance: Zatoshi = synchronizer.initializer.getBalance()
        let diff = balance - verifiedBalance

        return BalanceData(
                balance: verifiedBalance.decimalValue.decimalValue,
                balanceLocked: diff.decimalValue.decimalValue
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        synchronizer.blockProcessor.stop()
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
        true
    }

    func start() {
        if saplingDataExist() {
            sync()
        }
    }

    func stop() {
        synchronizer.stop()
    }

    func refresh() {
        if saplingDataExist() {
            sync(retry: true)
        }
    }

    private func sync(retry: Bool = false) {
        do {
            fixPendingTransactionsIfNeeded()
            try synchronizer.start(retry: retry)
        } catch {
            state = .notSynced(error: error)
        }
    }

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        let taddress = synchronizer.getTransparentAddress(accountIndex: 0)
        let tBalance = try? synchronizer.getTransparentBalance(address: taddress ?? "")
        return """
        ZcashAdapter
        z-address: \(String(describing: synchronizer.getShieldedAddress(accountIndex: 0)))
        t-address: \(String(describing: taddress ))
        spendingKeys: \(keys.description)
        shielded balance
                  total:  \(synchronizer.initializer.getBalance().decimalValue.decimalValue)
               verified:  \(synchronizer.initializer.getVerifiedBalance().decimalValue.decimalValue)
        transparent balance
                     total: \(tBalance == nil ? "failed" : String(describing: tBalance?.total))
                  verified: \(tBalance == nil ? "failed" : String(describing: tBalance?.verified))
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
        address.zAddress
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
            let derivationTool = DerivationTool(networkType: self.network.networkType)

            let validZAddress = try derivationTool.isValidShieldedAddress(address)
            let validTAddress = try derivationTool.isValidTransparentAddress(address)

            guard validZAddress || validTAddress else {
                throw AppError.addressInvalid
            }

            return validZAddress ? .shielded : .transparent
        } catch {
            //FIXME: Should this be handled another way? logged? how?
            throw AppError.addressInvalid
        }
    }

    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<()> {
        guard let spendingKey = keys.first else {
            return Single.error(AdapterError.unsupportedAccount)
        }

        let zatoshi = Zatoshi.from(decimal: amount)

        let synchronizer = synchronizer

        return Single<()>.create { [weak self] single in
            synchronizer.sendToAddress(spendingKey: spendingKey, zatoshi: zatoshi, toAddress: address, memo: memo, from: 0) { result in
                self?.syncPending()
                switch result {
                case .success:
                    single(.success(()))
                case .failure(let error):
                    single(.error(error))
                }
            }

            return Disposables.create()
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
}
