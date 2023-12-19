import EvmKit
import Foundation

import BigInt

class WalletConnectRequest {
    let id: Int
    let chain: Chain
    let payload: WCRequestPayload

    init(id: Int, chain: Chain, payload: WCRequestPayload) {
        self.id = id
        self.chain = chain
        self.payload = payload
    }

    func convert(result _: Any) -> String? {
        nil
    }

    struct Chain {
        let id: Int
        let chainName: String?
        let address: String?

        init(id: Int, chainName: String? = nil, address: String? = nil) {
            self.id = id
            self.chainName = chainName
            self.address = address
        }
    }
}

extension WalletConnectRequest {
    enum CreationError: Error {
        case noActiveAccount
        case invalidChain
        case cantCreateAddress
    }
}
