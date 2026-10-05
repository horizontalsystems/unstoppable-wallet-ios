import WalletConnectSign

struct WCRequestItem {
    let requestId: RPCID
    let result: WCRequestResult
    let session: WCSessionInfo

    var request: WCRequest? {
        switch result {
        case let .transaction(request, _), let .signMessage(request), let .direct(request): return request
        case .rejected: return nil
        }
    }
}
