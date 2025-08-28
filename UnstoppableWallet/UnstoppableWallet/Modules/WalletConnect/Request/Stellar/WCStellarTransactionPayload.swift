import Foundation
import SwiftUI
import UIKit
import WalletConnectSign

class WCStellarTransactionPayload: WCRequestPayload {
    class var method: String { "" }
    class var name: String { "" }

    override var method: String { Self.method }

    let xdr: String

    init(dAppName: String, xdr: String, data: Data) {
        self.xdr = xdr
        super.init(dAppName: dAppName, data: data)
    }

    public required convenience init(dAppName: String, from anyCodable: AnyCodable) throws {
        guard let values = anyCodable.value as? [String: String],
              let xdr = values["xdr"]
        else {
            throw WCRequestPayload.ParsingError.badJSONRPCRequest
        }

        self.init(dAppName: dAppName, xdr: xdr, data: anyCodable.encoded)
    }

    class func module(request _: WalletConnectRequest) -> UIViewController? {
        nil
    }
}

class WCSendStellarTransactionPayload: WCStellarTransactionPayload {
    override class var method: String { "stellar_signAndSubmitXDR" }
    override class var name: String { "Submit Transaction" }

    override class func module(request: WalletConnectRequest) -> UIViewController? {
        WalletConnectSendView(request: request).toNavigationViewController()
    }

    class func view(request: WalletConnectRequest) -> some View {
        ThemeNavigationStack {
            WalletConnectSendView(request: request)
        }
    }
}
