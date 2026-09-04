import WalletConnectSign

struct WCNRequestItem {
    let requestId: RPCID
    let result: WCNRequestResult
    let session: WCNSessionInfo

    var request: WCNRequest? {
        switch result {
        case let .transaction(request, _), let .signMessage(request), let .direct(request): return request
        case .rejected: return nil
        }
    }
}
