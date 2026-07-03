import Foundation
import MarketKit

class ZanoSwapBroadcaster: ISwapBroadcaster {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? ZanoExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let adapter = adapterManager.adapter(for: executable.token) as? ZanoAdapter else {
            throw MultiSwapSendHandler.SendError.noZanoAdapter
        }

        try adapter.send(to: executable.address, amount: executable.amount, memo: executable.memo)

        return BroadcastResult(txHash: nil, trackingHandle: nil)
    }
}

extension ZanoSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        guard blockchainType == .zano else {
            return nil
        }

        return ZanoSwapBroadcaster(adapterManager: Core.shared.adapterManager)
    }
}
