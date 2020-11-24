import Foundation

import ZcashLightClientKit
import RxSwift
import HdWalletKit
import HsToolKit

class ZcashAdapter {
    private static let coinRate = Decimal(ZcashSDK.ZATOSHI_PER_ZEC)
    let fee = Decimal(ZcashSDK.MINERS_FEE_ZATOSHI) / ZcashAdapter.coinRate

    private let synchronizer: SDKSynchronizer
    private let transactionPool: ZcashTransactionPool

    private let keys: [String]
    private let loggingProxy = ZcashLogger(logLevel: .error)

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let stateUpdatedSubject = PublishSubject<Void>()
    private let balanceUpdatedSubject = PublishSubject<Void>()
    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private var lastBlockHeight: Int? = 0

    private(set) var state: AdapterState

    init(wallet: Wallet, syncMode: SyncMode?, testMode: Bool) throws {
        guard case let .zcash(words, birthdayHeight) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        let endPoint = testMode ? "lightwalletd.testnet.electriccoin.co" : "zcash.horizontalsystems.xyz"

        let uniqueId = wallet.account.id
        let birthday: Int
        switch syncMode {
        case .new: birthday = Self.newBirthdayHeight
        default:
            if let height = birthdayHeight {
                birthday = WalletBirthday.birthday(with: max(height, ZcashSDK.SAPLING_ACTIVATION_HEIGHT)).height
            } else {
                birthday = ZcashSDK.SAPLING_ACTIVATION_HEIGHT
            }
        }

        let initializer = Initializer(cacheDbURL:try! ZcashAdapter.cacheDbURL(uniqueId: uniqueId),
                dataDbURL: try! ZcashAdapter.dataDbURL(uniqueId: uniqueId),
                pendingDbURL: try! ZcashAdapter.pendingDbURL(uniqueId: uniqueId),
                endpoint: LightWalletEndpoint(address: endPoint, port: 9067),
                spendParamsURL: try! ZcashAdapter.spendParamsURL(uniqueId: uniqueId),
                outputParamsURL: try! ZcashAdapter.outputParamsURL(uniqueId: uniqueId),
                loggerProxy: loggingProxy)


        let seedData = [UInt8](Mnemonic.seed(mnemonic: words))
        try initializer.initialize(viewingKeys: try DerivationTool.default.deriveViewingKeys(seed: seedData, numberOfAccounts: 1),
                walletBirthday: BlockHeight(birthday))

        keys = try DerivationTool.default.deriveSpendingKeys(seed: seedData, numberOfAccounts: 1)
        synchronizer = try SDKSynchronizer(initializer: initializer)

        transactionPool = ZcashTransactionPool()
        transactionPool.store(confirmedTransactions: synchronizer.clearedTransactions, pendingTransactions: synchronizer.pendingTransactions)

        state = .syncing(progress: 0, lastBlockDate: nil)
        lastBlockHeight = try? synchronizer.latestHeight()

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        subscribeSynchronizerNotifications()
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

    @objc private func didEnterBackground(_ notification: Notification) {
        synchronizer.stop()
    }

    @objc private func willEnterForeground(_ notification: Notification) {
        if synchronizer.status == .stopped || synchronizer.status == .disconnected {
            try? synchronizer.start()
        }
    }

    @objc private func statusUpdated(_ notification: Notification) {
        var newState = state

        switch synchronizer.status {
        case .disconnected: newState = .notSynced(error: AppError.noConnection)
        case .stopped: newState = .notSynced(error: AppError.unknownError)
        case .synced: newState = .synced
        case .syncing: newState = .syncing(progress: Int(synchronizer.progress * 100), lastBlockDate: nil)
        }

        if newState != state {
            state = newState
            stateUpdatedSubject.onNext(())
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
        if let userInfo = notification.userInfo, let blockHeight = userInfo[CompactBlockProcessorNotificationKey.progressHeight] as? BlockHeight {
            lastBlockHeight = blockHeight
            lastBlockUpdatedSubject.onNext(())
        }

        balanceUpdatedSubject.onNext(())
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
        var incoming = true
        if let toAddress = transaction.toAddress, toAddress != receiveAddress {
            incoming = false
        }

        let showRawTransaction = transaction.minedHeight == nil || transaction.failed

        return TransactionRecord(
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                interTransactionIndex: 0,
                type: incoming ? .incoming : .outgoing,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.DEFAULT_REWIND_DISTANCE,
                amount: Decimal(transaction.value) / Self.coinRate,
                fee: fee,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                failed: transaction.failed,
                from: nil,
                to: transaction.toAddress,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.synchronizer.blockProcessor?.stop()
        self.synchronizer.stop()
    }

}

extension ZcashAdapter {

    public static var newBirthdayHeight: Int {
        WalletBirthday.birthday(with: 0).height
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("z-cash-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    private static func cacheDbURL(uniqueId: String) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX + uniqueId + ZcashSDK.DEFAULT_CACHES_DB_NAME, isDirectory: false)
    }

    private static func dataDbURL(uniqueId: String) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX + uniqueId + ZcashSDK.DEFAULT_DATA_DB_NAME, isDirectory: false)
    }

    private static func pendingDbURL(uniqueId: String) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX + uniqueId + ZcashSDK.DEFAULT_PENDING_DB_NAME, isDirectory: false)
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

    func start() {
        sync()
    }

    func stop() {
        synchronizer.stop()
    }

    func refresh() {
        sync()
    }

    private func sync() {
        do {
            try synchronizer.start()
        } catch {
            state = .notSynced(error: error)
            stateUpdatedSubject.onNext(())
        }
    }

    var debugInfo: String {
        """
        ZcashAdapter address: \(synchronizer.getAddress(accountIndex: 0))
        spendingKeys: \(keys.description)
        balance: \(synchronizer.initializer.getBalance())
        verified balance: \(synchronizer.initializer.getVerifiedBalance())
        """
    }

}

extension ZcashAdapter: ITransactionsAdapter {

    var lastBlockInfo: LastBlockInfo? {
        lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        lastBlockUpdatedSubject.asObservable()
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        transactionPool.transactionsSingle(from: from, limit: limit).map { [weak self] txs in
            txs.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func rawTransaction(hash: String) -> String? {
        transactionPool.transaction(by: hash)?.raw?.hex
    }

}

extension ZcashAdapter: IBalanceAdapter {

    var stateUpdatedObservable: Observable<Void> {
        stateUpdatedSubject.asObservable()
    }

    var balanceUpdatedObservable: Observable<Void> {
        balanceUpdatedSubject.asObservable()
    }

    var balance: Decimal {
        Decimal(synchronizer.initializer.getVerifiedBalance()) / Self.coinRate
    }

    var balanceLocked: Decimal? {
        let verifiedBalance = Decimal(synchronizer.initializer.getVerifiedBalance())
        let balance = Decimal(synchronizer.initializer.getBalance())
        let diff = balance - verifiedBalance

        return !diff.isZero ? (diff / Self.coinRate) : nil
    }

}

extension ZcashAdapter: IDepositAdapter {

    var receiveAddress: String {
        // only first account
        synchronizer.getAddress(accountIndex: 0)
    }

}

extension ZcashAdapter: ISendZcashAdapter {

    var availableBalance: Decimal {
        max(0, Decimal(synchronizer.initializer.getVerifiedBalance()) / Self.coinRate - fee)
    }

    func validate(address: String) throws {
        guard !synchronizer.initializer.isValidTransparentAddress(address) else {
            throw AppError.zcash(reason: .transparentAddress)
        }

        guard synchronizer.initializer.isValidShieldedAddress(address) else {
            throw AppError.addressInvalid
        }

        guard address != receiveAddress else {
            throw AppError.zcash(reason: .sendToSelf)
        }
    }

    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<()> {
        guard let spendingKey = keys.first else {
            return Single.error(AdapterError.unsupportedAccount)
        }

        let amount = NSDecimalNumber(decimal: amount * Self.coinRate).int64Value
        let synchronizer = self.synchronizer

        return Single<()>.create { [weak self] single in
            synchronizer.sendToAddress(spendingKey: spendingKey, zatoshi: amount, toAddress: address, memo: memo, from: 0) { result in
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
        self.level = logLevel

        logger = Logger(minLogLevel: logLevel)
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    func event(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    private func log(level: HsToolKit.Logger.Level, message: String, file: String, function: String, line: Int) {
        logger.log(level: level, message: message, file: file, function: function, line: line)
    }

}
