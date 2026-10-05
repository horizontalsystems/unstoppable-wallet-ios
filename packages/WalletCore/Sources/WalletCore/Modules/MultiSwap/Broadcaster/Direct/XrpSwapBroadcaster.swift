import Foundation
import MarketKit

class XrpSwapBroadcaster: ISwapBroadcaster {
    private let account: Account
    private let adapterManager: AdapterManager

    init(account: Account, adapterManager: AdapterManager) {
        self.account = account
        self.adapterManager = adapterManager
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? XrpExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let adapter = adapterManager.adapter(for: executable.token) as? ISendXrpAdapter else {
            throw MultiSwapSendHandler.SendError.noXrpAdapter
        }

        let signer = try XrpKitManager.signer(accountType: account.type)

        let hash = try await adapter.send(
            amount: executable.amount,
            address: executable.address,
            destinationTag: executable.destinationTag,
            signer: signer
        )

        return BroadcastResult(txHash: hash, trackingHandle: nil)
    }
}

extension XrpSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        guard blockchainType == .xrp else {
            return nil
        }

        return XrpSwapBroadcaster(account: account, adapterManager: Core.shared.adapterManager)
    }
}
