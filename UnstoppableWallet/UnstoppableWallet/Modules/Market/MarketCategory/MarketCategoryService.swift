import MarketKit
import LanguageKit

class MarketCategoryService {
    let category: CoinCategory
    private let marketKit: MarketKit.Kit
    private let languageManager: LanguageManager

    init(category: CoinCategory, marketKit: MarketKit.Kit, languageManager: LanguageManager) {
        self.category = category
        self.marketKit = marketKit
        self.languageManager = languageManager
    }

}

extension MarketCategoryService {

    var currentLanguage: String {
        languageManager.currentLanguage
    }

}

extension MarketCategoryService: IMarketFilteredListProvider {

    func marketInfo(currencyCode: String) async throws -> [MarketInfo] {
        try await marketKit.marketInfos(categoryUid: category.uid, currencyCode: currencyCode)
    }

}
