import WalletConnectUtils

class WCNStellarChainSupport: IWCNChainSupport {
    private static let pubnet = WalletConnectUtils.Blockchain(namespace: WCNNamespace.stellar, reference: "pubnet")

    let namespace = WCNNamespace.stellar
    let supportedMethods = ["stellar_signXDR", "stellar_signAndSubmitXDR"]
    let supportedEvents = ["connect", "disconnect", "message"]

    func supportedChains(account: Account) -> [WalletConnectUtils.Blockchain] {
        guard Self.canSign(account: account) else {
            return []
        }
        return [Self.pubnet].compactMap { $0 }
    }

    func account(chain: WalletConnectUtils.Blockchain, account: Account) -> WalletConnectUtils.Account? {
        guard Self.canSign(account: account),
              chain == Self.pubnet,
              let accountId = try? StellarKitManager.accountId(accountType: account.type)
        else {
            return nil
        }

        return try? WalletConnectUtils.Account(blockchain: chain, accountAddress: accountId)
    }

    private static func canSign(account: Account) -> Bool {
        switch account.type {
        case .mnemonic, .stellarSecretKey: return true
        default: return false
        }
    }
}
