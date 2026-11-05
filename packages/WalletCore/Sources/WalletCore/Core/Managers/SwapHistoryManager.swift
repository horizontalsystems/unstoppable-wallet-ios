import Combine
import Foundation
import MarketKit

public class SwapHistoryManager {
    private let accountManager: AccountManager
    private let storage: SwapStorage
    private var cancellables = Set<AnyCancellable>()

    // sync state, only touched on the main queue
    private var syncTimer: AnyCancellable?
    private var isSyncing = false
    private var syncRequested = false

    private let swapUpdateSubject = PassthroughSubject<Swap, Never>()

    /// No work in init: the first sync is kicked by AppManager.didFinishLaunching, once the app
    /// (registries, adapters, host-app context) is assembled.
    init(accountManager: AccountManager, storage: SwapStorage) {
        self.accountManager = accountManager
        self.storage = storage

        // only the active account's pending swaps are polled, so a newly active account needs its own sync
        accountManager.activeAccountPublisher
            .map { $0?.id }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)
    }

    /// Returns whether any swap is still pending and needs another sync
    private func _sync() async throws -> Bool {
        guard let account = accountManager.activeAccount else {
            return false
        }

        let pendingSwaps = try storage.pendingSwaps(accountId: account.id)

        guard !pendingSwaps.isEmpty else {
            return false
        }

        var hasStillPendingSwaps = false

        for swap in pendingSwaps {
            // mechanism-pending: there is no on-chain hash to track by yet; resolve() will supply it.
            // Swaps without a trackingHandle keep today's behaviour even with a nil txHash
            // (deposit-based providers track by providerSwapId alone)
            if Self.isAwaitingTxHash(swap) {
                hasStillPendingSwaps = true
                continue
            }

            guard let provider = SwapProviderFactory.provider(trackingProviderId: swap.providerId) else {
                continue
            }

            do {
                let updatedSwap = try await provider.track(swap: swap)
                try storage.save(swap: updatedSwap)
                swapUpdateSubject.send(updatedSwap)

                if updatedSwap.isPending {
                    hasStillPendingSwaps = true
                }
            } catch {
                print(error)
                hasStillPendingSwaps = true
            }
        }

        return hasStillPendingSwaps
    }

    private func startSync() {
        guard !isSyncing else {
            // the running sync may be for a previous account or miss a just-saved swap, so it is re-run once it ends
            syncRequested = true
            return
        }

        syncTimer?.cancel()
        syncTimer = nil
        isSyncing = true

        Task { [weak self] in
            var hasPendingSwaps = false

            do {
                hasPendingSwaps = try await self?._sync() ?? false
            } catch {
                print(error)
            }

            DispatchQueue.main.async {
                self?.handleSyncFinished(hasPendingSwaps: hasPendingSwaps)
            }
        }
    }

    private func handleSyncFinished(hasPendingSwaps: Bool) {
        isSyncing = false

        if syncRequested {
            syncRequested = false
            startSync()
        } else if hasPendingSwaps {
            scheduleTimer()
        }
    }

    private func scheduleTimer() {
        syncTimer?.cancel()
        syncTimer = Just(())
            .delay(for: .seconds(15), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.sync()
            }
    }
}

public extension SwapHistoryManager {
    var swapUpdatePublisher: AnyPublisher<Swap, Never> {
        swapUpdateSubject.eraseToAnyPublisher()
    }

    func pendingSwaps(account: Account) -> [Swap] {
        do {
            return try storage.pendingSwaps(accountId: account.id)
        } catch {
            return []
        }
    }

    func sync() {
        DispatchQueue.main.async { [weak self] in
            self?.startSync()
        }
    }

    internal func lastSwap(accountId: String) -> Swap? {
        try? storage.lastSwap(accountId: accountId)
    }

    func swaps(
        accountId: String,
        token: Token? = nil,
        blockchainType: BlockchainType? = nil,
        addresses: [String]? = nil,
        from: Date? = nil,
        operation: Swap.Operation? = nil,
        operations: [Swap.Operation]? = nil,
        limit: Int
    ) -> [Swap] {
        do {
            return try storage.swaps(
                accountId: accountId,
                token: token,
                blockchainType: blockchainType,
                addresses: addresses,
                from: from,
                operation: operation,
                operations: operations,
                limit: limit
            )
        } catch {
            return []
        }
    }

    func save(swap: Swap) {
        do {
            try storage.save(swap: swap)
            swapUpdateSubject.send(swap)
            sync()
        } catch {
            print(error)
        }
    }

    /// mechanism-agnostic hook: attaches the on-chain txHash to the swap saved with
    /// this trackingHandle and starts tracking it
    func resolve(trackingHandle: String, txHash: String) {
        do {
            guard try storage.setTxHash(txHash, trackingHandle: trackingHandle) else {
                return
            }

            sync()
        } catch {
            print(error)
        }
    }

    /// mechanism-agnostic hook: the broadcast succeeded but the mechanism can never yield a ref
    /// (e.g. TonKit's send returns Void). Clearing the handle releases the record from
    /// isAwaitingTxHash() so the provider tracks it by providerSwapId alone — without this the
    /// swap would sit "awaiting tx hash" forever.
    func beginProviderTracking(trackingHandle: String) {
        do {
            guard try storage.clearTrackingHandle(trackingHandle) else {
                return
            }

            sync()
        } catch {
            print(error)
        }
    }

    /// mechanism-agnostic hook: a retried broadcast reuses the row it failed on. Scoped to the
    /// failed status — never resurrects a settled swap; false = nothing to retry.
    func retryFailed(trackingHandle: String) -> Bool {
        do {
            guard try storage.markNotStarted(trackingHandle: trackingHandle) else {
                return false
            }

            if let swap = try storage.swap(trackingHandle: trackingHandle) {
                swapUpdateSubject.send(swap)
            }

            return true
        } catch {
            return false
        }
    }

    /// mechanism-agnostic hook: the mechanism itself learned the swap failed (e.g. a reverted /
    /// never-mined userOp) — no server tracking involved. Targeted update scoped to pending
    /// statuses; a settled swap is never downgraded, a re-delivery is a no-op.
    func markFailed(trackingHandle: String) {
        do {
            guard try storage.markFailed(trackingHandle: trackingHandle) else {
                return
            }

            if let swap = try storage.swap(trackingHandle: trackingHandle) {
                swapUpdateSubject.send(swap)
            }
        } catch {
            print(error)
        }
    }

    internal static func isAwaitingTxHash(_ swap: Swap) -> Bool {
        swap.trackingHandle != nil && swap.txHash == nil
    }
}
