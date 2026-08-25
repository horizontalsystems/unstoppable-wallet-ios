import Combine
import Foundation
import HsToolKit
import RxSwift
import ZcashLightClientKit

class ZcashSyncService {
    private let synchronizer: Synchronizer
    private let network: ZcashNetwork
    private let seedData: [UInt8]
    private let birthday: BlockHeight
    private let initMode: WalletInitMode
    private let queue: DispatchQueue
    private let logger: HsToolKit.Logger?

    private let balanceService: ZcashBalanceService
    private let historyService: ZcashHistoryService
    private let sendService: ZcashSendService
    private let migrator: ZcashMigrator

    private var cancellables: [AnyCancellable] = []
    private var deferredStopCancellable: AnyCancellable?
    private var resubmitTask: Task<Void, Never>? // main-confined; dedupes concurrent startSynchronizer kicks
    private var resubmitWhenHeightIsAvailable = false // queue-confined with `sync(state:)`

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let depositAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    private var started = false
    private(set) var lastBlockHeight: Int = 0 {
        didSet {
            historyService.lastBlockHeight = lastBlockHeight
        }
    }

    private(set) var areFundsSpendable: Bool = false
    private(set) var syncing: Bool = true

    private(set) var accountId: AccountUUID?
    private(set) var uAddress: UnifiedAddress?
    private(set) var tAddress: TransparentAddress?
    private(set) var viewingKey: UnifiedFullViewingKey? // this being a single account does not need to be an array
    private(set) var spendingKey: UnifiedSpendingKey?

    private(set) var synchronizerState: SynchronizerState? {
        didSet {
            lastBlockUpdatedSubject.onNext(())
            balanceService.sync(synchronizerState: synchronizerState, accountId: accountId, lastBlockHeight: lastBlockHeight)
        }
    }

    private(set) var state: ZCashAdapterState = .idle {
        didSet {
            balanceStateSubject.onNext(state.adapterState)
            syncing = state.adapterState.syncing
        }
    }

    init(
        synchronizer: Synchronizer,
        network: ZcashNetwork,
        seedData: [UInt8],
        birthday: BlockHeight,
        initMode: WalletInitMode,
        queue: DispatchQueue,
        balanceService: ZcashBalanceService,
        historyService: ZcashHistoryService,
        sendService: ZcashSendService,
        migrator: ZcashMigrator,
        logger: HsToolKit.Logger?
    ) {
        self.synchronizer = synchronizer
        self.network = network
        self.seedData = seedData
        self.birthday = birthday
        self.initMode = initMode
        self.queue = queue
        self.balanceService = balanceService
        self.historyService = historyService
        self.sendService = sendService
        self.migrator = migrator
        self.logger = logger

        // subscribe on sync states
        synchronizer
            .stateStream
            .throttle(for: .seconds(0.3), scheduler: queue, latest: true)
            .sink(receiveValue: { [weak self] state in self?.sync(state: state) })
            .store(in: &cancellables)

        // subscribe on new transactions
        synchronizer
            .eventStream
            .receive(on: queue)
            .sink(receiveValue: { [weak self] event in self?.historyService.sync(event: event) })
            .store(in: &cancellables)

        Core.shared.appManager.didEnterBackgroundPublisher
            .sink { [weak self] in self?.didEnterBackground() }
            .store(in: &cancellables)
    }

    deinit {
        // capture the synchronizer strongly: a weak-self task in deinit never runs the stop
        let synchronizer = synchronizer
        let logger = logger
        Task {
            synchronizer.stop()
            logger?.log(level: .debug, message: "Synchronizer Was Stopped")
        }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        lastBlockUpdatedSubject.asObservable()
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        depositAddressSubject.eraseToAnyPublisher()
    }

    var isPreparing: Bool {
        state.isPrepairing
    }

    func start() {
        cancelDeferredStop()
        warmUpSaplingParams()
        prepare(seedData: seedData, walletBirthday: birthday, for: initMode)
    }

    func stop() {
        synchronizer.stop()
        logger?.log(level: .debug, message: "Synchronizer will stop")
    }

    func refresh() {
        cancelDeferredStop()
        startSynchronizer()
    }

    // Pre-warm sapling params unconditionally: the SDK sync-time download is gated by
    // sapling/transparent balances only, so a wallet with orchard-only funds would pay
    // the ~50 MB download synchronously inside its first send. Idempotent: validates and
    // returns when the files are already on disk.
    private func warmUpSaplingParams() {
        Task { [logger] in
            do {
                try await SaplingParameterDownloader.downloadParamsIfnotPresent(
                    retryEnabled: true,
                    spendURL: ZcashFileStore.spendParamsURL(),
                    spendSourceURL: SaplingParamsSourceURL.default.spendParamFileURL,
                    outputURL: ZcashFileStore.outputParamsURL(),
                    outputSourceURL: SaplingParamsSourceURL.default.outputParamFileURL,
                    logger: OSLogger(logLevel: .error)
                )
            } catch {
                // send path re-downloads just-in-time, so failure here only loses the pre-warm
                logger?.log(level: .error, message: "Sapling params pre-warm failed: \(error)")
            }
        }
    }

    private func prepare(seedData: [UInt8], walletBirthday: BlockHeight, for initMode: WalletInitMode) {
        queue.async { [weak self] in
            guard let self else { return }

            guard !state.isPrepairing else {
                return
            }
            state = .preparing

            depositAddressSubject.send(.loading)
            let networkType = network.networkType
            let queue = queue
            Task { [weak self, synchronizer] in
                do {
                    let tool = DerivationTool(networkType: networkType)
                    guard let unifiedSpendingKey = try? tool.deriveUnifiedSpendingKey(seed: seedData, accountIndex: .zero),
                          let unifiedViewingKey = try? tool.deriveUnifiedFullViewingKey(from: unifiedSpendingKey)
                    else {
                        throw AppError.ZcashError.cantCreateKeys
                    }

                    queue.async { [weak self] in
                        self?.spendingKey = unifiedSpendingKey
                        self?.viewingKey = unifiedViewingKey
                    }

                    let result = try await synchronizer.prepare(with: seedData, walletBirthday: walletBirthday, for: initMode, name: "", keySource: nil)
                    if case .seedRequired = result {
                        throw AppError.ZcashError.seedRequired
                    }

                    guard let account = try await synchronizer.listAccounts().first else {
                        throw AppError.ZcashError.noReceiveAddress
                    }

                    self?.logger?.log(level: .debug, message: "Successful prepared!")
                    guard let uAddress = try? await synchronizer.getUnifiedAddress(accountUUID: account.id),
                          let tAddress = try? await synchronizer.getTransparentAddress(accountUUID: account.id),
                          let saplingAddress = try? uAddress.saplingReceiver()
                    else {
                        throw AppError.ZcashError.noReceiveAddress
                    }

                    queue.async { [weak self] in
                        self?.accountId = account.id
                        self?.uAddress = uAddress
                        self?.tAddress = tAddress
                        self?.migrator.engine = ZcashMigrationEngine(synchronizer: synchronizer, accountUUID: account.id, spendingKey: unifiedSpendingKey)

                        self?.depositAddressSubject.send(.completed(DepositAddress(uAddress.stringEncoded)))
                    }

                    self?.logger?.log(level: .debug, message: "Successful get address for 0 account! \(saplingAddress.stringEncoded)")

                    let transactionPool = ZcashTransactionPool(accountId: account.id, receiveAddress: saplingAddress, synchronizer: synchronizer)
                    await self?.historyService.initialize(transactionPool: transactionPool)

                    let height = try await synchronizer.latestHeight()

                    queue.async { [weak self] in
                        self?.lastBlockHeight = height
                        self?.lastBlockUpdatedSubject.onNext(())
                        self?.finishPrepare()
                    }
                } catch {
                    queue.async { [weak self] in
                        self?.setPreparing(error: error)
                    }
                }
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

    func startSynchronizer() {
        queue.async { [weak self] in
            self?.startSynchronizerOnQueue()
        }
    }

    private func startSynchronizerOnQueue() {
        guard !state.isPrepairing else { // postpone start library until preparing will finish
            logger?.log(level: .debug, message: "Can't start because preparing!")
            return
        }

        // `.unprepared` with an address means a wipe failed after tearing the synchronizer
        // down: start() would only throw notPrepared, so re-prepare instead — this makes
        // pull-to-refresh and foregrounding recover the wallet without an app restart.
        if uAddress == nil || synchronizer.latestState.syncStatus == .unprepared {
            logger?.log(level: .debug, message: "Not prepared, try to prepare kit again!")
            prepare(seedData: seedData, walletBirthday: birthday, for: initMode)

            return
        }

        // Sapling parameters are downloaded by the SDK on demand
        // (conditionally during sync when balance > 0, and just-in-time before any spend).
        logger?.log(level: .debug, message: "Start syncing kit!")
        syncMain()

        resubmitWhenHeightIsAvailable = true
    }

    private func schedulePendingResubmission() {
        DispatchQueue.main.async { [weak self] in
            guard let self, resubmitTask == nil else { return }

            resubmitTask = Task { [weak self] in
                await self?.sendService.resubmitPendingTransactions()
                DispatchQueue.main.async { [weak self] in self?.resubmitTask = nil }
            }
        }
    }

    private func didEnterBackground() {
        let backgroundTaskManager = Core.shared.backgroundTaskManager

        // subscribe BEFORE checking activity: a critical section completing in between still triggers stop()
        deferredStopCancellable = backgroundTaskManager.criticalCompletedPublisher
            .first()
            .sink { [weak self] in
                self?.stop()
            }

        guard backgroundTaskManager.isCriticalActive else {
            deferredStopCancellable = nil
            stop()
            return
        }
        // send in flight: let the critical window finish the broadcast, the sink above stops after it
    }

    // foreground resume goes through refresh() (start() only on creation) — deferred stop must not kill a live sync.
    // deferredStopCancellable is main-confined: start()/refresh() arrive on background queues, subscription and fire are on main
    private func cancelDeferredStop() {
        DispatchQueue.main.async { [weak self] in
            self?.deferredStopCancellable = nil
        }
    }

    private func syncMain() {
        queue.async { [weak self] in
            self?.sync()
        }
    }

    private func sync() {
        balanceService.sync(synchronizerState: synchronizerState, accountId: accountId, lastBlockHeight: lastBlockHeight)

        fixPendingTransactionsIfNeeded { [weak self] in
            self?.logger?.log(level: .debug, message: "\(Date()) Try to start synchronizer :by Thread:\(Thread.current)")
            Task { [weak self] in
                do {
                    try await self?.synchronizer.start(retry: true)
                } catch {
                    self?.queue.async { [weak self] in
                        self?.state = .notSynced(error: error)
                    }
                }
            }
        }
    }

    private func sync(state: SynchronizerState) {
        synchronizerState = state

        if resubmitWhenHeightIsAvailable, state.latestBlockHeight > 0 {
            resubmitWhenHeightIsAvailable = false
            schedulePendingResubmission()
        }

        var syncStatus = self.state

        switch state.syncStatus {
        case .unprepared:
            if started {
                logger?.log(level: .debug, message: "State: Disconnected")
                syncStatus = .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            } else {
                syncStatus = .idle
            }
        case .stopped:
            logger?.log(level: .debug, message: "State: Disconnected")
            syncStatus = .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .upToDate:
            if !started {
                started = true
            }
            logger?.log(level: .debug, message: "State: Synced")
            syncStatus = .synced
            lastBlockHeight = max(state.latestBlockHeight, lastBlockHeight)
            logger?.log(level: .debug, message: "Update BlockHeight = \(lastBlockHeight)")
            checkFailingTransactions()
        case let .syncing(progress, areFundsSpendable):
            if !started {
                started = true
            }
            logger?.log(level: .debug, message: "State: Syncing")
            logger?.log(level: .debug, message: "State progress: \(progress) | spendable: \(areFundsSpendable)")
            lastBlockHeight = max(state.latestBlockHeight, lastBlockHeight)
            self.areFundsSpendable = areFundsSpendable

            logger?.log(level: .debug, message: "Update BlockHeight = \(lastBlockHeight)")

            lastBlockUpdatedSubject.onNext(())

            // Progress 0 (nothing scanned yet — the real scan range is unknown, and for a
            // new wallet the SDK starts near the tip, not at the nominal birthday) and
            // progress 1 (pre-scan housekeeping) carry no usable numbers: show an
            // indeterminate spinner instead of a count extrapolated from the birthday.
            if progress == 0 || progress == 1 {
                syncStatus = .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            } else {
                let newProgress = min(99, Int(progress * 100))
                let newRemaining = max(1, Int(Float(lastBlockHeight - birthday) * (1 - progress)))

                syncStatus = .syncing(progress: newProgress, remaining: newRemaining, lastBlockDate: nil)
            }
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

    private func checkFailingTransactions() {
        historyService.reSyncPending()
    }

    private func fixPendingTransactionsIfNeeded(completion: (() -> Void)? = nil) {
        // check if we need to perform the fix or leave
        // get all the pending transactions
        guard !Core.shared.localStorage.zcashAlwaysPendingRewind else {
            completion?()
            return
        }

        Task {
            let txs = await synchronizer.transactions.filter { overview in overview.minedHeight == nil }
            // fetch the first one that's reported to be unmined
            guard let firstUnmined = txs.filter({ $0.minedHeight == nil }).first else {
                Core.shared.localStorage.zcashAlwaysPendingRewind = true
                completion?()
                return
            }

            queue.async { [weak self] in
                self?.rewind(unmined: firstUnmined, completion: completion)
            }
        }
    }

    private func rewind(unmined: ZcashTransaction.Overview, completion: (() -> Void)? = nil) {
        synchronizer
            .rewind(.transaction(unmined))
            .receive(on: queue)
            .sink(receiveCompletion: { [weak self] result in
                      switch result {
                      case .finished:
                          Core.shared.localStorage.zcashAlwaysPendingRewind = true
                          completion?()
                      case .failure:
                          self?.rewindQuick()
                      }
                  },
                  receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func rewindQuick(completion: (() -> Void)? = nil) {
        synchronizer
            .rewind(.quick)
            .receive(on: queue)
            .sink(receiveCompletion: { [weak self] result in
                      switch result {
                      case .finished:
                          Core.shared.localStorage.zcashAlwaysPendingRewind = true
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

    // The SDK's wipe is self-serializing: called mid-sync it registers an after-sync hook,
    // stops the processor and wipes once the loop has fully wound down; called idle it wipes
    // immediately. Stopping manually and waiting for a `.stopped` emission here used to hang
    // forever on an idle synchronizer (the event is only produced by cancelling a running
    // sync loop) and raced the SDK's own teardown when sync was active.
    func wipe() -> AnyPublisher<Void, Error> {
        let logger = logger
        let migrator = migrator

        return synchronizer.wipe()
            .handleEvents(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // Cleared only on success: a failed wipe leaves the wallet data in
                    // place, and the migration markers must stay consistent with it.
                    migrator.clearOnWipe()
                    logger?.log(level: .debug, message: "[ZcashAdapter] wipe: completed successfully")
                case let .failure(error):
                    logger?.log(level: .error, message: "[ZcashAdapter] wipe: completed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
