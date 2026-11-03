import Alamofire
import Combine
import Foundation
import HsExtensions
import HsToolKit
import MarketKit
import ObjectMapper

/// The only provider directory: `GET /v3/providers` synced hourly into `SwapProviderStorage`. Venue
/// names, AML policies, privacy levels, execution types and split capability are read from here and
/// nowhere else. Suspensions are enforced server-side; a wholly suspended provider is dropped at sync.
class MultiSwapProviderManager {
    static let transferExecutionType = "transfer"
    private static let fallbackPrivacyLevels = ["basic"]

    private let expiration: TimeInterval = 60 * 60

    private let storage: SwapProviderStorage
    private let networkManager: NetworkManager

    private let baseUrl = "\(AppConfig.swapApiUrl)/v3"
    private var headers: HTTPHeaders?

    /// The synced rows by provider id. Written on the main actor, read from swap builders and the
    /// pre-send render path off it, so every access goes through `recordsLock`.
    private var _records = [String: SwapProviderRecord]()
    private let recordsLock = NSLock()

    /// Unknown venue ids that already forced a sync, with the time they did, so an id the server keeps
    /// quoting but never lists forces at most one fetch an hour.
    private var unknownSyncTimestamps = [String: TimeInterval]()
    private var syncTask: Task<Void, Never>?

    /// Ids of the providers that serve `/v3/split/*` (`splitSwaps`), the only ones quoted on the Private
    /// (split) swap tab. Assigned before `syncVersion`, which is the signal subscribers react to.
    @PostPublished private(set) var splitProviders: [String] = []
    /// Bumped after every applied list (the stored table at launch, each successful sync): the signal
    /// the swap screen, the catalog and the private-send gate re-evaluate on.
    @PostPublished private(set) var syncVersion = 0

    init(storage: SwapProviderStorage, networkManager: NetworkManager, apiKey: String?) {
        self.storage = storage
        self.networkManager = networkManager

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }

        // The last synced list, so a cold launch names venues straight away; `sync()` decides from the
        // stored timestamp whether the hour is up. The table is created empty by migration, so an
        // install upgrading from an older schema fetches on its first launch rather than trusting stale
        // rows, and the same holds for any future column: a migration that adds one must empty the table.
        apply(records: (try? storage.providers()) ?? [])
        sync()
    }

    // MARK: - Reads (safe off-main)

    func record(providerId: String) -> SwapProviderRecord? {
        recordsLock.withLock { _records[providerId] }
    }

    /// The provider's AML policy as published by the backend; nil when the server has not rated it
    /// (or no sync has ever succeeded).
    func amlPolicy(providerId: String) -> SwapProviderType? {
        record(providerId: providerId)?.amlPolicy.flatMap { SwapProviderType(rawValue: $0.lowercased()) }
    }

    /// `executionType` as published by `/v3/providers`; nil for an unknown id or an entry without one.
    func executionType(providerId: String) -> String? {
        guard let executionType = record(providerId: providerId)?.executionType, !executionType.isEmpty else {
            return nil
        }

        return executionType
    }

    /// The venue a route is served by. An id the last sync did not list gets a humanized name and no
    /// policy (`isKnown == false`); `requestSync(unknownProviderId:)` fetches the list for it.
    func venue(id: String) -> SwapVenue {
        guard let record = record(providerId: id) else {
            return .unknown(id: id)
        }

        return SwapVenue(
            id: id,
            name: record.name.isEmpty ? SwapVenue.humanized(id: id) : record.name,
            type: record.amlPolicy.flatMap { SwapProviderType(rawValue: $0.lowercased()) },
            privacy: record.privacy,
            executionType: record.executionType.flatMap { $0.isEmpty ? nil : $0 },
            isKnown: true
        )
    }

    /// Providers a private send may route through: confidential (`privacy != none`), settling as a plain
    /// `transfer`, and present in the synced list (wholly suspended providers are dropped at sync).
    var privateProviderIds: Set<String> {
        Self.privateProviderIds(records: recordsLock.withLock { Array(_records.values) })
    }

    /// The distinct synced privacy levels other than `none`, what a private send asks `/v3/rate` for.
    /// `["basic"]` until a sync has listed a confidential provider.
    var privacyLevelsExcludingNone: [String] {
        Self.privacyLevelsExcludingNone(records: recordsLock.withLock { Array(_records.values) })
    }

    static func privateProviderIds(records: [SwapProviderRecord]) -> Set<String> {
        Set(records
            .filter { $0.privacy != SwapVenue.noPrivacy && $0.executionType == transferExecutionType }
            .map(\.providerId))
    }

    static func privacyLevelsExcludingNone(records: [SwapProviderRecord]) -> [String] {
        let levels = Set(records.map(\.privacy)).subtracting([SwapVenue.noPrivacy])

        return levels.isEmpty ? fallbackPrivacyLevels : levels.sorted()
    }

    // MARK: - Sync

    func sync() {
        if let lastSyncTimestamp = try? storage.lastSyncTimestamp(), Date().timeIntervalSince1970 - lastSyncTimestamp < expiration {
            return
        }

        startSync()
    }

    /// A route named a venue the list does not know: fetch the list now, ignoring the hour, once per id
    /// per hour. Called from quote tasks, so it hops to the main actor before touching the bookkeeping.
    func requestSync(unknownProviderId: String) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let now = Date().timeIntervalSince1970

            if let last = unknownSyncTimestamps[unknownProviderId], now - last < expiration {
                return
            }

            unknownSyncTimestamps[unknownProviderId] = now
            startSync()
        }
    }

    private func startSync() {
        guard syncTask == nil else {
            return
        }

        syncTask = Task { [weak self, networkManager, storage, baseUrl, headers] in
            defer {
                Task { @MainActor [weak self] in
                    self?.syncTask = nil
                }
            }

            do {
                let responses: [ProviderResponse] = try await networkManager.fetch(url: "\(baseUrl)/providers", headers: headers)
                let timestamp = Date().timeIntervalSince1970

                // A wholly suspended provider is dropped here rather than filtered later: there is no
                // pair it can serve, so it must neither be named nor gate a private send.
                let records = responses.filter { !$0.suspended }.enumerated().map { position, response in
                    Self.record(response: response, position: position, timestamp: timestamp)
                }

                // Stored before it is published, with the timestamp on the rows themselves: a failed
                // write, like a failed fetch, leaves the previous list and timestamp in place, so the
                // next `sync()` — the swap screen calls it on appear — retries instead of waiting out
                // the hour.
                try storage.save(providers: records)

                await MainActor.run { [weak self] in
                    self?.apply(records: records)
                }
            } catch {
                // Logged because an install that has never held a list stays without names until that retry.
                print("[MultiSwapProviderManager] provider sync failed: \(error)")
            }
        }
    }

    /// Replaces every published value from one provider list — the stored table at launch or a fresh
    /// sync — so the in-memory state never mixes two syncs.
    ///
    /// Runs on the main thread (`Core` builds the manager there, and `sync` hops to the main actor):
    /// `@PostPublished` is a bare `PassthroughSubject` fired synchronously from `didSet`, with no
    /// synchronisation of its own. `syncVersion` is assigned LAST — it is the signal subscribers react
    /// to, so everything they will read must already be in place by the time it publishes.
    private func apply(records: [SwapProviderRecord]) {
        recordsLock.withLock {
            _records = Dictionary(records.map { ($0.providerId, $0) }, uniquingKeysWith: { first, _ in first })
        }

        splitProviders = Self.splitProviderIds(records: records)
        syncVersion += 1
    }

    /// Ids quoted on the Private (split) tab: every provider that serves `/v3/split/*`, in the server's
    /// order. Wholly suspended providers are already gone from `records`.
    static func splitProviderIds(records: [SwapProviderRecord]) -> [String] {
        records.filter(\.splitSwaps).map(\.providerId)
    }

    static func record(response: ProviderResponse, position: Int, timestamp: TimeInterval) -> SwapProviderRecord {
        SwapProviderRecord(
            providerId: response.provider,
            position: position,
            name: response.name ?? SwapVenue.humanized(id: response.provider),
            executionType: response.executionType,
            amlPolicy: response.amlPolicy,
            privacy: response.privacy,
            splitSwaps: response.splitSwaps,
            lastSyncTimestamp: timestamp
        )
    }
}

extension MultiSwapProviderManager {
    struct ProviderResponse: ImmutableMappable {
        let provider: String
        /// Display name; absent on an entry the server has no name for (then the id is humanized).
        let name: String?
        /// Whole-provider kill switch.
        let suspended: Bool
        /// How the provider settles (`thorchain_deposit`, `signed_transaction`, `transfer`, ...).
        let executionType: String?
        /// `excellent` | `good` | `fair`; mapped to `SwapProviderType` when read.
        let amlPolicy: String?
        /// `none` | `basic` | ...; absent reads as `none`.
        let privacy: String
        /// Whether the provider serves the `/v3/split/*` endpoints (one deposit delivered to several
        /// addresses), i.e. can be quoted on the Private swap tab.
        let splitSwaps: Bool
        /// Whether the provider serves single-output `/v3/rate` quotes; false for split-only entries.
        let quotes: Bool

        init(map: Map) throws {
            provider = try map.value("provider")
            name = (try? map.value("name") as String).flatMap { $0.isEmpty ? nil : $0 }
            suspended = (try? map.value("suspended")) ?? false
            executionType = try? map.value("executionType")
            amlPolicy = try? map.value("amlPolicy")
            privacy = (try? map.value("privacy")) ?? SwapVenue.noPrivacy
            splitSwaps = (try? map.value("splitSwaps")) ?? false
            quotes = (try? map.value("quotes")) ?? true
        }
    }
}
