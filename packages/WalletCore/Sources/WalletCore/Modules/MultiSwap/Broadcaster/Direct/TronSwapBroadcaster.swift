import Foundation
import MarketKit

class TronSwapBroadcaster: ISwapBroadcaster {
    private let tronKitWrapper: TronKitWrapper

    init(tronKitWrapper: TronKitWrapper) {
        self.tronKitWrapper = tronKitWrapper
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? TronExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        _ = try await tronKitWrapper.send(createdTranaction: executable.created)

        return BroadcastResult(txHash: nil, trackingHandle: nil)
    }
}

extension TronSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        guard blockchainType == .tron,
              let tronKitWrapper = Core.shared.tronAccountManager.tronKitManager.tronKitWrapper,
              tronKitWrapper.signer != nil
        else {
            return nil
        }

        return TronSwapBroadcaster(tronKitWrapper: tronKitWrapper)
    }
}
