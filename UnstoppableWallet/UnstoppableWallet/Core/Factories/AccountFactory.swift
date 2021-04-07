import Foundation

class AccountFactory {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

    private var nextWalletName: String {
        let count = accountManager.accounts.count
        let order = count + 1

        return "Wallet \(order)"
    }

}

extension AccountFactory {

    func account(type: AccountType, origin: AccountOrigin) -> Account {
        Account(
                id: UUID().uuidString,
                name: nextWalletName,
                type: type,
                origin: origin,
                backedUp: origin == .restored
        )
    }

}
