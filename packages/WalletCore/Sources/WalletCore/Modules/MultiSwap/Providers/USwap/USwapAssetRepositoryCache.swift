import Foundation

// One USwapAssetRepository per provider id, memoised.
//
// Required, not an optimisation: USwapAssetRepository.init calls sync(), so building a fresh
// instance per lookup would refetch GET /v2/tokens continuously. Both apps wire the private send
// stack through `repository(providerId:)`, so the token manager and the service share instances
// rather than duplicating the per-provider traffic.
public final class USwapAssetRepositoryCache {
    private let makeRepository: (String) -> USwapAssetRepository
    private let lock = NSLock()
    private var repositories = [String: USwapAssetRepository]()

    public init(makeRepository: @escaping (String) -> USwapAssetRepository) {
        self.makeRepository = makeRepository
    }

    public convenience init(api: USwapMultiSwapApi, storage: SwapAssetStorage) {
        self.init(makeRepository: { providerId in
            USwapAssetRepository(providerId: providerId, api: api, storage: storage)
        })
    }

    public func repository(providerId: String) -> USwapAssetRepository {
        lock.lock()
        defer { lock.unlock() }

        if let repository = repositories[providerId] {
            return repository
        }

        // Built under the lock so two concurrent lookups cannot each start a sync. The factory
        // never calls back into this cache, so there is no re-entrancy hazard.
        let repository = makeRepository(providerId)
        repositories[providerId] = repository

        return repository
    }
}
