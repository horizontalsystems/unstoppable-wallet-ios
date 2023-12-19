import Foundation
import WalletConnectSign

class Eip155RequestFactory {
    let evmBlockchainManager: EvmBlockchainManager
    let accountManager: AccountManager

    init(evmBlockchainManager: EvmBlockchainManager, accountManager: AccountManager) {
        self.evmBlockchainManager = evmBlockchainManager
        self.accountManager = accountManager
    }
}

extension Eip155RequestFactory {
    func request(request: Request, payload: WCRequestPayload) throws -> WalletConnectRequest {
        guard let account = accountManager.activeAccount else {
            throw WalletConnectRequest.CreationError.noActiveAccount
        }

        guard let chainId = Int(request.chainId.reference),
              let blockchain = evmBlockchainManager.blockchain(chainId: chainId)
        else {
            throw WalletConnectRequest.CreationError.invalidChain
        }

        guard let address = try? WalletConnectManager.evmAddress(
            account: account,
            chain: evmBlockchainManager.chain(blockchainType: blockchain.type)
        )
        else {
            throw WalletConnectRequest.CreationError.cantCreateAddress
        }

        let chain = WalletConnectRequest.Chain(id: chainId, chainName: blockchain.name, address: address.eip55)

        return WalletConnectRequest(
            id: request.id.intValue,
            chain: chain,
            payload: payload
        )
    }
}
