import MarketKit

class TopPlatformService {
    let topPlatform: TopPlatform
    private let marketKit: MarketKit.Kit

    init(topPlatform: TopPlatform, marketKit: MarketKit.Kit) {
        self.topPlatform = topPlatform
        self.marketKit = marketKit
    }

}

extension TopPlatformService: IMarketFilteredListProvider {

    func marketInfo(currencyCode: String) async throws -> [MarketInfo] {
        try await marketKit.topPlatformMarketInfos(blockchain: topPlatform.blockchain.uid, currencyCode: currencyCode)
    }

}
