import EvmKit
import Foundation

public class AccountFactory {
    private let accountManager: AccountManager

    public init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
}

public extension AccountFactory {
    var generatedAccountName: String {
        let index = Int.random(in: 1 ... 100)
        return NSLocalizedString("wallet_name.\(index)", bundle: .module, comment: "")
    }

    var nextAccountName: String {
        nextName(key: "wallet_name.default")
    }

    var nextWatchAccountName: String {
        nextName(key: "wallet_name.watch_default")
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

private extension AccountFactory {
    func nextName(key: String) -> String {
        let taken = Set(accountManager.accounts.map(\.name))

        // taken.count + 1 numbers always include a free one, as long as the template formats the number
        return (1 ... taken.count + 1).lazy.map { key.localized($0) }.first { !taken.contains($0) } ?? key.localized(1)
    }
}
