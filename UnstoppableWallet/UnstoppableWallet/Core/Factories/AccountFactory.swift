import Foundation
import EthereumKit

class AccountFactory {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

}

extension AccountFactory {

    var nextAccountName: String {
        let nonWatchAccounts = accountManager.accounts.filter { account in
            switch account.type {
            case .address: return false
            default: return true
            }
        }

        let order = nonWatchAccounts.count + 1

        return "Wallet \(order)"
    }

    var nextWatchAccountName: String {
        let watchAccounts = accountManager.accounts.filter { account in
            switch account.type {
            case .address: return true
            default: return false
            }
        }

        let order = watchAccounts.count + 1

        return "Watch Wallet \(order)"
    }

    func account(name: String, type: AccountType, origin: AccountOrigin) -> Account {
        Account(
                id: UUID().uuidString,
                name: name,
                type: type,
                origin: origin,
                backedUp: origin == .restored
        )
    }

    func watchAccount(name: String, address: EthereumKit.Address, domain: String?) -> Account {
        Account(
                id: UUID().uuidString,
                name: name,
                type: .address(address: address),
                origin: .restored,
                backedUp: true
        )
    }

}
