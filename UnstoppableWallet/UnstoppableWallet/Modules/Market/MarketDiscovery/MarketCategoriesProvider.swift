import Foundation

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

    func coinCodes(for category: String) -> [String] {
        coins
            .filter { coin in coin.categories.contains(category) }
            .map { $0.code }
    }

    func rate(for coinCode: String) -> String? {
        coins.first { $0.code == coinCode }?.rate
    }

}
