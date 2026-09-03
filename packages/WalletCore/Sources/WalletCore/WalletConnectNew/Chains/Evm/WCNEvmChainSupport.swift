import EvmKit
import WalletConnectUtils

class WCNEvmChainSupport: IWCNChainSupport {
    let namespace = WCNNamespace.eip155
    let supportedMethods = [
        "eth_sendTransaction",
        "eth_signTransaction",
        "eth_sign",
        "personal_sign",
        "eth_signTypedData",
        "eth_signTypedData_v4",
        "wallet_addEthereumChain",
        "wallet_switchEthereumChain",
    ]
    let supportedEvents = ["connect", "disconnect", "message", "chainChanged", "accountsChanged"]

    private let evmBlockchainManager: EvmBlockchainManager

    init(evmBlockchainManager: EvmBlockchainManager) {
        self.evmBlockchainManager = evmBlockchainManager
    }

    func supportedChains(account: Account) -> [WalletConnectUtils.Blockchain] {
        guard Self.canSign(account: account) else {
            return []
        }

        return evmBlockchainManager.allBlockchains.compactMap { blockchain in
            guard let chainId = try? evmBlockchainManager.chain(blockchainType: blockchain.type).id else {
                return nil
            }
            return WalletConnectUtils.Blockchain(namespace: namespace, reference: String(chainId))
        }
    }

    func account(chain: WalletConnectUtils.Blockchain, account: Account) -> WalletConnectUtils.Account? {
        guard Self.canSign(account: account),
              chain.namespace == namespace,
              let chainId = Int(chain.reference),
              let blockchain = evmBlockchainManager.blockchain(chainId: chainId),
              let address = try? AccountAddress.evmAddress(account: account, blockchainType: blockchain.type)
        else {
            return nil
        }

        return try? WalletConnectUtils.Account(blockchain: chain, accountAddress: address.eip55)
    }

    private static func canSign(account: Account) -> Bool {
        switch account.type {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }
}
