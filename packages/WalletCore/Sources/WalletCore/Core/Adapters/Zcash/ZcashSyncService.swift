import Combine
import Foundation
import HsToolKit
import RxSwift
import ZcashLightClientKit

class ZcashSyncService {
    private let synchronizer: Synchronizer
    private let initializer: Initializer
    private let network: ZcashNetwork
    private let seedData: [UInt8]
    private(set) var birthday: BlockHeight
    private let initMode: ZcashInitMode
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
    private var stallTask: Task<Void, Never>? // queue-confined; single-flight, cancelled on background
    private var stallRebuildsThisForeground = 0
    private var stallAutoSelectRequested = false
    private var lifecycleGeneration = 0 // bumped on background so a stale rebuild result is ignored
    private let stallSignalSubject = PassthroughSubject<Void, Never>()

    weak var endpointService: ZcashEndpointService?

    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    // Combine is primary; the Rx subject stays only to bridge the IBalanceAdapter contract
    // (AppManager's parallel-pair idiom).
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceStateUpdatedSubject = PassthroughSubject<AdapterState, Never>()
    private let depositAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    private var started = false
    private(set) var stallState: StallState = .none
    private var lastSyncProgress: Float = 0
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
            balanceStateUpdatedSubject.send(state.adapterState)
            balanceStateSubject.onNext(state.adapterState)
            syncing = state.adapterState.syncing
        }
    }

    init(
        synchronizer: Synchronizer,
        initializer: Initializer,
        network: ZcashNetwork,
        seedData: [UInt8],
        birthday: BlockHeight,
        initMode: ZcashInitMode,
        queue: DispatchQueue,
        balanceService: ZcashBalanceService,
        historyService: ZcashHistoryService,
        sendService: ZcashSendService,
        migrator: ZcashMigrator,
        logger: HsToolKit.Logger?
    ) {
        self.synchronizer = synchronizer
        self.initializer = initializer
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
            .sink(receiveValue: { [weak self] event in
                self?.historyService.sync(event: event)
                if case let .syncStalled(attempt, gaveUp) = event {
                    self?.handleStall(attempt: attempt, gaveUp: gaveUp)
                }
            })
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

    var stallSignalPublisher: AnyPublisher<Void, Never> {
        stallSignalSubject.eraseToAnyPublisher()
    }

    var balanceStateUpdatedPublisher: AnyPublisher<AdapterState, Never> {
        balanceStateUpdatedSubject.eraseToAnyPublisher()
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
        prepare(seedData: seedData, walletBirthday: birthday, initMode: initMode)
    }

    func stop() {
        synchronizer.stop()
        logger?.log(level: .debug, message: "Synchronizer will stop")
    }

    // Stops the engine and waits for the SDK to confirm, so a recreated adapter never opens the
    // wallet database while the previous engine handle is still winding down.
    func shutdown() async {
        let stopped = synchronizer.stateStream
            .map(\.syncStatus)
            .filter { status in
                switch status {
                case .stopped, .unprepared, .error: return true
                default: return false
                }
            }
            .first()
            .values

        stop()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { for await _ in stopped {
                break
            } }
            group.addTask { try? await Task.sleep(seconds: 10) }
            await group.next()
            group.cancelAll()
        }
    }

    func refresh() {
        cancelDeferredStop()
        queue.async { [weak self] in
            guard let self else { return }
            // pull-to-refresh after a terminal stall: the user asked, so the rebuild budget resets
            if stallState == .terminal {
                stallRebuildsThisForeground = 0
                stallState = .none
                startStallRebuild()
            } else {
                startSynchronizerOnQueue()
            }
        }
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

    private func prepare(seedData: [UInt8], walletBirthday: BlockHeight, initMode: ZcashInitMode) {
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

                    let sdkBirthday: BlockHeight? = initMode == .newWallet ? nil : walletBirthday
                    let result = try await synchronizer.prepare(with: seedData, walletBirthday: sdkBirthday, name: "", keySource: nil)
                    switch result {
                    case .seedRequired, .seedNotRelevant:
                        throw AppError.ZcashError.seedRequired
                    case .success:
                        break
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
                        self?.migrator.engine = ZcashMigrationEngine(synchronizer: synchronizer, accountUUID: account.id, spendingKey: unifiedSpendingKey, endpointService: self?.endpointService)

                        self?.depositAddressSubject.send(.completed(DepositAddress(uAddress.stringEncoded)))
                    }

                    self?.logger?.log(level: .debug, message: "Successful get address for 0 account! \(saplingAddress.stringEncoded)")

                    let transactionPool = ZcashTransactionPool(accountId: account.id, receiveAddress: saplingAddress, synchronizer: synchronizer)
                    await self?.historyService.initialize(transactionPool: transactionPool)

                    let height = try await synchronizer.latestHeight()

                    queue.async { [weak self] in
                        guard let self else { return }
                        // the SDK snaps a nil/new birthday to a checkpoint of its own choice
                        birthday = initializer.walletBirthday
                        lastBlockHeight = height
                        lastBlockUpdatedSubject.onNext(())
                        finishPrepare()
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
            prepare(seedData: seedData, walletBirthday: birthday, initMode: initMode)

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
        queue.async { [weak self] in
            guard let self else { return }
            stallTask?.cancel()
            stallTask = nil
            stallRebuildsThisForeground = 0
            stallAutoSelectRequested = false
            lifecycleGeneration += 1
            if stallState == .rebuilding {
                stallState = .none
            }
        }

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

        switch state.syncStatus {
        case .upToDate, .syncing:
            started = true
            lastBlockHeight = max(state.latestBlockHeight, lastBlockHeight)
            logger?.log(level: .debug, message: "State: \(state.syncStatus) | masked: \(state.isSpendableMasked) | height: \(lastBlockHeight)")
            lastBlockUpdatedSubject.onNext(())
            if case .upToDate = state.syncStatus {
                checkFailingTransactions()
            }
        case let .error(error):
            // a disconnect before the first sync keeps the engine "not started" (maps to .idle)
            if (error as? ZcashError) != .synchronizerDisconnected {
                started = true
            }
            logger?.log(level: .error, message: "State: Error: \(error)")
        case .unprepared, .stopped:
            logger?.log(level: .debug, message: "State: Disconnected")
        }

        // any real progress or a synced tip ends a stall episode
        switch state.syncStatus {
        case .upToDate:
            stallState = .none
        case let .syncing(progress, _) where progress > lastSyncProgress:
            stallState = .none
        default:
            break
        }
        if case let .syncing(progress, _) = state.syncStatus {
            lastSyncProgress = progress
        }

        let mapped = Self.mapState(Snapshot(state: state), started: started, birthday: birthday, lastBlockHeight: lastBlockHeight, stallTerminal: stallState == .terminal)
        let spendableChanged = mapped.effectiveSpendable != areFundsSpendable
        // assigned before the state publish so the send gate reads the new value with the new state
        areFundsSpendable = mapped.effectiveSpendable

        if mapped.state != self.state {
            self.state = mapped.state
        } else if spendableChanged {
            // a pure spendable flip republishes the same state so the send gate re-evaluates
            balanceStateUpdatedSubject.send(self.state.adapterState)
            balanceStateSubject.onNext(self.state.adapterState)
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
                          self?.rewindQuick(completion: completion)
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

extension ZcashSyncService {
    enum StallAction: Equatable {
        case none
        case requestAutoSelect
        case rebuild
        case terminal
    }

    static let maxStallRebuildsPerForeground = 2

    // attempt >= 2 (the SDK already restarted once) asks node auto-select for a healthier server;
    // gaveUp rebuilds the engine ourselves within a per-foreground budget, then goes terminal.
    static func stallAction(attempt: Int, gaveUp: Bool, isActive: Bool, autoSelectEnabled: Bool, rebuildsThisForeground: Int, alreadyRequestedAutoSelect: Bool) -> StallAction {
        guard isActive else { return .none }
        if gaveUp {
            return rebuildsThisForeground < maxStallRebuildsPerForeground ? .rebuild : .terminal
        }
        guard attempt >= 2, autoSelectEnabled, !alreadyRequestedAutoSelect else { return .none }
        return .requestAutoSelect
    }

    private func handleStall(attempt: Int, gaveUp: Bool) {
        let action = Self.stallAction(
            attempt: attempt,
            gaveUp: gaveUp,
            isActive: Core.shared.appManager.isActive,
            autoSelectEnabled: Core.shared.zcashNodeManager.autoSelectEnabled,
            rebuildsThisForeground: stallRebuildsThisForeground,
            alreadyRequestedAutoSelect: stallAutoSelectRequested
        )
        logger?.log(level: .error, message: "Sync stalled: attempt=\(attempt) gaveUp=\(gaveUp) -> \(action)")

        switch action {
        case .none:
            break
        case .requestAutoSelect:
            stallAutoSelectRequested = true
            stallSignalSubject.send()
        case .rebuild:
            stallRebuildsThisForeground += 1
            startStallRebuild()
        case .terminal:
            setStallTerminal()
        }
    }

    private func setStallTerminal() {
        stallState = .terminal
        state = .notSynced(error: AppError.zcash(reason: .syncStalled))
    }

    private func startStallRebuild() {
        guard stallTask == nil, let endpointService else { return }
        stallState = .rebuilding
        let generation = lifecycleGeneration
        let queue = queue

        stallTask = Task { [weak self] in
            defer { queue.async { [weak self] in self?.stallTask = nil } }
            do {
                try await endpointService.rebuild(at: endpointService.currentEndpoint)
            } catch is CancellationError {
                return
            } catch {
                queue.async { [weak self] in
                    guard let self, lifecycleGeneration == generation else { return }
                    setStallTerminal()
                }
                return
            }
            queue.async { [weak self] in
                guard let self, lifecycleGeneration == generation else { return }
                stallState = .none
                // let auto-select look for a healthier node after the rebuild
                stallSignalSubject.send()
            }
        }
    }
}

extension ZcashSyncService {
    enum StallState {
        case none
        case rebuilding
        case terminal
    }

    struct Snapshot: Equatable {
        let syncStatus: SyncStatus
        let isSpendableMasked: Bool
        let isRecovering: Bool
        let latestHeight: Int

        init(syncStatus: SyncStatus, isSpendableMasked: Bool, isRecovering: Bool, latestHeight: Int) {
            self.syncStatus = syncStatus
            self.isSpendableMasked = isSpendableMasked
            self.isRecovering = isRecovering
            self.latestHeight = latestHeight
        }

        init(state: SynchronizerState) {
            self.init(syncStatus: state.syncStatus, isSpendableMasked: state.isSpendableMasked, isRecovering: state.isRecovering, latestHeight: state.latestBlockHeight)
        }
    }

    struct Mapped: Equatable {
        let state: ZCashAdapterState
        let effectiveSpendable: Bool
    }

    // Pure mapping of one SDK snapshot; the caller applies side effects (heights, started flag).
    static func mapState(_ snapshot: Snapshot, started: Bool, birthday: Int, lastBlockHeight: Int, stallTerminal: Bool) -> Mapped {
        var state: ZCashAdapterState
        var spendable = false

        switch snapshot.syncStatus {
        case .unprepared:
            state = started ? .syncing(progress: nil, remaining: nil, lastBlockDate: nil) : .idle
        case .stopped:
            state = .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .upToDate:
            state = .synced
            spendable = true
        case let .syncing(progress, areFundsSpendable):
            spendable = areFundsSpendable
            // Progress 0 (nothing scanned yet — the real scan range is unknown, and for a
            // new wallet the SDK starts near the tip, not at the nominal birthday) and
            // progress 1 (pre-scan housekeeping) carry no usable numbers: show an
            // indeterminate spinner instead of a count extrapolated from the birthday.
            if progress == 0 || progress == 1 {
                state = .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            } else {
                let newProgress = min(99, Int(progress * 100))
                let newRemaining = max(1, Int(Float(lastBlockHeight - birthday) * (1 - progress)))
                state = .syncing(progress: newProgress, remaining: newRemaining, lastBlockDate: nil)
            }
        case let .error(error):
            if !started, case .synchronizerDisconnected = error as? ZcashError {
                state = .idle
            } else {
                state = .notSynced(error: AppError.unknownError)
            }
        }

        // terminal stall outranks repeated syncing/error snapshots
        switch snapshot.syncStatus {
        case .syncing, .error:
            if stallTerminal {
                state = .notSynced(error: AppError.zcash(reason: .syncStalled))
            }
        default:
            break
        }

        // The SDK is not willing to state a spendable value: under the stale-tip mask, and during
        // recovery (recent-first restore), where the balance is provisional and the "spendable"
        // field carries the whole reconciled total. Progress numbers stay; only a synced tip turns
        // into "syncing without numbers" so the UI never says synced while the send gate is shut.
        if snapshot.isSpendableMasked || snapshot.isRecovering {
            spendable = false
            if case .synced = state {
                state = .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            }
        }

        return Mapped(state: state, effectiveSpendable: spendable)
    }
}
