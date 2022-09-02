import Foundation
import NftKit
import MarketKit

class EvmNftRecord: NftRecord {
    let type: NftType
    let contractAddress: String
    let tokenId: String
    let tokenName: String?

    init(blockchainType: BlockchainType, type: NftType, contractAddress: String, tokenId: String, tokenName: String?, balance: Int) {
        self.type = type
        self.contractAddress = contractAddress
        self.tokenId = tokenId
        self.tokenName = tokenName

        super.init(blockchainType: blockchainType, balance: balance)
    }

    override var nftUid: NftUid {
        .evm(blockchainType: blockchainType, contractAddress: contractAddress, tokenId: tokenId)
    }

}
