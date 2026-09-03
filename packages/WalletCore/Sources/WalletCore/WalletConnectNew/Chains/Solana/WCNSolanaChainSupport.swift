import WalletConnectUtils

class WCNSolanaChainSupport: IWCNChainSupport {
    private static let mainnet = WalletConnectUtils.Blockchain(namespace: WCNNamespace.solana, reference: "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")

    let namespace = WCNNamespace.solana
    let supportedMethods = ["solana_signMessage", "solana_signTransaction", "solana_signAllTransactions", "solana_signAndSendTransaction"]
    let supportedEvents = [String]()

    func supportedChains(account: Account) -> [WalletConnectUtils.Blockchain] {
        guard Self.canSign(account: account) else {
            return []
        }
        return [Self.mainnet].compactMap { $0 }
    }

    func account(chain: WalletConnectUtils.Blockchain, account: Account) -> WalletConnectUtils.Account? {
        guard Self.canSign(account: account),
              chain == Self.mainnet,
              let address = try? SolanaKitManager.address(accountType: account.type)
        else {
            return nil
        }

        return try? WalletConnectUtils.Account(blockchain: chain, accountAddress: address)
    }

    private static func canSign(account: Account) -> Bool {
        switch account.type {
        case .mnemonic: return true
        default: return false
        }
    }
}
