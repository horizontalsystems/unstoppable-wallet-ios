import SolanaKit

protocol IWCNSolanaSignerProvider: AnyObject {
    var signer: SolanaKit.Signer? { get }
}

class WCNSolanaSignerProvider: IWCNSolanaSignerProvider {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

    var signer: SolanaKit.Signer? {
        accountManager.activeAccount.flatMap { try? SolanaKitManager.signer(accountType: $0.type) }
    }
}
