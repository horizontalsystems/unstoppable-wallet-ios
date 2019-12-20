import ObjectMapper

class CoinSpaceBitcoinCashProvider: IBitcoinForksProvider {
    let name = "Coin.space"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String? {
        url + hash
    }

    var reachabilityUrl: String {
        "https://bch.coin.space/api/sync" //TODO blockdozer is down, maybe we should remove blockdozer provider
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: apiUrl + hash, params: nil)
    }

    init(testMode: Bool) {
        let baseUrl = testMode ? "https://tbch.blockdozer.com" : "https://bch.coin.space" 
        url = "\(baseUrl)/tx/"
        apiUrl = "\(baseUrl)/api/tx/"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? InsightResponse(JSONObject: json)
    }

}
