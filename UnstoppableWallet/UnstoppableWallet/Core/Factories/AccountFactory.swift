import Foundation
import EthereumKit

class AccountFactory {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

    private var nextAccountName: String {
        let nonWatchAccounts = accountManager.accounts.filter { account in
            switch account.type {
            case .address: return false
            default: return true
            }
        }

        let order = nonWatchAccounts.count + 1

        return "Wallet \(order)"
    }

    private var nextWatchAccountName: String {
        let watchAccounts = accountManager.accounts.filter { account in
            switch account.type {
            case .address: return true
            default: return false
            }
        }

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

    func watchAccount(address: EthereumKit.Address, domain: String?) -> Account {
        Account(
                id: UUID().uuidString,
                name: domain ?? nextWatchAccountName,
                type: .address(address: address),
                origin: .restored,
                backedUp: true
        )
    }

}
