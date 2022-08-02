import RxSwift
import MarketKit
import CurrencyKit
import LanguageKit

class MarketCategoryConfigProvider {
    private let category: CoinCategory
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let languageManager: LanguageManager

    init(category: CoinCategory, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, languageManager: LanguageManager) {
        self.category = category
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.languageManager = languageManager
    }

}

extension MarketCategoryConfigProvider: IMarketMetricsServiceConfigProvider {

    var marketInfoSingle: Single<[MarketInfo]> {
        marketKit.marketInfosSingle(categoryUid: category.uid, currencyCode: currencyKit.baseCurrency.code)
    }

    var name: String {
        category.name
    }

    var categoryDescription: String? {
        category.descriptions[languageManager.currentLanguage] ?? category.descriptions.first?.value
    }

    var imageUrl: String {
        category.imageUrl
    }

    var imageMode: MarketCategoryViewModel.ViewItem.ImageMode {
        .large
    }

}
