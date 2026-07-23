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
        guard let prepared = prepared as? DirectPrepared else {
            throw SwapBroadcasterError.dataMismatch
        }

        let keyPair = try StellarKitManager.keyPair(accountType: account.type)

        // StellarBroker interactive trade: run the WebSocket session (the broker builds and
        // submits the txs; we sign each one). The last signed fee-bump hash is the tracking
        // handle uswap-server's StellarTracker verifies on Horizon.
        if let executable = prepared.executable as? StellarBrokerExecutable {
            let client = StellarBrokerSessionClient(
                trader: try StellarKitManager.accountId(accountType: account.type),
                keyPair: keyPair,
                params: executable.sessionParams
            )
            let result = try await client.execute()
            return BroadcastResult(txHash: result.txHashes.last, trackingHandle: nil)
        }

        guard let executable = prepared.executable as? StellarExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        let txHash = try await StellarSendHelper.send(
            transactionData: executable.transactionData,
            token: executable.token,
            adjustNativeBalance: false,
            keyPair: keyPair
        )

        return BroadcastResult(txHash: txHash, trackingHandle: nil)
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
