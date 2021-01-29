import Foundation
import ObjectMapper

private struct StringArrayTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> [String]? {
        value as? [String]
    }

    func transformToJSON(_ value: [String]?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

class CategorizedCoin: ImmutableMappable {
    public let code: String
    public let title: String
    public let categories: [String]
    public let active: Bool
    public let rate: String

    init(code: String, title: String, categories: [String], active: Bool, rate: String) {
        self.code = code
        self.title = title
        self.categories = categories
        self.active = active
        self.rate = rate
    }

    required public init(map: Map) throws {
        code = try map.value("code")
        title = (try? map.value("name")) ?? ""
        active = (try? map.value("active")) ?? false
        categories = (try? map.value("categories", using: StringArrayTransform())) ?? []
        rate = (try? map.value("rating")) ?? ""
    }

}

class MarketCategory: ImmutableMappable {
    public let id: String
    public let name: String

    required public init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
    }

}

class MarketCategoryCoins: ImmutableMappable {
    public let categories: [MarketCategory]
    public let coins: [CategorizedCoin]

    required public init(map: Map) throws {
        categories = try map.value("categories")
        coins = try map.value("coins")
    }

}
