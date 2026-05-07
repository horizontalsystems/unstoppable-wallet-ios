import Foundation
import WalletConnectSign

class StellarRequestFactory {
    let stellarKitManager: StellarKitManager
    let accountManager: AccountManager

    init(stellarKitManager: StellarKitManager, accountManager: AccountManager) {
        self.stellarKitManager = stellarKitManager
        self.accountManager = accountManager
    }
}

extension StellarRequestFactory {
    func request(request: Request, payload: WCRequestPayload) throws -> WalletConnectRequest {
        guard
            let account = accountManager.activeAccount
        else {
            throw WalletConnectRequest.CreationError.noActiveAccount
        }

        guard request.chainId.namespace == StellarProposalHandler.namespace else {
            throw WalletConnectRequest.CreationError.invalidChain
        }

        let address = try StellarKitManager.accountId(accountType: account.type)

        let chain = WalletConnectRequest.Chain(id: request.chainId.reference, chainName: request.chainId.namespace, address: address)

        return WalletConnectRequest(
            id: request.id.intValue,
            chain: chain,
            payload: payload
        )
    }
}
