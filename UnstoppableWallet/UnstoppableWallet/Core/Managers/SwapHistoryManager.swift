import Combine
import Foundation

class SwapHistoryManager {
    private let accountManager: AccountManager
    private let storage: SwapStorage
    private var cancellables = Set<AnyCancellable>()

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

        for swap in pendingSwaps {
            guard let provider = SwapProviderFactory.provider(id: swap.providerId) else {
                continue
            }

            do {
                let swap = try await provider.track(swap: swap)
                try storage.save(swap: swap)

                swapUpdateSubject.send(swap)
            } catch {
                print(error)
            }
        }
    }
}

extension SwapHistoryManager {
    var swapUpdatePublisher: AnyPublisher<Swap, Never> {
        swapUpdateSubject.eraseToAnyPublisher()
    }

    func sync() {
        Task { [weak self] in
            do {
                try await self?._sync()
            } catch {
                print(error)
            }
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
        try? storage.save(swap: swap)
    }
}
