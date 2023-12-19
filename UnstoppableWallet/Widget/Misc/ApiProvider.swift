import Alamofire
import Foundation
import HsToolKit
import ObjectMapper

class ApiProvider {
    private let baseUrl: String
    private let networkManager = NetworkManager()
    private let headers: HTTPHeaders

    init() {
        baseUrl = WidgetConfig.marketApiUrl

        var headers = HTTPHeaders()
        headers.add(name: "widget", value: "true")
        headers.add(name: "app_platform", value: "ios")
        headers.add(name: "app_version", value: WidgetConfig.appVersion)

        if let appId = WidgetConfig.appId {
            headers.add(name: "app_id", value: appId)
        }

        if let apiKey = WidgetConfig.hsProviderApiKey {
            headers.add(name: "apikey", value: apiKey)
        }

        self.headers = headers
    }

    func topCoins(limit: Int) async throws -> [Coin] {
        let parameters: Parameters = [
            "limit": limit,
            "fields": "uid,name,code",
            "order_by_rank": "true",
        ]

        return try await networkManager.fetch(url: "\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)
    }

    func listCoins(uids: [String]? = nil, type: ListType, order: ListOrder, limit: Int, currencyCode: String) async throws -> [Coin] {
        var parameters: Parameters = [
            "order": order.rawValue,
            "limit": limit,
            "currency": currencyCode.lowercased(),
        ]

        if let uids {
            parameters["uids"] = uids.joined(separator: ",")
        }

        return try await networkManager.fetch(url: "\(baseUrl)/v1/coins/top-movers-by/\(type.rawValue)", method: .get, parameters: parameters, headers: headers)
    }

    func coinWithPrice(uid: String, currencyCode: String) async throws -> Coin {
        let parameters: Parameters = [
            "uids": uid,
            "fields": "uid,name,code,price,price_change_24h",
            "currency": currencyCode.lowercased(),
        ]

        let coins: [Coin] = try await networkManager.fetch(url: "\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)

        if let coin = coins.first {
            return coin
        } else {
            throw ResponseError.coinNotFound
        }
    }

    func coinPriceChart(coinUid: String, currencyCode: String) async throws -> [ChartPoint] {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased(),
            "interval": "30m",
            "from_timestamp": Date().timeIntervalSince1970 - 60 * 60 * 24,
        ]

        return try await networkManager.fetch(url: "\(baseUrl)/v1/coins/\(coinUid)/price_chart", method: .get, parameters: parameters, headers: headers)
    }

    enum ResponseError: Error {
        case coinNotFound
    }

    enum ListOrder: String {
        case asc
        case desc
    }

    enum ListType: String {
        case price
        case volume
        case mcap
    }
}

struct Coin: ImmutableMappable {
    let uid: String
    let name: String
    let code: String
    let price: Decimal?
    let priceChange24h: Decimal?

    init(map: Map) throws {
        uid = try map.value("uid")
        name = try map.value("name")
        code = try map.value("code")
        price = try? map.value("price", using: Transform.stringToDecimalTransform)
        priceChange24h = try? map.value("price_change_24h", using: Transform.stringToDecimalTransform)
    }
}

struct ChartPoint: ImmutableMappable {
    let timestamp: Int
    let price: Decimal

    init(map: Map) throws {
        timestamp = try map.value("timestamp")
        price = try map.value("price", using: Transform.stringToDecimalTransform)
    }
}

enum Transform {
    static let stringToDecimalTransform: TransformOf<Decimal, String> = TransformOf(fromJSON: { string -> Decimal? in
        guard let string else {
            return nil
        }
        return Decimal(string: string)
    }, toJSON: { (value: Decimal?) in
        guard let value else {
            return nil
        }
        return value.description
    })
}
