import Foundation
import EvmKit

class AccountFactory {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

    private var nextAccountName: String {
        let nonWatchAccounts = accountManager.accounts.filter { !$0.watchAccount }
        let order = nonWatchAccounts.count + 1

        return "Wallet \(order)"
    }

    private var nextWatchAccountName: String {
        let watchAccounts = accountManager.accounts.filter { $0.watchAccount }
        let order = watchAccounts.count + 1

        return "Watch Wallet \(order)"
    }

}

extension AccountFactory {

    func account(type: AccountType, origin: AccountOrigin) -> Account {
        Account(
                id: UUID().uuidString,
                name: nextAccountName,
                type: type,
                origin: origin,
                backedUp: origin == .restored
        )
    }

    func watchAccount(address: EvmKit.Address, domain: String?) -> Account {
        Account(
                id: UUID().uuidString,
                name: domain ?? nextWatchAccountName,
                type: .evmAddress(address: address),
                origin: .restored,
                backedUp: true
        )
    }

}
