import Foundation
import HsToolKit
import ZcashLightClientKit

// Endpoint selection and switching. #7163 (server autoselect/failover) lands here:
// evaluateBestOf over the ZcashNodeManager pool without touching the adapter contract.
class ZcashEndpointService {
    private let synchronizer: Synchronizer
    private let network: ZcashNetwork
    private let logger: HsToolKit.Logger?

    weak var syncService: ZcashSyncService?

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

    func switchEndpoint(_ endpoint: LightWalletEndpoint) async throws {
        guard endpoint.host != currentEndpoint.host || endpoint.port != currentEndpoint.port || endpoint.secure != currentEndpoint.secure else {
            return
        }

        // defense for non-UI callers (backup restore, node deletion): never reconfigure the
        // synchronizer while background-finishing work (a send/migration broadcast) is active — "try again later"
        let busy = await MainActor.run { Core.shared.backgroundTaskManager.isCriticalActive }
        guard !busy else {
            throw AppError.zcash(reason: .sendInProgress)
        }

        do {
            try await synchronizer.switchTo(endpoint: endpoint)
            currentEndpoint = endpoint
            syncService?.startSynchronizer()
        } catch {
            logger?.log(level: .error, message: "Failed to switch endpoint to \(endpoint.host):\(endpoint.port): \(error)")
            try? await synchronizer.switchTo(endpoint: currentEndpoint)
            syncService?.startSynchronizer()
            throw error
        }
    }
}
