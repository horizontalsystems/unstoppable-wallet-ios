import EvmKit
import Foundation

class AccountFactory {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
}

extension AccountFactory {
    var generatedAccountName: String {
        let adjectiveIndex = Int.random(in: 1 ... 100)
        let nounIndex = Int.random(in: 1 ... 100)

        let adjective = "wallet_name.adjective.\(adjectiveIndex)".localized
        let noun = "wallet_name.noun.\(nounIndex)".localized

        return "\(adjective) \(noun)"
    }

    var nextAccountName: String {
        let nonWatchAccounts = accountManager.accounts.filter { !$0.watchAccount }
        let order = nonWatchAccounts.count + 1

        return "Wallet \(order)"
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
