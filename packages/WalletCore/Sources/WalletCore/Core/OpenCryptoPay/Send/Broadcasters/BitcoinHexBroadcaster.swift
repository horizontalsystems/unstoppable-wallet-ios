import BitcoinCore
import Foundation
import MarketKit

// Type A: signs UTXO tx locally, returns hex; OCP server broadcasts.
class BitcoinHexBroadcaster: IOpenCryptoPayBroadcaster {
    private let token: Token

    init(token: Token) {
        self.token = token
    }

    func broadcast(data: ISendData) async throws -> OpenCryptoPayBroadcastResult {
        guard let btcData = data as? BitcoinSendHandler.SendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? BitcoinBaseAdapter else {
            throw OpenCryptoPayBroadcastError.noAdapter
        }
        let fullTransaction = try adapter.signedTransaction(params: btcData.params)
        let raw = TransactionSerializer.serialize(transaction: fullTransaction)
        let transactionHash = fullTransaction.header.dataHash.hs.reversedHex
        return .init(proof: .hex(raw.hs.hexString), transactionHash: transactionHash)
    }
}

extension BitcoinHexBroadcaster: IOpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = ["Bitcoin": .bitcoin]

    static func make(method: String, token: Token) -> IOpenCryptoPayBroadcaster? {
        guard supportedChains.keys.contains(method) else { return nil }
        return BitcoinHexBroadcaster(token: token)
    }
}
