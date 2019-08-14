import ObjectMapper

class BlockdozerBitcoinCashProvider: IBitcoinForksProvider {
    let name = "Blockdozer.com"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String? {
        return url + hash
    }

    func reachabilityUrl(for hash: String) -> String {
        return apiUrl + hash
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        return .get(url: apiUrl + hash, params: nil)
    }

    init(testMode: Bool) {
        let baseUrl = testMode ? "https://tbch.blockdozer.com" : "https://blockdozer.com" 
        url = "\(baseUrl)/tx/"
        apiUrl = "\(baseUrl)/api/tx/"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? InsightResponse(JSONObject: json)
    }

}
