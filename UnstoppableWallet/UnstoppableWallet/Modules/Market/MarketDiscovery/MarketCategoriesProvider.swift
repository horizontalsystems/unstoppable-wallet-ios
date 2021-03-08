import Foundation
import CoinKit

class MarketCategoriesProvider {
    private static let fileName = "MarketCategoryCoins"

    private var coins = [CategorizedCoin]()

    init() {
        prepareCoinData()
    }

    private func prepareCoinData() {
        if let path = Bundle.main.path(forResource: Self.fileName, ofType: "json") {
            do {
                let text = try String(contentsOfFile: path, encoding: .utf8)
                if let dataText = text.data(using: .utf8),
                   let dictionary = try JSONSerialization.jsonObject(with: dataText, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] {
                   let marketCategoryCoins = try MarketCategoryCoins(JSON: dictionary)

                   coins = marketCategoryCoins.coins
                }
            } catch {
                print("\(error.localizedDescription)")
            }
        }
    }

}

extension MarketCategoriesProvider {

    func coinTypes(for category: String? = nil) -> [CoinType] {
        guard let category = category else {
            return coins.map { CoinType(id: $0.id) }
        }

        return coins
            .filter { coin in coin.categories.contains(category) }
            .map { CoinType(id: $0.id) }
    }

    func rate(for coinType: CoinType) -> String? {
        coins.first { $0.id == coinType.id }?.rate
    }

}
