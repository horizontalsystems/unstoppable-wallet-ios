import MarketKit

struct NftKey: Hashable {
    let account: Account
    let blockchainType: BlockchainType

    func hash(into hasher: inout Hasher) {
        hasher.combine(account)
        hasher.combine(blockchainType)
    }

    static func ==(lhs: NftKey, rhs: NftKey) -> Bool {
        lhs.account == rhs.account && lhs.blockchainType == rhs.blockchainType
    }

}
