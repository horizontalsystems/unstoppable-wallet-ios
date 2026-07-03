import Foundation
import MarketKit

class UtxoSwapBroadcaster: ISwapBroadcaster {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? UtxoExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let adapter = adapterManager.adapter(for: executable.token) as? BitcoinBaseAdapter else {
            throw MultiSwapSendHandler.SendError.noBitcoinAdapter
        }
        guard let sendParameters = executable.sendParameters else {
            throw MultiSwapSendHandler.SendError.noSendParameters
        }

        let fullTransaction = try adapter.send(params: sendParameters)

        return BroadcastResult(txHash: fullTransaction.header.dataHash.hs.reversedHex, trackingHandle: nil)
    }
}

extension UtxoSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        guard BtcBlockchainManager.blockchainTypes.contains(blockchainType) else {
            return nil
        }

        return UtxoSwapBroadcaster(adapterManager: Core.shared.adapterManager)
    }
}
