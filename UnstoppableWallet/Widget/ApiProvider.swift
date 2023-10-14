import Alamofire
import Foundation
import HsToolKit
import ObjectMapper

class ApiProvider {
    private let baseUrl: String
    private let networkManager = NetworkManager()
    private let headers: HTTPHeaders

    init(baseUrl: String) {
        self.baseUrl = baseUrl

        var headers = HTTPHeaders()
        headers.add(name: "app_platform", value: "ios")
        //        headers.add(name: "app_version", value: appVersion)

        //        if let appId {
        //            headers.add(name: "app_id", value: appId)
        //        }

        //        if let apiKey {
        //            headers.add(name: "apikey", value: apiKey)
        //        }

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

    func coinWithPrice(uid: String, currencyCode: String) async throws -> CoinWithPrice {
        let parameters: Parameters = [
            "uids": uid,
            "fields": "uid,name,code,price,price_change_24h",
            "currency": currencyCode.lowercased(),
        ]

        let coinsWithPrice: [CoinWithPrice] = try await networkManager.fetch(url: "\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)

        if let coinWithPrice = coinsWithPrice.first {
            return coinWithPrice
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
}

struct Coin: ImmutableMappable {
    let uid: String
    let name: String
    let code: String

    init(map: Map) throws {
        uid = try map.value("uid")
        name = try map.value("name")
        code = try map.value("code")
    }
}

struct CoinWithPrice: ImmutableMappable {
    let uid: String
    let name: String
    let code: String
    let price: Decimal
    let priceChange24h: Decimal

    init(map: Map) throws {
        uid = try map.value("uid")
        name = try map.value("name")
        code = try map.value("code")
        price = try map.value("price", using: Transform.stringToDecimalTransform)
        priceChange24h = try map.value("price_change_24h", using: Transform.stringToDecimalTransform)
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
        guard let string = string else {
            return nil
        }
        return Decimal(string: string)
    }, toJSON: { (value: Decimal?) in
        guard let value = value else {
            return nil
        }
        return value.description
    })
}
