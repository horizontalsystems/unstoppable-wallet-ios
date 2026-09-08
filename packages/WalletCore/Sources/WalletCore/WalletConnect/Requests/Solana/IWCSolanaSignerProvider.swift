import SolanaKit

protocol IWCSolanaSignerProvider: AnyObject {
    var signer: SolanaKit.Signer? { get }
}

class WCSolanaSignerProvider: IWCSolanaSignerProvider {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

    var signer: SolanaKit.Signer? {
        accountManager.activeAccount.flatMap { try? SolanaKitManager.signer(accountType: $0.type) }
    }
}
