import Combine
import Foundation
import MarketKit

// Single source of truth for "can this token be sent privately". Deliberately separate from the
// regular swap asset lists: a token being swappable says nothing about it being privately sendable.
// Each confidential provider gets its own USwapAssetRepository, so its token list is persisted under
// its own provider key in SwapAssetStorage with no schema change.
public final class PrivateSendTokenManager {
    private let registry: ConfidentialProviderRegistry
    private let makeRepository: (String) -> USwapAssetRepository
    private let syncSubject = PassthroughSubject<Void, Never>()
    private let stateLock = NSLock()
    private var repositories = [String: USwapAssetRepository]()
    private var cancellables = Set<AnyCancellable>()
    private var repositoryCancellables = [String: AnyCancellable]()

    // The repository factory is injected so an app that already memoises repositories elsewhere
    // (the private send service uses the same ones) shares instances rather than duplicating the
    // per-provider GET /v2/tokens traffic.
    public init(registry: ConfidentialProviderRegistry, repository: @escaping (String) -> USwapAssetRepository) {
        self.registry = registry
        makeRepository = repository

        // A newly-confidential provider starts contributing tokens without an app restart, and a
        // de-listed one stops.
        registry.syncPublisher
            .sink { [weak self] in self?.handleRegistrySync() }
            .store(in: &cancellables)

        syncRepositories()
    }

    public var syncPublisher: AnyPublisher<Void, Never> {
        syncSubject.eraseToAnyPublisher()
    }

    // Pure in-memory lookup over already-synced state. Called from the render path: it must never
    // trigger a fetch, block, or become async.
    public func supports(token: Token) -> Bool {
        !supportedProviderIds(token: token).isEmpty
    }

    public func asset(token: Token, providerId: String) -> String? {
        repository(providerId: providerId)?.asset(token: token)
    }

    public func supportedProviderIds(token: Token) -> [String] {
        registry.providerIds.filter { providerId in
            repository(providerId: providerId)?.asset(token: token) != nil
        }
    }

    public func sync() {
        registry.sync()
        syncRepositories()

        for repository in withLock({ Array(repositories.values) }) {
            repository.sync()
        }
    }
}

private extension PrivateSendTokenManager {
    func withLock<T>(_ action: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action()
    }

    func repository(providerId: String) -> USwapAssetRepository? {
        withLock { repositories[providerId] }
    }

    func handleRegistrySync() {
        syncRepositories()
        syncSubject.send()
    }

    // Re-derives the repository set from the registry, creating missing ones lazily and dropping
    // repositories for providers that are no longer confidential.
    func syncRepositories() {
        let providerIds = registry.providerIds

        // Snapshot what is missing, then build outside every lock. makeRepository is
        // USwapAssetRepositoryCache.repository(providerId:) in both apps: it takes a second lock and,
        // on a miss, constructs a USwapAssetRepository whose init reads GRDB synchronously and spawns
        // a sync Task. Holding stateLock across that would serialise disk I/O behind the very lock
        // supports(token:) reads from the SwiftUI render path.
        let missing = withLock { providerIds.filter { repositories[$0] == nil } }
        let built = missing.map { (providerId: $0, repository: makeRepository($0)) }

        var created = [(providerId: String, repository: USwapAssetRepository)]()

        withLock {
            for entry in built {
                // A concurrent caller may have inserted while we were building. The cache hands both
                // callers the same instance, but only one of us may own the subscription.
                guard repositories[entry.providerId] == nil else { continue }

                repositories[entry.providerId] = entry.repository
                created.append(entry)
            }

            for providerId in Array(repositories.keys) where !providerIds.contains(providerId) {
                repositories[providerId] = nil
                repositoryCancellables[providerId] = nil
            }
        }

        // A first token-list sync landing while the pre-send screen is open must reveal the toggle
        // without a reload.
        for entry in created {
            let cancellable = entry.repository.syncPublisher
                .sink { [weak self] in self?.syncSubject.send() }

            withLock { repositoryCancellables[entry.providerId] = cancellable }
        }
    }
}
