import Foundation
import MarketKit

class MoneroSwapBroadcaster: ISwapBroadcaster {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? MoneroExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let adapter = adapterManager.adapter(for: executable.token) as? MoneroAdapter else {
            throw MultiSwapSendHandler.SendError.noMoneroAdapter
        }

        try adapter.send(
            to: executable.address,
            amount: executable.amount,
            priority: executable.priority,
            memo: executable.memo
        )

        return BroadcastResult(txHash: nil, trackingHandle: nil)
    }
}

extension MoneroSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        guard blockchainType == .monero else {
            return nil
        }

        return MoneroSwapBroadcaster(adapterManager: Core.shared.adapterManager)
    }
}
