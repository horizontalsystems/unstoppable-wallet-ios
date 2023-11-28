import MarketKit

class MarketCategoryService {
    let category: CoinCategory
    private let marketKit: MarketKit.Kit
    private let languageManager: LanguageManager
    private let apiTag: String

    init(category: CoinCategory, marketKit: MarketKit.Kit, languageManager: LanguageManager, apiTag: String) {
        self.category = category
        self.marketKit = marketKit
        self.languageManager = languageManager
        self.apiTag = apiTag
    }
}

extension MarketCategoryService {
    var currentLanguage: String {
        languageManager.currentLanguage
    }
}

extension MarketCategoryService: IMarketFilteredListProvider {
    func marketInfos(currencyCode: String) async throws -> [MarketInfo] {
        try await marketKit.marketInfos(categoryUid: category.uid, currencyCode: currencyCode, apiTag: apiTag)
    }
}
