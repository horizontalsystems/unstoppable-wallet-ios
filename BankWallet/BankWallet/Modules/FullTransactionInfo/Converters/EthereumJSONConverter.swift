import Foundation

protocol IEthereumJSONConverter {
    var resource: String { get }
    var url: String { get }
    func convert(json: [String: Any]) -> IEthereumTxResponse?
}

class HorSysEthereumJSONConverter: IEthereumJSONConverter {
    var resource: String { return "HorizontalSystems" }
    let url: String

    init(url: String) {
        self.url = url
    }

    func convert(json: [String: Any]) -> IEthereumTxResponse? {
        return try? HorSysEthereumTxResponse(JSONObject: json)
    }
}
