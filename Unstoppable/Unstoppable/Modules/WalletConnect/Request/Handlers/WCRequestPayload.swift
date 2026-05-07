import Foundation
import WalletConnectSign

class WCRequestPayload {
    let dAppName: String
    let data: Data

    init(dAppName: String, data: Data) {
        self.dAppName = dAppName
        self.data = data
    }

    var method: String {
        fatalError("Must be overridden by subclass")
    }
}

extension WCRequestPayload {
    enum ParsingError: Error {
        case cantParseRequest
        case badJSONRPCRequest
    }
}
