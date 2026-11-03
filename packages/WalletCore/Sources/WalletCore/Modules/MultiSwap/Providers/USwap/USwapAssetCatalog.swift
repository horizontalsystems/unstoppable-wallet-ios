import Combine
import Foundation
import MarketKit

/// The one token catalog: `GET /v3/tokens/all` synced hourly with `If-None-Match`, persisted through the
/// generic `SwapAssetStorage` under a single key, read synchronously (lock-guarded) from the swap screen,
/// the private-send gate and CrossPay.
///
/// `init` touches neither the database nor the network: `Core` builds the catalog on the main thread at
/// launch, and the stored rows (several thousand, JSON-decoded) are loaded inside the first `sync()` task,
/// published through `syncPublisher` like a fresh fetch, and only then compared with the server's ETag.
public final class USwapAssetCatalog {
    /// The `SwapAsset.provider` column value the catalog rows are stored under. Not a provider id.
    static let storageKey = "__catalog__"
    private static let expiration: TimeInterval = 60 * 60

    private let api: USwapMultiSwapApi
    private let storage: SwapAssetStorage
    private let localStorage: LocalStorage
    private let providerManager: MultiSwapProviderManager
    private let syncSubject = PassthroughSubject<Void, Never>()
    private let stateLock = NSLock()
    private var state = State(entries: [:], etag: nil, lastSyncTimestamp: nil, storedRowsLoaded: false, refreshTask: nil)

    init(api: USwapMultiSwapApi, storage: SwapAssetStorage, localStorage: LocalStorage, providerManager: MultiSwapProviderManager) {
        self.api = api
        self.storage = storage
        self.localStorage = localStorage
        self.providerManager = providerManager

        sync()
    }

    /// Fires when the stored rows are loaded, on a catalog sync (200 and 304 alike) and on every
    /// provider-list sync (the private-send gate depends on both).
    public var syncPublisher: AnyPublisher<Void, Never> {
        Publishers.Merge(syncSubject, providerManager.$syncVersion.map { _ in () })
            .eraseToAnyPublisher()
    }

    /// Whether a catalog has landed (the stored rows or a fetch). Until then every catalogued token
    /// would read as uncatalogued, so callers that show "not supported" wait for this instead.
    public var isLoaded: Bool {
        withState { !$0.entries.isEmpty }
    }

    func entry(token: Token) -> USwapCatalogEntry? {
        withState { $0.entries[token.tokenQuery.id.lowercased()] }
    }

    /// The identifier a request names the token by: the catalog identifier, else the bare address with
    /// the request's `chainId` (`USwapAssetMapping.bareAddress`), else nil (the token cannot be quoted).
    public func asset(token: Token) -> String? {
        entry(token: token)?.identifier ?? USwapAssetMapping.bareAddress(token: token)
    }

    public func contains(token: Token) -> Bool {
        entry(token: token) != nil
    }

    /// Providers with a token list that quote the token. Not exhaustive (no DEX / LI.FI venues).
    public func venueIds(token: Token) -> [String] {
        entry(token: token)?.providerIds ?? []
    }

    /// Synchronous, lock-guarded: called from the pre-send render path.
    public func privateVenueIds(token: Token) -> [String] {
        USwapPrivateSendGate.privateVenueIds(
            entry: entry(token: token),
            blockchainType: token.blockchainType,
            privateProviderIds: providerManager.privateProviderIds
        )
    }

    /// Loads the stored rows on the first call, then fetches `GET /v3/tokens/all` when the hour is up.
    /// One task at a time; the hour is judged against the stored timestamp once it is known.
    public func sync() {
        withState { state in
            guard state.refreshTask == nil else {
                return
            }

            if state.storedRowsLoaded, let lastSyncTimestamp = state.lastSyncTimestamp,
               Date().timeIntervalSince1970 - lastSyncTimestamp < Self.expiration
            {
                return
            }

            // The catalog lives as long as `Core`, so the task is never cancelled; it holds the catalog
            // only for the duration of one sync.
            state.refreshTask = Task { [weak self] in
                await self?.runSync()
            }
        }
    }
}

private extension USwapAssetCatalog {
    struct State {
        var entries: [String: USwapCatalogEntry]
        var etag: String?
        var lastSyncTimestamp: TimeInterval?
        /// Whether the persisted rows have been read into `entries` (once per process)
        var storedRowsLoaded: Bool
        var refreshTask: Task<Void, Never>?
    }

    func withState<T>(_ action: (inout State) -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action(&state)
    }

    func runSync() async {
        do {
            try Task.checkCancellation()

            // 1. The persisted catalog, before any network answer can be compared with its ETag.
            if !withState({ $0.storedRowsLoaded }) {
                let entries = (try? storage.swapAssetMap(provider: Self.storageKey, as: USwapCatalogEntry.self)) ?? [:]
                let etag = entries.isEmpty ? nil : localStorage.swapCatalogEtag
                let timestamp: TimeInterval? = entries.isEmpty ? nil : try? storage.lastSyncTimetamp(provider: Self.storageKey)

                try Task.checkCancellation()

                await MainActor.run { [weak self] in
                    self?.applyStored(entries: entries, etag: etag, timestamp: timestamp)
                }
            }

            // 2. The hour, judged against the stored timestamp.
            let (etag, lastSyncTimestamp) = withState { ($0.etag, $0.lastSyncTimestamp) }

            if let lastSyncTimestamp, Date().timeIntervalSince1970 - lastSyncTimestamp < Self.expiration {
                finishSync()
                return
            }

            // 3. The network, conditional on the stored ETag.
            let response = try await api.allTokens(etag: etag)
            try Task.checkCancellation()

            let timestamp = Date().timeIntervalSince1970

            switch response {
            case .notModified:
                try? storage.save(lastSyncTimestamp: timestamp, provider: Self.storageKey)

                await MainActor.run { [weak self] in
                    self?.finishSync(timestamp: timestamp)
                }
            case let .tokens(tokens, newEtag):
                let entries = USwapAssetMapping.catalog(tokens: tokens)

                // An empty list is never stored as current: no ETag is kept for it, so the next sync
                // fetches the body again instead of being told "not modified".
                guard !entries.isEmpty else {
                    localStorage.swapCatalogEtag = nil
                    await MainActor.run { [weak self] in
                        self?.finishSync(etag: nil)
                    }
                    return
                }

                // The ETag is persisted only once the rows it describes are: a failed write must not
                // leave an ETag that would answer 304 for rows that were never saved.
                let etag: String?
                do {
                    try storage.save(swapAssetMap: entries, provider: Self.storageKey)
                    try storage.save(lastSyncTimestamp: timestamp, provider: Self.storageKey)
                    localStorage.swapCatalogEtag = newEtag
                    etag = newEtag
                } catch {
                    localStorage.swapCatalogEtag = nil
                    etag = nil
                }

                await MainActor.run { [weak self] in
                    self?.finishSync(entries: entries, etag: etag, timestamp: timestamp)
                }
            }
        } catch {
            // A failed fetch keeps the previous rows and ETag; the next `sync()` retries.
            finishSync()
        }
    }

    /// The persisted rows become the live catalog (main thread, like every publish). Published only when
    /// there is something to read, so the pre-send toggle and the swap screen re-evaluate once.
    func applyStored(entries: [String: USwapCatalogEntry], etag: String?, timestamp: TimeInterval?) {
        withState { state in
            state.entries = entries
            state.etag = etag
            state.lastSyncTimestamp = timestamp
            state.storedRowsLoaded = true
        }

        if !entries.isEmpty {
            syncSubject.send()
        }
    }

    func finishSync(entries: [String: USwapCatalogEntry], etag: String?, timestamp: TimeInterval) {
        withState { state in
            state.entries = entries
            state.etag = etag
            state.lastSyncTimestamp = timestamp
            state.refreshTask = nil
        }

        syncSubject.send()
    }

    /// 304: the rows stand, the hour restarts, and subscribers still hear that the catalog is current.
    func finishSync(timestamp: TimeInterval) {
        withState { state in
            state.lastSyncTimestamp = timestamp
            state.refreshTask = nil
        }

        syncSubject.send()
    }

    func finishSync() {
        withState { state in
            state.refreshTask = nil
        }
    }

    /// An unusable 200 (empty list): the rows stand, the ETag is dropped so the next sync refetches.
    func finishSync(etag: String?) {
        withState { state in
            state.etag = etag
            state.refreshTask = nil
        }
    }
}
