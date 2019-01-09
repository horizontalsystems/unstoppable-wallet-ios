import Foundation

protocol IBitcoinJSONConverter {
    var resource: String { get }
    var url: String { get }
    func convert(json: [String: Any]) -> IBitcoinTxResponse?
}

class HorSysBitcoinJSONConverter: IBitcoinJSONConverter {
    var resource: String { return "HorizontalSystems" }
    let url: String

    init(url: String) {
        self.url = url
    }

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? HorSysBitcoinTxResponse(JSONObject: json)
    }
}

class BlockChairBitcoinJSONConverter: IBitcoinJSONConverter {
    var resource: String { return "BlockChair.com" }
    let url: String

    init(url: String) {
        self.url = url
    }

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? BlockChairBitcoinTxResponse(JSONObject: json)
    }
}

class BlockExplorerBitcoinJSONConverter: IBitcoinJSONConverter {
    var resource: String { return "BlockExplorer.com" }
    let url: String

    init(url: String) {
        self.url = url
    }

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? BlockExplorerBitcoinTxResponse(JSONObject: json)
    }
}

class BtcComBitcoinJSONConverter: IBitcoinJSONConverter {
    var resource: String { return "Btc.com" }
    let url: String

    init(url: String) {
        self.url = url
    }

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? BtcComBitcoinTxResponse(JSONObject: json)
    }
}

