import RxSwift
import MarketKit
import CurrencyKit

class TopPlatformConfigProvider {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let topPlatform: TopPlatform

    init(topPlatform: TopPlatform, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.topPlatform = topPlatform
        self.marketKit = marketKit
        self.currencyKit = currencyKit
    }

}

extension TopPlatformConfigProvider: IMarketMetricsServiceConfigProvider {

    var marketInfoSingle: RxSwift.Single<[MarketInfo]> {
        marketKit.topPlatformMarketInfosSingle(blockchain: topPlatform.blockchain.uid, currencyCode: currencyKit.baseCurrency.code)
    }

    var name: String {
        "top_platform.title".localized(topPlatform.blockchain.name)
    }

    var categoryDescription: String? {
        "top_platform.description".localized(topPlatform.blockchain.name)
    }

    var imageUrl: String {
        topPlatform.blockchain.type.imageUrl
    }

    var imageMode: MarketCategoryViewModel.ViewItem.ImageMode {
        .small
    }

}
