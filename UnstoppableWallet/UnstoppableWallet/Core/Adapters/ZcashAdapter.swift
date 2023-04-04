import Foundation
import UIKit
import ZcashLightClientKit
import RxSwift
import HdWalletKit
import HsToolKit
import MarketKit
import HsExtensions
import Combine

class ZcashAdapter {
    private static let limitShowingDownloadBlockCount = 50
    private let serialScheduler = SerialDispatchQueueScheduler(qos: .utility)
    private let disposeBag = DisposeBag()
    private var initialPrepareDisposeBag = DisposeBag()
    private var cancellables: [AnyCancellable] = []

    private let token: Token
    private let transactionSource: TransactionSource

    private let saplingDownloader = DownloadService(queueLabel: "io.SaplingDownloader")

    private let rxSynchronizer: RxSDKSynchronizer
    private let closureSynchronizer: ClosureSynchronizer

    private var address: UnifiedAddress?
    private var saplingAddress: SaplingAddress? // This should be replaced by unified address.
    private var transactionPool: ZcashTransactionPool?

    private let uniqueId: String
    private let birthday: BlockHeight
    private let spendingKey: UnifiedSpendingKey // this being a single account does not need to be an array
    private let loggingProxy = ZcashLogger(logLevel: .debug)

    private(set) var network: ZcashNetwork
    private(set) var fee: Decimal

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceSubject = PublishSubject<BalanceData>()
    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private var waitForStart: Bool = false {
        didSet {
            if waitForStart && address != nil {     // already prepared and has address
                sync()
            }
        }
    }

    private var synchronizerState: SynchronizerState? {
        didSet {
            print("Did set syncState: \(synchronizerState)")

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
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        network = ZcashNetworkBuilder.network(for: .mainnet)
        fee = network.constants.defaultFee().decimalValue.decimalValue

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

        let initializer = Initializer(
                cacheDbURL: nil,
                fsBlockDbRoot: try ZcashAdapter.fsBlockDbRootURL(uniqueId: uniqueId, network: network),
                dataDbURL: try ZcashAdapter.dataDbURL(uniqueId: uniqueId, network: network),
                pendingDbURL: try ZcashAdapter.pendingDbURL(uniqueId: uniqueId, network: network),
                endpoint: LightWalletEndpoint(address: endPoint, port: 9067, secure: true, streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000),
                network: network,
                spendParamsURL: try ZcashAdapter.spendParamsURL(uniqueId: uniqueId),
                outputParamsURL: try ZcashAdapter.outputParamsURL(uniqueId: uniqueId),
                saplingParamsSourceURL: SaplingParamsSourceURL.default,
                alias: .default,
                logLevel: .error
        )

        spendingKey = unifiedSpendingKey

        let synchronizer = SDKSynchronizer(initializer: initializer)
        rxSynchronizer = RxSDKSynchronizer(synchronizer: synchronizer)
        closureSynchronizer = ClosureSDKSynchronizer(synchronizer: synchronizer)

        closureSynchronizer
                .stateStream
                .throttle(for: .seconds(0.3), scheduler: DispatchQueue.main, latest: true)
                .sink(receiveValue: { [weak self] state in self?.sync(state: state) })
                .store(in: &cancellables)

        rxSynchronizer
                .stateStreamObservable
                .observeOn(serialScheduler)
                .subscribe { [weak self] state in
                    self?.sync(state: state)
                }
                .disposed(by: disposeBag)

        rxSynchronizer
                .eventStreamObservable
                .observeOn(serialScheduler)
                .subscribe { [weak self] event in
                    self?.sync(event: event)
                }
                .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        subscribeDownloadService()


        initialPrepare(
                seedData: seedData,
                viewingKeys: [unifiedViewingKey],
                walletBirthday: birthday) { [weak self] result in
            switch result {
            case .success:
                self?.finishPrepare()
            case .failure(let error):
                self?.state = .notSynced(error: error)
            }
        }
    }

    private func initialPrepare(seedData: [UInt8]?, viewingKeys: [UnifiedFullViewingKey], walletBirthday: BlockHeight, completion: @escaping (Result<(), Error>) -> ()) {
        state = .preparing
        initialPrepareDisposeBag = DisposeBag()

        // preparing synchronizer and initialize addresses if possible
        rxSynchronizer.prepare(
                with: seedData,
                viewingKeys: viewingKeys,
                walletBirthday: birthday
        )
        .observeOn(serialScheduler)
        .flatMap { [weak self] result -> Single<()> in
            switch result {
            case .success:
                return self?.initAddress() ?? .error(AppError.ZcashError.noReceiveAddress)
            case .seedRequired:
                return .error(AppError.ZcashError.seedRequired)
            }
        }
        .subscribe(
            onSuccess: {
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            }
        ).disposed(by: initialPrepareDisposeBag)
    }

    private func initAddress() -> Single<()> {
        rxSynchronizer
                .getUnifiedAddress(accountIndex: 0)
                .flatMap { [weak self] address in
                    self?.address = address
                    return self?.initTransactionPool(
                            saplingAddress: address?.saplingReceiver()
                    ) ?? .error(AppError.ZcashError.noReceiveAddress)
                }
    }

    private func initTransactionPool(saplingAddress: SaplingAddress?) -> Single<()> {
        guard let saplingAddress else {
            return .error(AppError.ZcashError.noReceiveAddress)
        }

        let transactionPool = ZcashTransactionPool(receiveAddress: saplingAddress)
        self.transactionPool = transactionPool

        return Single.zip(
                rxSynchronizer.clearedTransactions(),
                rxSynchronizer.pendingTransactions()
        ).map { overviews, pending in
            transactionPool.store(confirmedTransactions: overviews, pendingTransactions: pending)
        }
    }

    private func finishPrepare() {
        let shielded = rxSynchronizer.getShieldedBalance().decimalValue.decimalValue
        let shieldedVerified = rxSynchronizer.getShieldedVerifiedBalance().decimalValue.decimalValue
        balanceSubject.onNext(BalanceData(
                balance: shieldedVerified,
                balanceLocked: shielded - shieldedVerified
        ))

        state = .idle
        if waitForStart {
            start()
        }
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

    private func sync(state: SynchronizerState) {
        print("\(Date()) ==> SYNCRONIZER update! \(Thread.current)")
        print("Old State: \(state)")

        synchronizerState = state

        var syncStatus = self.state

        switch state.syncStatus {
        case .disconnected:
            print("==> ==> Disconnected")
            syncStatus = .syncing(progress: nil, lastBlockDate: nil)
        case .stopped:
            print("==> ==> Stopped")
            syncStatus = .notSynced(error: AppError.unknownError)
        case .synced:
            print("==> ==> Synced")
            syncStatus = .synced
        case .syncing(let progress):
            print("==> ==> Syncing")
            print("==> ==> ==> \n\(progress)")
            print("Update BlockHeight = \(state.latestScannedHeight)")

            lastBlockUpdatedSubject.onNext(())

            syncStatus = .downloadingBlocks(number: progress.progressHeight, lastBlock: progress.targetHeight)

//            let diff = progress.progressHeight - lastDownloaded
//            if !state.syncStatus.isDownloading ||
//                       (diff > Self.limitShowingDownloadBlockCount) { // show first changing state, every 100 blocks and last 100 blocks
//            }
        case .enhancing(let p):
            print("==> ==> Enhancing")
            print("==> ==> ==> \n\(p)")
            syncStatus = .enhancingTransactions(number: p.enhancedTransactions, count: p.totalTransactions)
        case .unprepared:
            syncStatus = .notSynced(error: AppError.unknownError)
        case .fetching:
            print("==> ==> Fetching")
            syncStatus = .syncing(progress: 0, lastBlockDate: nil)
        case .error:
            syncStatus = .notSynced(error: AppError.unknownError)
        }

        if syncStatus != self.state {
            self.state = syncStatus
        }
    }

    private func sync(event: SynchronizerEvent) {
        switch event {
        case .foundTransactions(let transactions, let inRange):
            print("found \(transactions.count) txs in range: \(inRange)")
            let newTxs = transactionPool?.sync(transactions: transactions) ?? []
            transactionRecordsSubject.onNext(newTxs.map {
                transactionRecord(fromTransaction: $0)
            })
        case .minedTransaction(let pendingEntity):
            print("found pending tx")
            let newTxs = transactionPool?.sync(transactions: [pendingEntity]) ?? []
            transactionRecordsSubject.onNext(newTxs.map {
                transactionRecord(fromTransaction: $0)
            })
        default:
            print("Event: \(event)")
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
//        // check if we need to perform the fix or leave
//        guard !localStorage.zcashAlwaysPendingRewind else {
//            return
//        }
//
//        do {
//            // get all the pending transactions
//            let txs = synchronizer.pendingTransactions()
//
//            // fetch the first one that's reported to be unmined
//            guard let firstUnmined = txs.filter({ !$0.isMined }).first else {
//                localStorage.zcashAlwaysPendingRewind = true
//                return
//            }
//
//            try await synchronizer.rewind(.transaction(firstUnmined.makeTransactionEntity(defaultFee: defaultFee(network: network))))
//            localStorage.zcashAlwaysPendingRewind = true
//        } catch SynchronizerError.rewindErrorUnknownArchorHeight {
//            do {
//                try await synchronizer.rewind(.quick)
//                localStorage.zcashAlwaysPendingRewind = true
//            } catch {
//                loggingProxy.error("attempt to fix pending transactions failed with error: \(error)", file: #file, function: #function, line: 0)
//            }
//        } catch {
//            loggingProxy.error("attempt to fix pending transactions failed with error: \(error)", file: #file, function: #function, line: 0)
//        }
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
        closureSynchronizer.stop {
            print("Synchronizer Was Stopped")
        }
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
        self.network.networkType == .mainnet
    }

    func start() {
        if saplingDataExist() {
            if address == nil {     //while adapter is preparing synchronizer in background, we can't get address and start syncing
                waitForStart = true
            } else {
                sync(retry: true)
            }
        }
    }

    func stop() {
        closureSynchronizer.stop() {
            print("Synchronizer will stop")
        }
    }


    func refresh() {
        start()
    }

    private func sync(retry: Bool = false) {
        balanceSubject.onNext(_balanceData)
//        await fixPendingTransactionsIfNeeded()
            print("\(Date()) Try to start synchronizer : retry = \(retry), by Thread:\(Thread.current)")
        closureSynchronizer.start(retry: retry) { [weak self] error in
            if let error {
                self?.state = .notSynced(error: error)
            }
        }

//        state = .notSynced(error: error)
    }

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        let tAddress = self.address?.transparentReceiver()?.stringEncoded ?? "No Info"
        let zAddress = self.address?.saplingReceiver()?.stringEncoded ?? "No Info"
        var balanceState = "No Balance Information yet"

        if let status = self.synchronizerState {
            balanceState = """
                           shielded balance
                             total:  \(rxSynchronizer.getShieldedBalance().decimalValue.decimalValue)
                           verified:  \(rxSynchronizer.getShieldedVerifiedBalance().decimalValue.decimalValue)
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
        LastBlockInfo(height: state.lastProcessedBlockHeight ?? 0, timestamp: nil)
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

    var receiveAddress: String {
        // only first account
        saplingAddress?.stringEncoded ?? "n/a".localized
    }

}

extension ZcashAdapter: ISendZcashAdapter {
    enum AddressType {
        case shielded
        case transparent
    }

    var availableBalance: Decimal {
        max(0, rxSynchronizer.getShieldedVerifiedBalance().decimalValue.decimalValue - fee)
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
        let synchronizer = rxSynchronizer
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
//                    await self.syncPending()
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
