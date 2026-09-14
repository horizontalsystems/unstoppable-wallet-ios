import Foundation
import HsToolKit
import ZcashLightClientKit

// Endpoint selection and switching. #7163 (server autoselect/failover) lands here:
// evaluateBestOf over the ZcashNodeManager pool without touching the adapter contract.
class ZcashEndpointService {
    private static let quiescenceAttempts = 3
    private static let quiescenceDelay: TimeInterval = 2
    private static let lifecycleTimeout: TimeInterval = 60

    private let synchronizer: Synchronizer
    private let network: ZcashNetwork
    private let logger: HsToolKit.Logger?

    private(set) var currentEndpoint: LightWalletEndpoint

    init(synchronizer: Synchronizer, network: ZcashNetwork, endpoint: LightWalletEndpoint, logger: HsToolKit.Logger?) {
        self.synchronizer = synchronizer
        self.network = network
        currentEndpoint = endpoint
        self.logger = logger
    }

    // Used by AdapterManager to revert the stored selection on switch failure.
    var currentEndpointURL: URL? {
        URL(string: "\(currentEndpoint.secure ? "https" : "http")://\(currentEndpoint.host):\(currentEndpoint.port)")
    }

    func isEndpointAvailable(_ endpoint: LightWalletEndpoint) async -> Bool {
        // hard cap on the whole check: fetchThresholdSeconds bounds only the fetch phase,
        // while gRPC connect/TLS retries against a dead host spin far beyond it
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { [synchronizer, network] in
                let endpoints = await synchronizer.evaluateBestOf(
                    endpoints: [endpoint],
                    fetchThresholdSeconds: 20,
                    nBlocksToFetch: 1,
                    kServers: 1,
                    network: network.networkType
                )

                return endpoints.contains {
                    $0.host == endpoint.host && $0.port == endpoint.port && $0.secure == endpoint.secure
                }
            }

            group.addTask {
                try? await Task.sleep(seconds: 10)
                return false
            }

            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    // Endpoint changes only on a confirmed success: the SDK moves it after reopen but before
    // start, and a failed reopen leaves a closed handle — either way the app rolls back by
    // rebuilding at the previous endpoint.
    static func endpointAfterRebuild(target: LightWalletEndpoint, current: LightWalletEndpoint, error: Error?) -> LightWalletEndpoint {
        error == nil ? target : current
    }

    static func isQuiescenceRefusal(_ error: Error) -> Bool {
        if case .slipstreamEngineNotQuiescent = error as? ZcashError {
            return true
        }
        return false
    }

    func switchEndpoint(_ endpoint: LightWalletEndpoint) async throws {
        guard endpoint.host != currentEndpoint.host || endpoint.port != currentEndpoint.port || endpoint.secure != currentEndpoint.secure else {
            return
        }
        try await rebuild(at: endpoint)
    }

    // restartSync is the one call that leaves the engine running in both engines: the legacy
    // switchTo only re-registers services, the Slipstream one restarts a pass only if one was running.
    func rebuild(at target: LightWalletEndpoint) async throws {
        do {
            try await ZcashOperationGuard.shared.withLifecycle(timeout: Self.lifecycleTimeout) {
                var failure: Error?
                do {
                    try await retryingQuiescent { try await synchronizer.restartSync(at: target) }
                } catch {
                    failure = error
                    logger?.log(level: .error, message: "Failed to rebuild at \(target.host):\(target.port): \(error)")
                    try? await retryingQuiescent { try await synchronizer.restartSync(at: currentEndpoint) }
                }
                currentEndpoint = Self.endpointAfterRebuild(target: target, current: currentEndpoint, error: failure)
                if let failure {
                    throw failure
                }
            }
        } catch is ZcashOperationGuard.Failure {
            // a send held the guard for the whole timeout — "try again later"
            throw AppError.zcash(reason: .sendInProgress)
        }
    }

    private func retryingQuiescent(_ body: () async throws -> Void) async throws {
        for attempt in 1 ... Self.quiescenceAttempts {
            do {
                try await body()
                return
            } catch where Self.isQuiescenceRefusal(error) && attempt < Self.quiescenceAttempts {
                try await Task.sleep(seconds: Self.quiescenceDelay)
            }
        }
    }
}
