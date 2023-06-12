import Foundation
import EvmKit

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
            case .cex(let type): return type.cex == cex
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

    func account(type: AccountType, origin: AccountOrigin, backedUp: Bool, name: String) -> Account {
        Account(
                id: UUID().uuidString,
                name: name,
                type: type,
                origin: origin,
                backedUp: backedUp
        )
    }

    func watchAccount(type: AccountType, name: String) -> Account {
        Account(
                id: UUID().uuidString,
                name: name,
                type: type,
                origin: .restored,
                backedUp: true
        )
    }

}
