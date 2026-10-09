import Alamofire
import Foundation
import HsExtensions
import HsToolKit
import ObjectMapper

class MultiSwapProviderManager {
    private static let vaultExecutionType = "thorchain_deposit"

    private let expiration: TimeInterval = 60 * 60

    private let localStorage: LocalStorage
    private let networkManager: NetworkManager

    private let baseUrl = "\(AppConfig.swapApiUrl)/v3"
    private var headers: HTTPHeaders?

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

    init(localStorage: LocalStorage, networkManager: NetworkManager, apiKey: String?) {
        self.localStorage = localStorage
        self.networkManager = networkManager
        // networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }

        syncProviders(uSwapProviders: localStorage.uSwapProviders?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [])

        let hadSuspensions = restoreSuspensions()
        let hadExecutionTypes = restoreExecutionTypes()

        // Force a fetch when suspensions or execution types have never been stored, even if the
        // provider list is still within its TTL. Upgrading from a build that predates them leaves a
        // FRESH `swap-providers-last-sync-timestamp` beside an empty cache, so the ordinary TTL check
        // would skip the sync and leave the first hour after the update unenforced (suspensions) or
        // without shielded ZEC delivery (execution types).
        sync(force: !hadSuspensions || !hadExecutionTypes)
    }

    private func syncProviders(uSwapProviders: [String]) {
        providers = uSwapProviders
    }

    private func syncSuspensions(responses: [ProviderResponse]) {
        var byProvider = [String: [SwapSuspension]]()

        for response in responses where !response.suspensions.isEmpty {
            byProvider[response.provider] = response.suspensions
        }

        suspensions = SwapSuspensionIndex(byProvider: byProvider)
        localStorage.uSwapSuspensions = Self.encode(byProvider: byProvider)
    }

    /// Suspensions must survive a cold launch: the provider list is cached for an hour, so without
    /// this a restart would quote a suspended provider until the next sync.
    ///
    /// Returns whether a stored cache was found at all — `false` means this install has never held
    /// suspensions, which is what makes the caller override the sync TTL. Note an empty rule set
    /// still round-trips as `{}`, so "no suspensions anywhere" reads as `true` and does not force a
    /// fetch on every launch.
    @discardableResult private func restoreSuspensions() -> Bool {
        guard let raw = localStorage.uSwapSuspensions, let data = raw.data(using: .utf8) else { return false }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: [[String: Any]]] else {
            return false
        }

        var byProvider = [String: [SwapSuspension]]()
        for (providerId, rules) in json {
            byProvider[providerId] = rules.compactMap { try? SwapSuspension(JSON: $0) }
        }

        suspensions = SwapSuspensionIndex(byProvider: byProvider)
        return true
    }

    private func syncExecutionTypes(responses: [ProviderResponse]) {
        var byProvider = [String: String]()

        for response in responses {
            if let executionType = response.executionType, !executionType.isEmpty {
                byProvider[response.provider] = executionType
            }
        }

        executionTypesLock.withLock { _executionTypes = byProvider }

        if let data = try? JSONSerialization.data(withJSONObject: byProvider) {
            localStorage.uSwapExecutionTypes = String(data: data, encoding: .utf8)
        }
    }

    /// Returns whether a stored cache was found; an empty map still round-trips as `{}`.
    private func restoreExecutionTypes() -> Bool {
        guard let raw = localStorage.uSwapExecutionTypes, let data = raw.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: String]
        else {
            return false
        }

        executionTypesLock.withLock { _executionTypes = json }
        return true
    }

    /// Whether a provider can pay a ZEC output to a shielded / unified receiver. Vault-settled
    /// (thorchain_deposit) providers deliver from their own ZEC client, which addresses unified
    /// receivers; transfer venues reject shielded recipients at order creation. Read from
    /// /v3/providers so the server, not the app, decides per provider. Safe to call off-main.
    func deliversShieldedZcash(providerId: String) -> Bool {
        executionTypesLock.withLock { _executionTypes[providerId] } == Self.vaultExecutionType
    }

    private static func encode(byProvider: [String: [SwapSuspension]]) -> String? {
        var json = [String: [[String: Any]]]()

        for (providerId, rules) in byProvider {
            json[providerId] = rules.map { rule in
                var dict: [String: Any] = ["kind": rule.kind.rawValue, "side": rule.side.rawValue]
                if let asset = rule.asset { dict["asset"] = asset }
                if let chain = rule.chain { dict["chain"] = chain }
                if let sellAsset = rule.sellAsset { dict["sellAsset"] = sellAsset }
                if let buyAsset = rule.buyAsset { dict["buyAsset"] = buyAsset }
                if let expiresAt = rule.expiresAt { dict["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt) }
                return dict
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func sync(force: Bool = false) {
        let lastSyncTimetamp = localStorage.swapProvidersLastSyncTimestamp

        if !force, let lastSyncTimetamp, Date().timeIntervalSince1970 - lastSyncTimetamp < expiration {
            return
        }

        Task { [weak self, networkManager, baseUrl, headers] in
            do {
                let responses: [ProviderResponse] = try await networkManager.fetch(url: "\(baseUrl)/providers", headers: headers)

                // A wholly suspended provider is dropped here rather than filtered per-pair later —
                // there is no pair it can serve, so it should not produce a card at all.
                await self?.apply(responses: responses.filter { !$0.suspended })
            } catch {
                // The cached list stays in place and the sync timestamp is deliberately NOT
                // stamped, so the next `sync()` — the swap screen calls it on appear — retries
                // instead of waiting out the hour. Logged because a FORCED sync failing means an
                // install that has never held suspensions stays unenforced until that retry.
                print("[MultiSwapProviderManager] provider sync failed: \(error)")
            }
        }
    }

    /// Applies a fetched provider list on the main actor.
    ///
    /// `@PostPublished` is a bare `PassthroughSubject` fired synchronously from `didSet`, with no
    /// synchronisation of its own, and `MultiSwapViewModel` reads both properties from the main
    /// thread — so the writes have to happen there too.
    @MainActor
    private func apply(responses: [ProviderResponse]) {
        let ids = responses.map(\.provider)

        // Suspensions FIRST. `providers` is the signal the view model subscribes to, so everything
        // it will read must already be in place by the time that assignment publishes.
        syncSuspensions(responses: responses)
        syncExecutionTypes(responses: responses)
        syncProviders(uSwapProviders: ids)

        localStorage.uSwapProviders = ids.joined(separator: ",")
        localStorage.swapProvidersLastSyncTimestamp = Date().timeIntervalSince1970
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

        init(map: Map) throws {
            provider = try map.value("provider")
            suspended = (try? map.value("suspended")) ?? false
            suspensions = (try? map.value("suspensions")) ?? []
            executionType = try? map.value("executionType")
        }
    }
}
