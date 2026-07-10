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
        guard let created = executable.created else {
            throw MultiSwapSendHandler.SendError.invalidTransactionData
        }

        _ = try await tronKitWrapper.send(createdTranaction: created)

        // The Tron tx hash IS the created transaction's `txID` (sha256 of raw_data — the value we
        // sign, which becomes the on-chain hash). Surface it as the broadcast hash so USwap swaps
        // (e.g. LI.FI Tron-source) can track by `inboundTxHash`; without it the track call would
        // omit the hash and the server can't poll the provider's status.
        return BroadcastResult(txHash: created.txID.hs.hex, trackingHandle: nil)
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
