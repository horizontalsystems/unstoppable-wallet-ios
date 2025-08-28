import Foundation
import SwiftUI
import UIKit
import WalletConnectSign

class WCStellarSignPayload: WCSignMessagePayload {
    override class var method: String { "stellar_signXDR" }
    override class var name: String { "Sign Request" }

    override class func data(from anyCodable: AnyCodable) throws -> Data {
        guard let values = anyCodable.value as? [String: String],
              let xdr = values["xdr"]
        else {
            throw WCRequestPayload.ParsingError.badJSONRPCRequest
        }

        return xdr.hs.data
    }
}
