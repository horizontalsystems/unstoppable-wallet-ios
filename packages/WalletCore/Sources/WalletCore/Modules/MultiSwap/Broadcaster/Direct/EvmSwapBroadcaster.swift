import EvmKit
import Foundation
import MarketKit

class EvmSwapBroadcaster: ISwapBroadcaster {
    private let evmKitWrapper: EvmKitWrapper

    init(evmKitWrapper: EvmKitWrapper) {
        self.evmKitWrapper = evmKitWrapper
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? EvmExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let transactionData = executable.transactionData else {
            throw MultiSwapSendHandler.SendError.invalidTransactionData
        }
        guard let gasLimit = executable.gasLimit else {
            throw MultiSwapSendHandler.SendError.noGasLimit
        }
        guard let gasPrice = executable.gasPrice else {
            throw MultiSwapSendHandler.SendError.noGasPrice
        }

        let fullTransaction = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            privateSend: executable.privateSend,
            nonce: executable.nonce
        )

        return BroadcastResult(txHash: fullTransaction.transaction.hash.hs.hexString, trackingHandle: nil)
    }
}

extension EvmSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        guard let evmKitWrapper = try? Core.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper,
              evmKitWrapper.signer != nil
        else {
            return nil
        }

        return EvmSwapBroadcaster(evmKitWrapper: evmKitWrapper)
    }
}
