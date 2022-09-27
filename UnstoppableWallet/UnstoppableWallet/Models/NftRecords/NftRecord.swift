import MarketKit

class NftRecord {
    let blockchainType: BlockchainType
    let balance: Int

    init(blockchainType: BlockchainType, balance: Int) {
        self.blockchainType = blockchainType
        self.balance = balance
    }

    var nftUid: NftUid {
        fatalError("Should be overridden")
    }

}
