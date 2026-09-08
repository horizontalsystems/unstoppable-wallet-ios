import WalletConnectUtils

// Slice of the persisted session snapshot the service verifies requests against
struct WCSessionInfo {
    let topic: String
    let accountId: String
    let dAppName: String
    let approvedAccounts: [WalletConnectUtils.Account]
    var peerUrl: String?
    var peerIconUrl: String?
}
