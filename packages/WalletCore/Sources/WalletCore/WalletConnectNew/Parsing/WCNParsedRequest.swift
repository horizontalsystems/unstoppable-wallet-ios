import BigInt
import Foundation
import WalletConnectSign

class WCNParsedRequest {
    enum Kind {
        case transaction
        case signMessage
        case direct
    }

    let id: RPCID
    let topic: String
    let method: String
    let chainId: Blockchain
    let kind: Kind
    let from: String?

    init(request: Request, kind: Kind, from: String?) {
        id = request.id
        topic = request.topic
        method = request.method
        chainId = request.chainId
        self.kind = kind
        self.from = from
    }

    var to: String? { nil }
    var value: BigUInt? { nil }
    var data: Data? { nil }
    var message: Data? { nil }
    var decodedSwapInfo: WCNSwapInfo? { nil }

    func makeSendData() -> SendData? {
        nil
    }
}
