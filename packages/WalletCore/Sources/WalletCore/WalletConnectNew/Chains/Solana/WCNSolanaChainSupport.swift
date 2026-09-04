import MarketKit
import WalletConnectUtils

class WCNSolanaChainSupport: IWCNChainSupport {
    // older dApps still use the legacy mainnet genesis reference
    private static let chains = ["5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", "4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ"]
        .compactMap { WalletConnectUtils.Blockchain(namespace: WCNNamespace.solana, reference: $0) }

    let namespace = WCNNamespace.solana
    let supportedMethods = ["solana_signMessage", "solana_signTransaction", "solana_signAllTransactions", "solana_signAndSendTransaction"]
    let supportedEvents = [String]()

    func supportedChains(account: Account) -> [WalletConnectUtils.Blockchain] {
        Self.canSign(account: account) ? Self.chains : []
    }

    func account(chain: WalletConnectUtils.Blockchain, account: Account) -> WalletConnectUtils.Account? {
        guard Self.canSign(account: account),
              Self.chains.contains(chain),
              let address = try? SolanaKitManager.address(accountType: account.type)
        else {
            return nil
        }

        return try? WalletConnectUtils.Account(blockchain: chain, accountAddress: address)
    }

    func blockchainType(chain: WalletConnectUtils.Blockchain) -> BlockchainType? {
        Self.chains.contains(chain) ? .solana : nil
    }

    private static func canSign(account: Account) -> Bool {
        switch account.type {
        case .mnemonic: return true
        default: return false
        }
    }
}
