import Foundation
import MarketKit

class ZcashSwapBroadcaster: ISwapBroadcaster {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? ZcashExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let adapter = adapterManager.adapter(for: executable.token) as? ZcashAdapter else {
            throw MultiSwapSendHandler.SendError.noZcashAdapter
        }
        guard let proposal = executable.proposal else {
            throw MultiSwapSendHandler.SendError.noProposal
        }

        let hash = try await adapter.send(proposal: proposal)

        return BroadcastResult(txHash: hash, trackingHandle: nil)
    }
}

extension ZcashSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        guard blockchainType == .zcash else {
            return nil
        }

        return ZcashSwapBroadcaster(adapterManager: Core.shared.adapterManager)
    }
}
