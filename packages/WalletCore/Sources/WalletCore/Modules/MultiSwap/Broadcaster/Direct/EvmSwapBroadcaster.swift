import EvmKit
import Foundation
import MarketKit

class EvmSwapBroadcaster: ISwapBroadcaster {
    private let evmKitWrapper: EvmKitWrapper
    private let securityManager: SecurityManager
    private let localStorage: LocalStorage

    init(evmKitWrapper: EvmKitWrapper, securityManager: SecurityManager, localStorage: LocalStorage) {
        self.evmKitWrapper = evmKitWrapper
        self.securityManager = securityManager
        self.localStorage = localStorage
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

        if AppConfig.showDevTools, localStorage.emulateEvmSwapSend {
            let fakeHash = Data((0 ..< 32).map { _ in UInt8.random(in: .min ... .max) })
            return BroadcastResult(txHash: fakeHash.hs.hexString, trackingHandle: nil)
        }

        // routing flag read live at send-tap: MEV toggle state is the persisted setting
        let fullTransaction = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            privateSend: executable.mevProtectionAllowed && securityManager.swapProtectionEnabled,
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

        return EvmSwapBroadcaster(evmKitWrapper: evmKitWrapper, securityManager: Core.shared.securityManager, localStorage: Core.shared.localStorage)
    }
}
