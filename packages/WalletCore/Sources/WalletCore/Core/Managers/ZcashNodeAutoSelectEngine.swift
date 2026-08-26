import Foundation
import MarketKit
import ZcashLightClientKit

// Thin Zcash conformer for the auto-select seam: node list and persistence come from
// ZcashNodeManager, switching goes through the live adapter (switchTo, no rebuild).
class ZcashNodeAutoSelectEngine {
    private let nodeManager: ZcashNodeManager
    private let coinManager: ICoinManager
    private weak var adapterManager: AdapterManager?

    init(nodeManager: ZcashNodeManager, coinManager: ICoinManager, adapterManager: AdapterManager) {
        self.nodeManager = nodeManager
        self.coinManager = coinManager
        self.adapterManager = adapterManager
    }

    // Project idiom for reaching a chain adapter: native token → adapter(for:) with a cast.
    // At most one exists — the zcash chain has a single native token per account.
    private var zcashAdapter: ZcashAdapter? {
        guard let token = try? coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }
        return adapterManager?.adapter(for: token) as? ZcashAdapter
    }
}

extension ZcashNodeAutoSelectEngine: INodeAutoSelectEngine {
    var autoSelectEnabled: Bool {
        nodeManager.autoSelectEnabled
    }

    var currentNodeId: String {
        nodeManager.node(blockchainType: .zcash).url.absoluteString
    }

    func pingNodes() async -> [NodeAutoSelector.PingResult] {
        await ZcashNodeManager.candidates(from: nodeManager.pingNodes(blockchainType: .zcash))
    }

    // Persist-only-on-success: switchEndpoint carries its own busy gate and reverts on failure,
    // so a throw leaves everything untouched. Manual path (setCurrent → nodeRelay) stays separate.
    func switchNode(id: String) async throws {
        guard let node = nodeManager.allNodes(blockchainType: .zcash).first(where: { $0.url.absoluteString == id }) else {
            return
        }

        // No live wallet: nothing to switch, the next adapter is created on the winner.
        guard let adapter = zcashAdapter else {
            nodeManager.persistCurrent(node: node, blockchainType: .zcash)
            return
        }

        try await adapter.switchEndpoint(ZcashAdapter.endpoint(url: node.url))
        nodeManager.persistCurrent(node: node, blockchainType: .zcash)
    }
}
