import BigInt
import Foundation
import WalletConnectSign

class WCRequestPayload {
    enum Kind {
        case transaction
        case signMessage
        case direct
    }

    let id: RPCID
    let topic: String
    let method: String
    let chainId: Blockchain
    let expiryTimestamp: UInt64?
    let kind: Kind
    let from: String?

    init(request: Request, kind: Kind, from: String?) {
        id = request.id
        topic = request.topic
        method = request.method
        chainId = request.chainId
        expiryTimestamp = request.expiryTimestamp
        self.kind = kind
        self.from = from
    }

    // true when the result goes back to the dApp without broadcasting
    var isSignOnly: Bool { false }
    var to: String? { nil }
    var value: BigUInt? { nil }
    var data: Data? { nil }
    var message: Data? { nil }
    var decodedSwapInfo: WCSwapInfo? { nil }

    func makeSendData() -> SendData? {
        nil
    }
}
