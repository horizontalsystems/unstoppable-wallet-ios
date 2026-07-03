import Foundation
import MarketKit

class TonSwapBroadcaster: ISwapBroadcaster {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? TonExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        let (publicKey, secretKey) = try TonKitManager.keyPair(accountType: account.type)
        let contract = TonKitManager.contract(publicKey: publicKey)

        let transferData = try TonSendHelper.transferData(
            param: executable.transactionParam,
            contract: contract
        )

        _ = try await TonSendHelper.send(
            transferData: transferData,
            contract: contract,
            secretKey: secretKey
        )

        return BroadcastResult(txHash: nil, trackingHandle: nil)
    }
}

extension TonSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        guard blockchainType == .ton else {
            return nil
        }

        return TonSwapBroadcaster(account: account)
    }
}
