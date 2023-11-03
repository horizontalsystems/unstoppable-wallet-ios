import Foundation
import UIKit
import WalletConnectSign

class WCEthereumTransactionPayload: WCRequestPayload {
    class var method: String { "" }
    override var method: String { Self.method }

    let transaction: WalletConnectTransaction

    init(dAppName: String, transaction: WalletConnectTransaction, data: Data) {
        self.transaction = transaction
        super.init(dAppName: dAppName, data: data)
    }

    required public convenience init(dAppName: String, from anyCodable: AnyCodable) throws {
        guard let transactions = try? anyCodable.get([WCEthereumTransaction].self),
              let wcTransaction = transactions.first else {
            throw WCRequestPayload.ParsingError.badJSONRPCRequest
        }

        let transaction = try WalletConnectTransaction(transaction: wcTransaction)
        self.init(dAppName: dAppName, transaction: transaction, data: anyCodable.encoded)
    }

    class func module(request: WalletConnectRequest) -> UIViewController? {
        nil
    }
}

class WCSendEthereumTransactionPayload: WCEthereumTransactionPayload {
    override class var method: String { "eth_sendTransaction" }
    override class func module(request: WalletConnectRequest) -> UIViewController? {
        WalletConnectSendEthereumTransactionRequestModule.viewController(request: request)
    }
}

class WCSignEthereumTransactionPayload: WCEthereumTransactionPayload {
    override class var method: String { "eth_signTransaction" }
    override class func module(request: WalletConnectRequest) -> UIViewController? {
        WalletConnectSignMessageRequestModule.viewController(request: request)
    }
}
