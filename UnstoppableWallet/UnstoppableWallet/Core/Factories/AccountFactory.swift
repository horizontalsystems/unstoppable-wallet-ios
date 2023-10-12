import EvmKit
import Foundation

class AccountFactory {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
}

extension AccountFactory {
    var nextAccountName: String {
        let nonWatchAccounts = accountManager.accounts.filter { !$0.watchAccount }
        let order = nonWatchAccounts.count + 1

        return "Wallet \(order)"
    }

    func nextAccountName(cex: Cex) -> String {
        let cexAccounts = accountManager.accounts.filter { account in
            switch account.type {
            case let .cex(cexAccount): return cexAccount.cex == cex
            default: return false
            }
        }
        let order = cexAccounts.count + 1

        return "\(cex.title)\(order == 1 ? "" : " \(order)")"
    }

    var nextWatchAccountName: String {
        let watchAccounts = accountManager.accounts.filter { $0.watchAccount }
        let order = watchAccounts.count + 1

        return "Watch Wallet \(order)"
    }

    func account(type: AccountType, origin: AccountOrigin, backedUp: Bool, fileBackedUp: Bool, name: String) -> Account {
        Account(
            id: UUID().uuidString,
            level: accountManager.currentLevel,
            name: name,
            type: type,
            origin: origin,
            backedUp: backedUp,
            fileBackedUp: fileBackedUp
        )
    }

    func watchAccount(type: AccountType, name: String) -> Account {
        Account(
            id: UUID().uuidString,
            level: accountManager.currentLevel,
            name: name,
            type: type,
            origin: .restored,
            backedUp: true,
            fileBackedUp: false
        )
    }
}
