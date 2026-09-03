import WalletConnectUtils

struct WCNBlockchainProposal: Equatable {
    let chain: WalletConnectUtils.Blockchain
    let account: WalletConnectUtils.Account
    var methods: Set<String>
    var events: Set<String>
    var required: Bool
}
