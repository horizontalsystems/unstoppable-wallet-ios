import ObjectMapper

class CoinSpaceBitcoinCashProvider: IBitcoinForksProvider {
    let name = "Coin.space"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String? {
        url + hash
    }

    var reachabilityUrl: String {
        "https://bch.coin.space/api/sync"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: apiUrl + hash, params: nil)
    }

    init() {
        url = "https://bch.coin.space/tx/"
        apiUrl = "https://bch.coin.space/api/tx/"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? InsightResponse(JSONObject: json)
    }

}
