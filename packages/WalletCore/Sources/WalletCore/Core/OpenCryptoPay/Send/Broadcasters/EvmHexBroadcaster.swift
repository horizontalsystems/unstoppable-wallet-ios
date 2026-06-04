import EvmKit
import Foundation
import HsCryptoKit
import MarketKit

// Type A: signs RLP locally, returns hex; OCP server broadcasts.
class EvmHexBroadcaster: IOpenCryptoPayBroadcaster {
    private let blockchainType: BlockchainType

    init(blockchainType: BlockchainType) {
        self.blockchainType = blockchainType
    }

    func broadcast(data: ISendData) async throws -> OpenCryptoPayBroadcastResult {
        guard let evmData = data as? EvmSendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let transactionData = evmData.transactionData else {
            throw OpenCryptoPayBroadcastError.missingField("transactionData")
        }
        guard let gasPrice = evmData.gasPrice else {
            throw OpenCryptoPayBroadcastError.missingField("gasPrice")
        }
        guard let gasLimit = evmData.evmFeeData?.surchargedGasLimit else {
            throw OpenCryptoPayBroadcastError.missingField("gasLimit")
        }
        guard let wrapper = try? Core.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            throw OpenCryptoPayBroadcastError.noWrapper
        }
        guard let signer = wrapper.signer else {
            throw OpenCryptoPayBroadcastError.noSigner
        }

        let rawTransaction = try await wrapper.evmKit.fetchRawTransaction(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: evmData.nonce
        )
        let signature = try signer.signature(rawTransaction: rawTransaction)
        let encoded = TransactionBuilder.encode(
            rawTransaction: rawTransaction,
            signature: signature,
            chainId: wrapper.evmKit.chain.id
        )
        let transactionHash = Crypto.sha3(encoded).hs.hexString
        return .init(proof: .hex(encoded.hs.hexString), transactionHash: transactionHash)
    }
}

extension EvmHexBroadcaster: IOpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = [
        "Ethereum": .ethereum,
        "BinanceSmartChain": .binanceSmartChain,
        "Polygon": .polygon,
        "Arbitrum": .arbitrumOne,
        "Optimism": .optimism,
        "Base": .base,
    ]

    static func make(method: String, token _: Token) -> IOpenCryptoPayBroadcaster? {
        guard let blockchainType = supportedChains[method] else { return nil }
        return EvmHexBroadcaster(blockchainType: blockchainType)
    }
}
