import Foundation
import WalletConnectSign

class WCNSolanaSignMessagePayload: WCNRequestPayload {
    static let method = "solana_signMessage"

    private let messageData: Data

    init(request: Request, publicKey: String, message: Data) {
        messageData = message
        super.init(request: request, kind: .signMessage, from: publicKey)
    }

    override var message: Data? { messageData }

    var readableMessage: String {
        String(data: messageData, encoding: .utf8) ?? messageData.hs.hexString
    }
}
