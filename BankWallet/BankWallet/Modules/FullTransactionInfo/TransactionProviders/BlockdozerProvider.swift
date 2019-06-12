import ObjectMapper

class BlockdozerBitcoinCashProvider: IBitcoinForksProvider {
    let name = "Blockdozer.com"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String { return url + hash }
    func apiUrl(for hash: String) -> String { return apiUrl + hash }

    init(testMode: Bool) {
        let baseUrl = testMode ? "https://tbch.blockdozer.com" : "https://blockdozer.com" 
        url = "\(baseUrl)/tx/"
        apiUrl = "\(baseUrl)/api/tx/"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? InsightResponse(JSONObject: json)
    }

}
