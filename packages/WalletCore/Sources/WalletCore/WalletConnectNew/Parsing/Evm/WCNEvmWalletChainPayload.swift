import WalletConnectSign

class WCNEvmWalletChainPayload: WCNRequestPayload {
    static let switchMethod = "wallet_switchEthereumChain"
    static let addMethod = "wallet_addEthereumChain"

    let targetChainId: Int

    init(request: Request, targetChainId: Int) {
        self.targetChainId = targetChainId
        super.init(request: request, kind: .direct, from: nil)
    }
}
