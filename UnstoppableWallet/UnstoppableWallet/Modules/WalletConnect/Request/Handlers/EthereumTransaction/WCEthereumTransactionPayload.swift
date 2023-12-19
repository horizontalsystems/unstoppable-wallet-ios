import Foundation
import UIKit
import WalletConnectSign

class WCEthereumTransactionPayload: WCRequestPayload {
    class var method: String { "" }
    class var name: String { "" }

    override var method: String { Self.method }

    let transaction: WalletConnectTransaction

    init(dAppName: String, transaction: WalletConnectTransaction, data: Data) {
        self.transaction = transaction
        super.init(dAppName: dAppName, data: data)
    }

    public required convenience init(dAppName: String, from anyCodable: AnyCodable) throws {
        guard let transactions = try? anyCodable.get([WCEthereumTransaction].self),
              let wcTransaction = transactions.first
        else {
            throw WCRequestPayload.ParsingError.badJSONRPCRequest
        }

        let transaction = try WalletConnectTransaction(transaction: wcTransaction)
        self.init(dAppName: dAppName, transaction: transaction, data: anyCodable.encoded)
    }

    class func module(request _: WalletConnectRequest) -> UIViewController? {
        nil
    }
}

class WCSendEthereumTransactionPayload: WCEthereumTransactionPayload {
    override class var method: String { "eth_sendTransaction" }
    override class var name: String { "Approve Transaction" }
    override class func module(request: WalletConnectRequest) -> UIViewController? {
        WCSendEthereumTransactionRequestModule.viewController(request: request)
    }
}

class WCSignEthereumTransactionPayload: WCEthereumTransactionPayload {
    override class var method: String { "eth_signTransaction" }
    override class var name: String { "Sign Transaction" }
    override class func module(request: WalletConnectRequest) -> UIViewController? {
        WCSignEthereumTransactionRequestModule.viewController(request: request)
    }
}
