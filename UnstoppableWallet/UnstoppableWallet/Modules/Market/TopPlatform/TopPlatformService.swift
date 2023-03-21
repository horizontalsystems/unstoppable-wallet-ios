import RxSwift
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

    func marketInfoSingle(currencyCode: String) -> Single<[MarketInfo]> {
        marketKit.topPlatformMarketInfosSingle(blockchain: topPlatform.blockchain.uid, currencyCode: currencyCode)
    }

}
