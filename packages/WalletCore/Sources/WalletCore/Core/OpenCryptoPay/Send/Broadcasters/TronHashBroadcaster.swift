import Foundation
import MarketKit
import TronKit

// Type B: broadcasts via TronKit, returns txID.
class TronHashBroadcaster: OpenCryptoPayBroadcaster {
    private let token: Token

    init(token: Token) {
        self.token = token
    }

    func broadcast(data: ISendData) async throws -> OpenCryptoPayProof {
        guard let tronData = data as? TronSendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let contract = tronData.contract else {
            throw OpenCryptoPayBroadcastError.missingField("contract")
        }
        guard let totalFees = tronData.totalFees else {
            throw OpenCryptoPayBroadcastError.missingField("totalFees")
        }
        guard let wrapper = Core.shared.tronAccountManager.tronKitManager.tronKitWrapper else {
            throw OpenCryptoPayBroadcastError.noWrapper
        }

        let response = try await wrapper.send(contract: contract, feeLimit: totalFees)
        return .tx(response.txID.hs.hexString)
    }
}

extension TronHashBroadcaster: OpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = ["Tron": .tron]

    static func make(method: String, token: Token) -> OpenCryptoPayBroadcaster? {
        guard supportedChains.keys.contains(method) else { return nil }
        return TronHashBroadcaster(token: token)
    }
}
