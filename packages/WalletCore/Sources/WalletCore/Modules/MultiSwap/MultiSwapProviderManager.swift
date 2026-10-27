import Alamofire
import Foundation
import HsExtensions
import HsToolKit
import MarketKit
import ObjectMapper

class MultiSwapProviderManager {
    private static let vaultExecutionType = "thorchain_deposit"

    private let expiration: TimeInterval = 60 * 60

    private let storage: SwapProviderStorage
    private let networkManager: NetworkManager

    private let baseUrl = "\(AppConfig.swapApiUrl)/v3"
    private var headers: HTTPHeaders?

    /// Ids of the providers quotable on the Standard tab (`quotes: true`). Split-only entries such as
    /// `SWAPUZ_SPLIT` are left out so they are never sent to `/v3/rate`.
    @PostPublished private(set) var providers: [String] = []
    /// Scoped asset/chain/pair suspensions, indexed by provider id. Applied by `MultiSwapViewModel`
    /// when it decides which providers can serve the current pair.
    @PostPublished private(set) var suspensions = SwapSuspensionIndex()
    /// `executionType` per provider id, as published by `/v3/providers`. Route capabilities that
    /// depend on how a provider settles (e.g. shielded ZEC delivery) are read from here, never
    /// from a provider id. Written on the main actor but read from swap builders off it, so every
    /// access goes through `executionTypesLock`.
    private var _executionTypes = [String: String]()
    private let executionTypesLock = NSLock()
    /// `amlPolicy` per provider id, as published by `/v3/providers`. Read by the swap views through
    /// `USwapMultiSwapProvider.type`; guarded like `_executionTypes` because reads are not confined to main.
    private var _amlPolicies = [String: SwapProviderType]()
    private let amlPoliciesLock = NSLock()
    /// Ids of the providers flagged `split` by the backend: the only ones quoted on the Private
    /// (split) swap tab. Assigned before `providers`, which is the signal subscribers react to.
    @PostPublished private(set) var splitProviders: [String] = []

    init(storage: SwapProviderStorage, networkManager: NetworkManager, apiKey: String?) {
        self.storage = storage
        self.networkManager = networkManager
        // networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }

        // The last synced list, so a cold launch quotes straight away and keeps honouring the cached
        // suspensions; `sync()` decides from the stored timestamp whether the hour is up. The table is
        // created empty by migration, so an install upgrading from the UserDefaults cache fetches on its
        // first launch rather than running without suspensions, and the same holds for any future column:
        // a migration that adds one must empty the table so the stale rows are not trusted for an hour.
        apply(records: (try? storage.providers()) ?? [])
        sync()
    }

    /// The provider's AML policy as published by the backend; nil when the server has not rated it
    /// (or no sync has ever succeeded). Safe to call off-main.
    func amlPolicy(providerId: String) -> SwapProviderType? {
        amlPoliciesLock.withLock { _amlPolicies[providerId] }
    }

    /// Whether a swap selling `tokenIn` through this provider can pay its ZEC output to a shielded /
    /// unified receiver: the provider must settle through a vault, and the sell chain must carry the
    /// route memo that names a unified address, which an OP_RETURN output cannot — the UTXO chains fall
    /// back to the transparent address. Safe to call off-main.
    func deliversShieldedZcash(providerId: String, tokenIn: Token) -> Bool {
        isVaultSettled(providerId: providerId) && !tokenIn.blockchainType.memoRidesOpReturn
    }

    /// Whether a provider settles through a vault (thorchain_deposit) and so pays a ZEC output from its
    /// own ZEC client, which addresses unified receivers; transfer venues reject shielded recipients at
    /// order creation. Inferred from the executionType /v3/providers publishes, so the server decides per
    /// provider. Known false for THORChain, which accepts only transparent ZEC and lists no ZEC today; a
    /// per-provider flag is requested from the backend. Never the whole answer: the sell chain's memo
    /// must fit a unified address too, see `deliversShieldedZcash(providerId:tokenIn:)`.
    private func isVaultSettled(providerId: String) -> Bool {
        executionTypesLock.withLock { _executionTypes[providerId] } == Self.vaultExecutionType
    }

    func sync() {
        if let lastSyncTimestamp = try? storage.lastSyncTimestamp(), Date().timeIntervalSince1970 - lastSyncTimestamp < expiration {
            return
        }

        Task { [weak self, networkManager, storage, baseUrl, headers] in
            do {
                let responses: [ProviderResponse] = try await networkManager.fetch(url: "\(baseUrl)/providers", headers: headers)
                let timestamp = Date().timeIntervalSince1970

                // A wholly suspended provider is dropped here rather than filtered per-pair later —
                // there is no pair it can serve, so it should not produce a card at all.
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
                // Logged because an install that has never held a list stays without providers until
                // that retry.
                print("[MultiSwapProviderManager] provider sync failed: \(error)")
            }
        }
    }

    /// Replaces every published value from one provider list — the stored table at launch or a fresh
    /// sync — so the in-memory state never mixes two syncs.
    ///
    /// Runs on the main thread (`Core` builds the manager there, and `sync` hops to the main actor):
    /// `@PostPublished` is a bare `PassthroughSubject` fired synchronously from `didSet`, with no
    /// synchronisation of its own, and `MultiSwapViewModel` reads these properties from the main
    /// thread. `providers` is assigned LAST — it is the signal the view model subscribes to, so
    /// everything it will read must already be in place by the time that assignment publishes.
    private func apply(records: [SwapProviderRecord]) {
        var suspensionsByProvider = [String: [SwapSuspension]]()
        var executionTypes = [String: String]()
        var amlPolicies = [String: SwapProviderType]()

        for record in records {
            let rules = Self.decode(suspensions: record.suspensions)
            if !rules.isEmpty {
                suspensionsByProvider[record.providerId] = rules
            }

            if let executionType = record.executionType, !executionType.isEmpty {
                executionTypes[record.providerId] = executionType
            }

            // An absent or unknown value (e.g. a future level) leaves the provider unrated; never defaulted.
            if let amlPolicy = record.amlPolicy, let type = SwapProviderType(rawValue: amlPolicy.lowercased()) {
                amlPolicies[record.providerId] = type
            }
        }

        executionTypesLock.withLock { _executionTypes = executionTypes }
        amlPoliciesLock.withLock { _amlPolicies = amlPolicies }
        suspensions = SwapSuspensionIndex(byProvider: suspensionsByProvider)
        splitProviders = Self.splitProviderIds(records: records)
        providers = Self.quotableProviderIds(records: records)
    }

    /// Ids quoted on the Standard tab: every provider that serves `/v3/rate`, in the server's order.
    static func quotableProviderIds(records: [SwapProviderRecord]) -> [String] {
        records.filter(\.quotes).map(\.providerId)
    }

    /// Ids quoted on the Private (split) tab: every provider that serves `/v3/split/*`, in the server's order.
    static func splitProviderIds(records: [SwapProviderRecord]) -> [String] {
        records.filter(\.split).map(\.providerId)
    }

    private static func record(response: ProviderResponse, position: Int, timestamp: TimeInterval) -> SwapProviderRecord {
        SwapProviderRecord(
            providerId: response.provider,
            position: position,
            executionType: response.executionType,
            amlPolicy: response.amlPolicy,
            split: response.split,
            quotes: response.quotes,
            suspensions: encode(suspensions: response.suspensions),
            lastSyncTimestamp: timestamp
        )
    }

    private static func encode(suspensions: [SwapSuspension]) -> String? {
        guard !suspensions.isEmpty else { return nil }

        let json: [[String: Any]] = suspensions.map { rule in
            var dict: [String: Any] = ["kind": rule.kind.rawValue, "side": rule.side.rawValue]
            if let asset = rule.asset { dict["asset"] = asset }
            if let chain = rule.chain { dict["chain"] = chain }
            if let sellAsset = rule.sellAsset { dict["sellAsset"] = sellAsset }
            if let buyAsset = rule.buyAsset { dict["buyAsset"] = buyAsset }
            if let expiresAt = rule.expiresAt { dict["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt) }
            return dict
        }

        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func decode(suspensions: String?) -> [SwapSuspension] {
        guard let suspensions, let data = suspensions.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else {
            return []
        }

        return json.compactMap { try? SwapSuspension(JSON: $0) }
    }
}

extension MultiSwapProviderManager {
    struct ProviderResponse: ImmutableMappable {
        let provider: String
        /// Whole-provider kill switch.
        let suspended: Bool
        let suspensions: [SwapSuspension]
        /// How the provider settles (`thorchain_deposit`, `signed_transaction`, ...).
        let executionType: String?
        /// `excellent` | `good` | `fair`; mapped to `SwapProviderType` when the stored list is applied.
        let amlPolicy: String?
        /// Whether the provider serves the `/v3/split/*` endpoints (one deposit delivered to several
        /// addresses), i.e. can be quoted on the Private swap tab.
        let split: Bool
        /// Whether the provider serves single-output `/v3/rate` quotes. False for split-only entries
        /// (`SWAPUZ_SPLIT`); an entry without the flag is an ordinary quotable provider.
        let quotes: Bool

        init(map: Map) throws {
            provider = try map.value("provider")
            suspended = (try? map.value("suspended")) ?? false
            suspensions = (try? map.value("suspensions")) ?? []
            executionType = try? map.value("executionType")
            amlPolicy = try? map.value("amlPolicy")
            split = (try? map.value("splitSwaps")) ?? false
            quotes = (try? map.value("quotes")) ?? true
        }
    }
}
