import Combine
import Foundation

class SwapHistoryManager {
    private let accountManager: AccountManager
    private let storage: SwapStorage
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: AnyCancellable?
    private var isSyncing = false

    private let swapUpdateSubject = PassthroughSubject<Swap, Never>()

    init(accountManager: AccountManager, storage: SwapStorage) {
        self.accountManager = accountManager
        self.storage = storage

        sync()
    }

    private func _sync() async throws {
        guard let account = accountManager.activeAccount else {
            return
        }

        let pendingSwaps = try storage.pendingSwaps(accountId: account.id)

        guard !pendingSwaps.isEmpty else {
            return
        }

        var hasStillPendingSwaps = false

        for swap in pendingSwaps {
            guard let provider = SwapProviderFactory.provider(id: swap.providerId) else {
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

        if hasStillPendingSwaps {
            scheduleTimer()
        }
    }

    private func scheduleTimer() {
        syncTimer?.cancel()
        syncTimer = Just(())
            .delay(for: .seconds(30), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.sync()
            }
    }
}

extension SwapHistoryManager {
    var swapUpdatePublisher: AnyPublisher<Swap, Never> {
        swapUpdateSubject.eraseToAnyPublisher()
    }

    func sync() {
        guard !isSyncing else {
            return
        }

        syncTimer?.cancel()
        syncTimer = nil
        isSyncing = true

        Task { [weak self] in
            do {
                try await self?._sync()
            } catch {
                print(error)
            }

            self?.isSyncing = false
        }
    }

    func swaps(accountId: String, from: Date? = nil, limit: Int) -> [Swap] {
        do {
            return try storage.swaps(accountId: accountId, from: from, limit: limit)
        } catch {
            return []
        }
    }

    func save(swap: Swap) {
        do {
            try storage.save(swap: swap)
            sync()
        } catch {
            print(error)
        }
    }
}
