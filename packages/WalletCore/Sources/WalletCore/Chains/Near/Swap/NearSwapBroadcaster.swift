import Foundation
import MarketKit

class NearSwapBroadcaster: ISwapBroadcaster {
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
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? NearExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let adapter = adapterManager.adapter(for: executable.token) as? ISendNearAdapter else {
            throw MultiSwapSendHandler.SendError.noNearAdapter
        }
        // the quote failed to estimate, so nothing the user confirmed can be sent
        guard let estimate = executable.estimate else {
            throw SwapBroadcasterError.dataMismatch
        }

        let signer = try NearKitManager.signer(accountType: account.type)

        // a broadcast that left a new pending transaction is a success, as on the send screen
        let hash = try await NearSendHelper.send(
            adapter: adapter,
            amount: executable.amount,
            address: executable.address,
            memo: nil,
            estimate: estimate,
            signer: signer
        )

        return BroadcastResult(txHash: hash, trackingHandle: nil)
    }
}

extension NearSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        guard blockchainType == .near else {
            return nil
        }

        return NearSwapBroadcaster(account: account, adapterManager: Core.shared.adapterManager)
    }
}
