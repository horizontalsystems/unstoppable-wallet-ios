import Foundation
import MarketKit
import SolanaKit

// Type B: broadcasts via SolanaKit, returns tx hash.
class SolanaHashBroadcaster: IOpenCryptoPayBroadcaster {
    func broadcast(data: ISendData) async throws -> OpenCryptoPayBroadcastResult {
        guard let solData = data as? SolanaSendHandler.SendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let account = Core.shared.accountManager.activeAccount,
              let signer = try? SolanaKitManager.signer(accountType: account.type)
        else {
            throw OpenCryptoPayBroadcastError.noSigner
        }
        guard let adapter = Core.shared.adapterManager.adapter(for: solData.token) as? ISendSolanaAdapter else {
            throw OpenCryptoPayBroadcastError.noAdapter
        }

        let fullTransaction: FullTransaction
        if solData.token.type.isNative {
            fullTransaction = try await adapter.sendSol(toAddress: solData.address, amount: solData.amount, signer: signer)
        } else {
            guard case let .spl(mintAddress) = solData.token.type else {
                throw OpenCryptoPayBroadcastError.dataMismatch
            }
            fullTransaction = try await adapter.sendSpl(
                mintAddress: mintAddress,
                toAddress: solData.address,
                amount: solData.amount,
                decimals: solData.token.decimals,
                signer: signer
            )
        }
        let transactionHash = fullTransaction.transaction.hash
        return .init(proof: .tx(transactionHash), transactionHash: transactionHash)
    }
}

extension SolanaHashBroadcaster: IOpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = ["Solana": .solana]

    static func make(method: String, token _: Token) -> IOpenCryptoPayBroadcaster? {
        guard supportedChains.keys.contains(method) else { return nil }
        return SolanaHashBroadcaster()
    }
}
