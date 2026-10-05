import Foundation
import WalletConnectSign

class WCSolanaTransactionPayload: WCRequestPayload {
    static let signMethod = "solana_signTransaction"
    static let signAllMethod = "solana_signAllTransactions"
    static let signAndSendMethod = "solana_signAndSendTransaction"

    let rawTransactions: [Data]
    let requiredSigners: [[String]]

    init(request: Request, rawTransactions: [Data], requiredSigners: [[String]], from: String?) {
        self.rawTransactions = rawTransactions
        self.requiredSigners = requiredSigners
        super.init(request: request, kind: .transaction, from: from)
    }

    override var isSignOnly: Bool { method != Self.signAndSendMethod }
}
