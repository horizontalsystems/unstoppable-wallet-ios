import ObjectMapper

class BitcoinComBitcoinCashProvider: IBitcoinForksProvider {
    let name = "Bitcoin.com"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String? {
        url + hash
    }

    var reachabilityUrl: String {
        "https://cashexplorer.bitcoin.com/api/sync"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: apiUrl + hash, params: nil)
    }

    init() {
        url = "https://explorer.bitcoin.com/bch/tx/"
        apiUrl = "https://cashexplorer.bitcoin.com/api/tx/"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? InsightResponse(JSONObject: json)
    }

}
