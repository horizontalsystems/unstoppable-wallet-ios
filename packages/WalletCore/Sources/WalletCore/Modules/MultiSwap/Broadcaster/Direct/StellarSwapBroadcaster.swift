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

        guard let executable = prepared.executable as? StellarExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        let keyPair = try StellarKitManager.keyPair(accountType: account.type)

        switch executable.kind {
        case let .signed(transactionData):
            let txHash = try await StellarSendHelper.send(
                transactionData: transactionData,
                token: executable.token,
                adjustNativeBalance: false,
                keyPair: keyPair
            )

            return BroadcastResult(txHash: txHash, trackingHandle: nil)

        case let .brokerSession(sessionParams):
            // The broker builds and submits the txs; we sign each one. The last signed
            // fee-bump hash is the tracking handle uswap-server's StellarTracker verifies
            // on Horizon.
            let client = try StellarBrokerSessionClient(
                trader: StellarKitManager.accountId(accountType: account.type),
                keyPair: keyPair,
                params: sessionParams
            )
            let result = try await client.execute()

            return BroadcastResult(txHash: result.txHashes.last, trackingHandle: nil)
        }
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
