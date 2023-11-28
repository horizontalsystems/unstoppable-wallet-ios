import Foundation
import UIKit
import WalletConnectSign

class WCSignMessagePayload: WCRequestPayload {
    class var method: String { "" }
    class var name: String { "" }
    override var method: String { Self.method }

    override init(dAppName: String, data: Data) {
        super.init(dAppName: dAppName, data: data)
    }

    public required convenience init(dAppName: String, from anyCodable: AnyCodable) throws {
        try self.init(dAppName: dAppName, data: Self.data(from: anyCodable))
    }

    class func data(from _: AnyCodable) throws -> Data {
        throw ParsingError.badJSONRPCRequest
    }

    class func module(request: WalletConnectRequest) -> UIViewController? {
        WCSignMessageRequestModule.viewController(request: request)
    }
}

class WCSignPayload: WCSignMessagePayload {
    override class var method: String { "eth_sign" }
    override class var name: String { "Sign Request" }

    override class func data(from anyCodable: AnyCodable) throws -> Data {
        let strings = try anyCodable.get([String].self)
        if strings.count >= 2, let data = strings[1].hs.hexData {
            return data
        }
        throw ParsingError.badJSONRPCRequest
    }
}

class WCPersonalSignPayload: WCSignMessagePayload {
    override class var method: String { "personal_sign" }
    override class var name: String { "Personal Sign Request" }

    override class func data(from anyCodable: AnyCodable) throws -> Data {
        let strings = try anyCodable.get([String].self)
        if strings.count >= 1, let data = strings[0].hs.hexData ?? strings[0].data(using: .utf8) {
            return data
        }
        throw ParsingError.badJSONRPCRequest
    }
}

class WCSignTypedDataPayload: WCSignMessagePayload {
    override class var method: String { "eth_signTypedData" }
    override class var name: String { "Typed Sign Request" }

    override class func data(from anyCodable: AnyCodable) throws -> Data {
        let strings = try anyCodable.get([String].self)
        if strings.count >= 2, let data = strings[1].data(using: .utf8) {
            return data
        }
        throw ParsingError.badJSONRPCRequest
    }
}

class WCSignTypedDataV4Payload: WCSignTypedDataPayload {
    override class var method: String { "eth_signTypedData_v4" }
    override class var name: String { "Typed Sign v4 Request" }
}
