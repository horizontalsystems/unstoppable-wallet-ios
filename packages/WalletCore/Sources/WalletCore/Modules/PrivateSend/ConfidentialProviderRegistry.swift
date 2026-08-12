import Combine
import Foundation

// The list of USwap providers that route through a confidential rail. Kept apart from the static
// USwapProviderInfo table so the server, not a release, decides which providers are available.
public final class ConfidentialProviderRegistry {
    private static let expiration: TimeInterval = 6 * 60 * 60

    // A confidential provider is only usable here if it executes as a plain transfer: anything
    // else (signed_transaction, thorchain_deposit, …) needs real transaction building and must
    // not silently join the private send flow.
    private static let supportedExecutionType = "transfer"

    private let api: USwapMultiSwapApi
    private let storage: ConfidentialProviderStorage
    private let fallbackIds: [String]
    private let syncSubject = PassthroughSubject<Void, Never>()
    private let stateLock = NSLock()
    private var state: State

    public init(api: USwapMultiSwapApi, storage: ConfidentialProviderStorage, fallbackIds: [String] = ["NEAR_CONFIDENTIAL"]) {
        self.api = api
        self.storage = storage
        self.fallbackIds = fallbackIds

        let storedIds = (try? storage.providerIds()) ?? []
        let lastSyncTimestamp = try? storage.lastSyncTimestamp()

        state = State(
            // The seed only covers first launch / offline. A successful sync always replaces it,
            // including removing a provider the server stops marking confidential.
            providerIds: storedIds.isEmpty ? fallbackIds : storedIds,
            synced: !storedIds.isEmpty,
            lastSyncTimestamp: lastSyncTimestamp
        )

        sync()
    }

    deinit {
        stateLock.lock()
        let refreshTask = state.refreshTask
        state.refreshTask = nil
        stateLock.unlock()

        refreshTask?.cancel()
    }

    public var providerIds: [String] {
        withState { $0.providerIds }
    }

    public var syncPublisher: AnyPublisher<Void, Never> {
        syncSubject.eraseToAnyPublisher()
    }

    public func sync() {
        let api = api
        let storage = storage

        withState { state in
            guard state.refreshTask == nil else {
                return
            }

            if state.synced,
               let lastSyncTimestamp = state.lastSyncTimestamp,
               Date().timeIntervalSince1970 - lastSyncTimestamp < Self.expiration
            {
                return
            }

            state.refreshTask = Task { [weak self] in
                do {
                    try Task.checkCancellation()
                    let descriptors = try await api.providers()
                    try Task.checkCancellation()

                    let confidential = descriptors.filter {
                        $0.confidential && !$0.suspended && $0.executionType == Self.supportedExecutionType
                    }
                    let providerIds = confidential.map(\.id)
                    let executionTypes = Dictionary(
                        confidential.map { ($0.id, $0.executionType) },
                        uniquingKeysWith: { first, _ in first }
                    )

                    let timestamp = Date().timeIntervalSince1970
                    try? storage.save(providerIds: providerIds, executionTypes: executionTypes, lastSyncTimestamp: timestamp)

                    await MainActor.run { [weak self] in
                        self?.finishSync(providerIds: providerIds, timestamp: timestamp)
                    }
                } catch {
                    self?.finishSync()
                }
            }
        }
    }
}

private extension ConfidentialProviderRegistry {
    struct State {
        var providerIds: [String]
        var synced: Bool
        var lastSyncTimestamp: TimeInterval?
        var refreshTask: Task<Void, Never>?
    }

    func withState<T>(_ action: (inout State) -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action(&state)
    }

    func finishSync(providerIds: [String], timestamp: TimeInterval) {
        withState { state in
            state.providerIds = providerIds
            state.synced = true
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
}
