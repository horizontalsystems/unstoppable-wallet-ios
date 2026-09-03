import WalletConnectSign

class WCNStellarTransactionPayload: WCNRequestPayload {
    static let signMethod = "stellar_signXDR"
    static let submitMethod = "stellar_signAndSubmitXDR"

    let xdr: String

    init(request: Request, xdr: String, sourceAccountId: String) {
        self.xdr = xdr
        super.init(request: request, kind: .transaction, from: sourceAccountId)
    }

    override var isSignOnly: Bool { method == Self.signMethod }
}
