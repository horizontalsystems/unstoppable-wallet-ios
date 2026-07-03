import Foundation
import MarketKit

class StellarSwapBroadcaster: ISwapBroadcaster {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? StellarExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        let keyPair = try StellarKitManager.keyPair(accountType: account.type)

        try await StellarSendHelper.send(
            transactionData: executable.transactionData,
            token: executable.token,
            adjustNativeBalance: false,
            keyPair: keyPair
        )

        return BroadcastResult(txHash: nil, trackingHandle: nil)
    }
}

extension StellarSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        guard blockchainType == .stellar else {
            return nil
        }

        return StellarSwapBroadcaster(account: account)
    }
}
