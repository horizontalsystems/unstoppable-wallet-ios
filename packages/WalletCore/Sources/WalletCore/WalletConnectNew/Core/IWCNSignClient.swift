import WalletConnectSign

protocol IWCNSignClient: AnyObject {
    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws
}
