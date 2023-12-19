import MarketKit

class TopPlatformService {
    let topPlatform: TopPlatform
    private let marketKit: MarketKit.Kit
    private let apiTag: String

    init(topPlatform: TopPlatform, marketKit: MarketKit.Kit, apiTag: String) {
        self.topPlatform = topPlatform
        self.marketKit = marketKit
        self.apiTag = apiTag
    }
}

extension TopPlatformService: IMarketFilteredListProvider {
    func marketInfos(currencyCode: String) async throws -> [MarketInfo] {
        try await marketKit.topPlatformMarketInfos(blockchain: topPlatform.blockchain.uid, currencyCode: currencyCode, apiTag: apiTag)
    }
}
