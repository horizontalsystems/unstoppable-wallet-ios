/// Only Solana NFT transfers produce NFT values; EVM producers were removed together with NftKit.
enum NftUid: Hashable {
    case solana(contractAddress: String, tokenId: String)

    var tokenId: String {
        switch self {
        case let .solana(_, tokenId): return tokenId
        }
    }
}
